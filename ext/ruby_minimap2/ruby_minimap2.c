#include <ruby.h>
#include <ruby/thread.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <zlib.h>

#ifdef _WIN32
#include <fcntl.h>
#include <io.h>
#else
#include <unistd.h>
#endif

#include "minimap.h"
#include "kseq.h"

#ifdef __clang__
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wshorten-64-to-32"
#endif
KSEQ_INIT(gzFile, gzread)
#ifdef __clang__
#pragma clang diagnostic pop
#endif

extern int mm2_embedded_main(int argc, char **argv);
extern unsigned char seq_comp_table[256];
extern double realtime(void);

typedef struct {
    mm_idxopt_t idx_opt;
    mm_mapopt_t map_opt;
    mm_idx_t **indexes;
    size_t index_count;
    size_t index_capacity;
    int released;
    VALUE mutex;
} rb_mm2_aligner_t;

typedef struct {
    kseq_t *seq;
    gzFile file;
    int closed;
} rb_mm2_fastx_t;

static VALUE mMinimap2;
static VALUE mNative;
static VALUE cAligner;
static VALUE cAlignment;
static VALUE cFastxReader;
static VALUE eMinimap2Error;
static VALUE execute_mutex;

#ifdef RUBY_MINIMAP2_TESTING
static size_t live_indexes = 0;
static size_t live_fastx_readers = 0;
static size_t live_pair_buffers = 0;
#endif

static ID id_new;
static ID id_sort_by;

static void aligner_release_indexes(rb_mm2_aligner_t *aligner)
{
    size_t i;
    if (aligner->released) return;
    aligner->released = 1;
    for (i = 0; i < aligner->index_count; ++i) {
        if (aligner->indexes[i]) {
            mm_idx_destroy(aligner->indexes[i]);
#ifdef RUBY_MINIMAP2_TESTING
            --live_indexes;
#endif
        }
    }
    free(aligner->indexes);
    aligner->indexes = NULL;
    aligner->index_count = 0;
    aligner->index_capacity = 0;
}

static void aligner_mark(void *ptr)
{
    rb_mm2_aligner_t *aligner = ptr;
    if (aligner) rb_gc_mark(aligner->mutex);
}

static void aligner_free(void *ptr)
{
    rb_mm2_aligner_t *aligner = ptr;
    if (!aligner) return;
    aligner_release_indexes(aligner);
    xfree(aligner);
}

static size_t aligner_memsize(const void *ptr)
{
    const rb_mm2_aligner_t *aligner = ptr;
    if (!aligner) return 0;
    return sizeof(*aligner) + aligner->index_capacity * sizeof(mm_idx_t *);
}

static const rb_data_type_t aligner_type = {
    "Minimap2::Aligner",
    {aligner_mark, aligner_free, aligner_memsize, NULL},
    NULL, NULL,
    RUBY_TYPED_FREE_IMMEDIATELY
};

static VALUE aligner_alloc(VALUE klass)
{
    rb_mm2_aligner_t *aligner;
    VALUE object = TypedData_Make_Struct(klass, rb_mm2_aligner_t, &aligner_type, aligner);
    memset(aligner, 0, sizeof(*aligner));
    aligner->released = 1;
    aligner->mutex = rb_mutex_new();
    return object;
}

static rb_mm2_aligner_t *get_aligner(VALUE self)
{
    rb_mm2_aligner_t *aligner;
    TypedData_Get_Struct(self, rb_mm2_aligner_t, &aligner_type, aligner);
    return aligner;
}

static void aligner_add_index(rb_mm2_aligner_t *aligner, mm_idx_t *index)
{
    if (!index) return;
    if (aligner->index_count == aligner->index_capacity) {
        size_t capacity = aligner->index_capacity == 0 ? 4 : aligner->index_capacity * 2;
        mm_idx_t **indexes = realloc(aligner->indexes, capacity * sizeof(*indexes));
        if (!indexes) rb_memerror();
        aligner->indexes = indexes;
        aligner->index_capacity = capacity;
    }
    aligner->indexes[aligner->index_count++] = index;
#ifdef RUBY_MINIMAP2_TESTING
    ++live_indexes;
#endif
}

static int keyword_given(VALUE value)
{
    return value != Qundef && !NIL_P(value);
}

static int keyword_int(VALUE value)
{
    return NUM2INT(value);
}

typedef struct {
    const char *path;
    const char *output_path;
    mm_idxopt_t options;
    int threads;
    mm_idx_t **indexes;
    size_t count;
    size_t capacity;
    int open_failed;
    int allocation_failed;
} index_file_job_t;

static void *load_indexes_without_gvl(void *argument)
{
    index_file_job_t *job = argument;
    mm_idx_reader_t *reader = mm_idx_reader_open(job->path, &job->options, job->output_path);
    if (!reader) {
        job->open_failed = 1;
        return NULL;
    }
    for (;;) {
        mm_idx_t *index = mm_idx_reader_read(reader, job->threads);
        if (!index) break;
        mm_idx_index_name(index);
        if (job->count == job->capacity) {
            size_t capacity = job->capacity == 0 ? 4 : job->capacity * 2;
            mm_idx_t **indexes = realloc(job->indexes, capacity * sizeof(*indexes));
            if (!indexes) {
                mm_idx_destroy(index);
                job->allocation_failed = 1;
                break;
            }
            job->indexes = indexes;
            job->capacity = capacity;
        }
        job->indexes[job->count++] = index;
    }
    mm_idx_reader_close(reader);
    return NULL;
}

typedef struct {
    const char *sequence;
    mm_idxopt_t options;
    mm_idx_t *index;
} index_sequence_job_t;

static void *build_sequence_index_without_gvl(void *argument)
{
    index_sequence_job_t *job = argument;
    const char *name = "N/A";
    job->index = mm_idx_str(job->options.w, job->options.k, job->options.flag & 1,
                            job->options.bucket_bits, 1, &job->sequence, &name);
    if (job->index) mm_idx_index_name(job->index);
    return NULL;
}

static VALUE aligner_initialize(int argc, VALUE *argv, VALUE self)
{
    static ID keywords[18];
    VALUE path = Qnil, options = Qnil, values[18];
    VALUE preset, seq, fn_idx_out, scoring;
    rb_mm2_aligner_t *aligner = get_aligner(self);
    const char *preset_ptr = NULL;
    int result;

    if (!keywords[0]) {
        const char *names[] = {
            "seq", "preset", "k", "w", "min_cnt", "min_chain_score", "min_dp_score",
            "bw", "bw_long", "best_n", "n_threads", "fn_idx_out", "max_frag_len",
            "extra_flags", "scoring", "sc_ambi", "max_chain_skip", "batch_size"
        };
        int i;
        for (i = 0; i < 18; ++i) keywords[i] = rb_intern(names[i]);
    }

    rb_scan_args(argc, argv, "01:", &path, &options);
    for (int i = 0; i < 18; ++i) values[i] = Qundef;
    if (!NIL_P(options)) rb_get_kwargs(options, keywords, 0, 18, values);

    seq = values[0];
    preset = values[1];
    fn_idx_out = values[11];
    scoring = values[14];

    mm_set_opt(NULL, &aligner->idx_opt, &aligner->map_opt);
    if (keyword_given(preset)) {
        VALUE preset_string = rb_obj_as_string(preset);
        preset_ptr = StringValueCStr(preset_string);
        result = mm_set_opt(preset_ptr, &aligner->idx_opt, &aligner->map_opt);
        if (result == -1) rb_raise(rb_eArgError, "Unknown preset name: %s", preset_ptr);
    }
    aligner->map_opt.flag |= MM_F_CIGAR;
    aligner->idx_opt.batch_size = UINT64_MAX >> 1;

    if (keyword_given(values[2])) {
        int k = keyword_int(values[2]);
        if (k < 1 || k > 28) rb_raise(rb_eArgError, "k must be between 1 and 28");
        aligner->idx_opt.k = (short)k;
    }
    if (keyword_given(values[3])) {
        int w = keyword_int(values[3]);
        if (w < 1 || w > 255) rb_raise(rb_eArgError, "w must be between 1 and 255");
        aligner->idx_opt.w = (short)w;
    }
    if (keyword_given(values[4])) aligner->map_opt.min_cnt = keyword_int(values[4]);
    if (keyword_given(values[5])) aligner->map_opt.min_chain_score = keyword_int(values[5]);
    if (keyword_given(values[6])) aligner->map_opt.min_dp_max = keyword_int(values[6]);
    if (keyword_given(values[7])) aligner->map_opt.bw = keyword_int(values[7]);
    if (keyword_given(values[8])) aligner->map_opt.bw_long = keyword_int(values[8]);
    if (keyword_given(values[9])) aligner->map_opt.best_n = keyword_int(values[9]);
    if (keyword_given(values[12])) aligner->map_opt.max_frag_len = keyword_int(values[12]);
    if (keyword_given(values[13])) aligner->map_opt.flag |= NUM2LL(values[13]);
    if (keyword_given(values[15])) aligner->map_opt.sc_ambi = keyword_int(values[15]);
    if (keyword_given(values[16])) aligner->map_opt.max_chain_skip = keyword_int(values[16]);
    if (keyword_given(values[17])) aligner->idx_opt.batch_size = NUM2ULL(values[17]);

    if (keyword_given(scoring)) {
        long length;
        Check_Type(scoring, T_ARRAY);
        length = RARRAY_LEN(scoring);
        if (length >= 4) {
            aligner->map_opt.a = NUM2INT(rb_ary_entry(scoring, 0));
            aligner->map_opt.b = NUM2INT(rb_ary_entry(scoring, 1));
            aligner->map_opt.q = NUM2INT(rb_ary_entry(scoring, 2));
            aligner->map_opt.e = NUM2INT(rb_ary_entry(scoring, 3));
            aligner->map_opt.q2 = aligner->map_opt.q;
            aligner->map_opt.e2 = aligner->map_opt.e;
            if (length >= 6) {
                aligner->map_opt.q2 = NUM2INT(rb_ary_entry(scoring, 4));
                aligner->map_opt.e2 = NUM2INT(rb_ary_entry(scoring, 5));
                if (length >= 7) aligner->map_opt.sc_ambi = NUM2INT(rb_ary_entry(scoring, 6));
            }
        }
    }

    aligner->released = 0;
    if (!NIL_P(path)) {
        VALUE path_string = rb_get_path(path);
        index_file_job_t job;
        char *path_copy;
        char *output_copy = NULL;
        int threads = keyword_given(values[10]) ? keyword_int(values[10]) : 3;

        if (!RTEST(rb_funcall(rb_cFile, rb_intern("file?"), 1, path_string)))
            rb_raise(eMinimap2Error, "Cannot open index file: %s", StringValueCStr(path_string));
        path_copy = strdup(StringValueCStr(path_string));

        if (keyword_given(seq)) rb_warn("Since fn_idx_in is specified, the seq argument will be ignored.");
        if (keyword_given(fn_idx_out)) {
            fn_idx_out = rb_get_path(fn_idx_out);
            output_copy = strdup(StringValueCStr(fn_idx_out));
        }
        if (!path_copy || (keyword_given(fn_idx_out) && !output_copy)) {
            free(path_copy);
            free(output_copy);
            rb_memerror();
        }
        memset(&job, 0, sizeof(job));
        job.path = path_copy;
        job.output_path = output_copy;
        job.options = aligner->idx_opt;
        job.threads = threads;
        rb_thread_call_without_gvl(load_indexes_without_gvl, &job, NULL, NULL);
        free(path_copy);
        free(output_copy);
        if (job.allocation_failed) {
            for (size_t i = 0; i < job.count; ++i) mm_idx_destroy(job.indexes[i]);
            free(job.indexes);
            rb_memerror();
        }
        if (job.open_failed) rb_raise(eMinimap2Error, "Cannot open: %s", StringValueCStr(path_string));
        uint64_t sequence_count = 0;
        int sequence_data_missing = 0;
        for (size_t i = 0; i < job.count; ++i) sequence_count += job.indexes[i]->n_seq;
        for (size_t i = 0; i < job.count; ++i) {
            if (job.indexes[i]->flag & MM_I_NO_SEQ) sequence_data_missing = 1;
        }
        if (job.count == 0 || sequence_count == 0 || sequence_data_missing) {
            for (size_t i = 0; i < job.count; ++i) mm_idx_destroy(job.indexes[i]);
            free(job.indexes);
            if (sequence_data_missing)
                rb_raise(eMinimap2Error, "Index does not contain sequence data: %s", StringValueCStr(path_string));
            rb_raise(eMinimap2Error, "Failed to read index parts from: %s", StringValueCStr(path_string));
        }
        aligner->indexes = job.indexes;
        aligner->index_count = job.count;
        aligner->index_capacity = job.capacity;
#ifdef RUBY_MINIMAP2_TESTING
        live_indexes += job.count;
#endif
        mm_mapopt_update(&aligner->map_opt, aligner->indexes[0]);
        RB_GC_GUARD(path_string);
        RB_GC_GUARD(fn_idx_out);
    } else if (keyword_given(seq)) {
        VALUE sequence = StringValue(seq);
        index_sequence_job_t job;
        char *sequence_copy = malloc((size_t)RSTRING_LEN(sequence) + 1);
        if (!sequence_copy) rb_memerror();
        memcpy(sequence_copy, RSTRING_PTR(sequence), (size_t)RSTRING_LEN(sequence));
        sequence_copy[RSTRING_LEN(sequence)] = '\0';
        memset(&job, 0, sizeof(job));
        job.sequence = sequence_copy;
        job.options = aligner->idx_opt;
        rb_thread_call_without_gvl(build_sequence_index_without_gvl, &job, RUBY_UBF_IO, NULL);
        free(sequence_copy);
        if (!job.index) rb_raise(eMinimap2Error, "Failed to build index from sequence");
        aligner_add_index(aligner, job.index);
        mm_mapopt_update(&aligner->map_opt, job.index);
        aligner->map_opt.mid_occ = 1000;
        RB_GC_GUARD(sequence);
    }

    return self;
}

static VALUE aligner_free_index_locked(VALUE argument)
{
    rb_mm2_aligner_t *aligner = (rb_mm2_aligner_t *)(uintptr_t)argument;
    aligner_release_indexes(aligner);
    return Qnil;
}

static VALUE aligner_free_index(VALUE self)
{
    rb_mm2_aligner_t *aligner = get_aligner(self);
    return rb_mutex_synchronize(aligner->mutex, aligner_free_index_locked, (VALUE)(uintptr_t)aligner);
}

static void require_live_index(rb_mm2_aligner_t *aligner)
{
    if (aligner->released) rb_raise(eMinimap2Error, "index has been released");
    if (aligner->index_count == 0) rb_raise(eMinimap2Error, "index is not initialized");
}

static VALUE aligner_index_p_locked(VALUE argument)
{
    rb_mm2_aligner_t *aligner = (rb_mm2_aligner_t *)(uintptr_t)argument;
    return (!aligner->released && aligner->index_count > 0) ? Qtrue : Qfalse;
}

static VALUE aligner_index_p(VALUE self)
{
    rb_mm2_aligner_t *aligner = get_aligner(self);
    return rb_mutex_synchronize(aligner->mutex, aligner_index_p_locked, (VALUE)(uintptr_t)aligner);
}

static VALUE aligner_k_locked(VALUE argument)
{
    rb_mm2_aligner_t *aligner = (rb_mm2_aligner_t *)(uintptr_t)argument;
    require_live_index(aligner);
    return INT2NUM(aligner->indexes[0]->k);
}

static VALUE aligner_k(VALUE self)
{
    rb_mm2_aligner_t *aligner = get_aligner(self);
    return rb_mutex_synchronize(aligner->mutex, aligner_k_locked, (VALUE)(uintptr_t)aligner);
}

static VALUE aligner_w_locked(VALUE argument)
{
    rb_mm2_aligner_t *aligner = (rb_mm2_aligner_t *)(uintptr_t)argument;
    require_live_index(aligner);
    return INT2NUM(aligner->indexes[0]->w);
}

static VALUE aligner_w(VALUE self)
{
    rb_mm2_aligner_t *aligner = get_aligner(self);
    return rb_mutex_synchronize(aligner->mutex, aligner_w_locked, (VALUE)(uintptr_t)aligner);
}

static VALUE aligner_n_seq_locked(VALUE argument)
{
    rb_mm2_aligner_t *aligner = (rb_mm2_aligner_t *)(uintptr_t)argument;
    size_t i;
    uint64_t count = 0;
    if (aligner->released) return INT2FIX(0);
    for (i = 0; i < aligner->index_count; ++i) count += aligner->indexes[i]->n_seq;
    return ULL2NUM(count);
}

static VALUE aligner_n_seq(VALUE self)
{
    rb_mm2_aligner_t *aligner = get_aligner(self);
    return rb_mutex_synchronize(aligner->mutex, aligner_n_seq_locked, (VALUE)(uintptr_t)aligner);
}

static VALUE aligner_seq_names_locked(VALUE argument)
{
    rb_mm2_aligner_t *aligner = (rb_mm2_aligner_t *)(uintptr_t)argument;
    VALUE result = rb_ary_new();
    size_t i;
    if (aligner->released) return result;
    for (i = 0; i < aligner->index_count; ++i) {
        mm_idx_t *index = aligner->indexes[i];
        uint32_t j;
        for (j = 0; j < index->n_seq; ++j) {
            VALUE name = rb_utf8_str_new_cstr(index->seq[j].name);
            rb_ary_push(result, name);
        }
    }
    return result;
}

static VALUE aligner_seq_names(VALUE self)
{
    rb_mm2_aligner_t *aligner = get_aligner(self);
    return rb_mutex_synchronize(aligner->mutex, aligner_seq_names_locked, (VALUE)(uintptr_t)aligner);
}

typedef struct {
    rb_mm2_aligner_t *aligner;
    const char *name;
    int start;
    int stop;
} seq_args_t;

static VALUE aligner_seq_locked(VALUE argument)
{
    seq_args_t *args = (seq_args_t *)(uintptr_t)argument;
    size_t i;
    if (args->aligner->released) return Qnil;
    for (i = 0; i < args->aligner->index_count; ++i) {
        mm_idx_t *index = args->aligner->indexes[i];
        int rid = mm_idx_name2id(index, args->name);
        int start = args->start;
        int stop = args->stop;
        int length, j;
        uint8_t *buffer;
        VALUE result;
        if (rid < 0) continue;
        if (start < 0) start = 0;
        if ((uint32_t)start >= index->seq[rid].len || start >= stop) return Qnil;
        if ((uint32_t)stop > index->seq[rid].len) stop = (int)index->seq[rid].len;
        buffer = malloc((size_t)(stop - start));
        if (!buffer) rb_memerror();
        length = mm_idx_getseq(index, (uint32_t)rid, (uint32_t)start, (uint32_t)stop, buffer);
        for (j = 0; j < length; ++j) buffer[j] = (uint8_t)"ACGTN"[buffer[j]];
        result = rb_str_new((const char *)buffer, length);
        free(buffer);
        return result;
    }
    return Qnil;
}

static VALUE aligner_seq(int argc, VALUE *argv, VALUE self)
{
    VALUE name, start_value = Qnil, stop_value = Qnil;
    VALUE name_string;
    rb_mm2_aligner_t *aligner = get_aligner(self);
    seq_args_t args;
    rb_scan_args(argc, argv, "12", &name, &start_value, &stop_value);
    if (NIL_P(start_value)) start_value = INT2FIX(0);
    if (NIL_P(stop_value)) stop_value = INT2NUM(0x7fffffff);
    name_string = rb_obj_as_string(name);
    args.aligner = aligner;
    args.name = StringValueCStr(name_string);
    args.start = NUM2INT(start_value);
    args.stop = NUM2INT(stop_value);
    VALUE result = rb_mutex_synchronize(aligner->mutex, aligner_seq_locked, (VALUE)(uintptr_t)&args);
    RB_GC_GUARD(name_string);
    return result;
}

typedef struct {
    const mm_idx_t *index;
    const char *name;
    const char *seq1;
    const char *seq2;
    mm_mapopt_t options;
    mm_tbuf_t *buffer;
    mm_reg1_t *regs;
    int n_regs;
    int failed;
} map_job_t;

static void *map_without_gvl(void *argument)
{
    map_job_t *job = argument;
    if (!job->seq2) {
        job->regs = mm_map(job->index, (int)strlen(job->seq1), job->seq1,
                           &job->n_regs, job->buffer, &job->options, job->name);
    } else {
        int lengths[2], counts[2] = {0, 0};
        mm_reg1_t *parts[2] = {NULL, NULL};
        const char *sequences[2];
        char *mate = strdup(job->seq2);
        int i;
        if (!mate) {
            job->failed = 1;
            return NULL;
        }
#ifdef RUBY_MINIMAP2_TESTING
        ++live_pair_buffers;
#endif
        lengths[0] = (int)strlen(job->seq1);
        lengths[1] = (int)strlen(job->seq2);
        sequences[0] = job->seq1;
        sequences[1] = mate;
        for (i = 0; i < lengths[1] / 2; ++i) {
            int right = mate[lengths[1] - i - 1];
            mate[lengths[1] - i - 1] = (char)seq_comp_table[(uint8_t)mate[i]];
            mate[i] = (char)seq_comp_table[(uint8_t)right];
        }
        if (lengths[1] & 1)
            mate[lengths[1] / 2] = (char)seq_comp_table[(uint8_t)mate[lengths[1] / 2]];
        mm_map_frag(job->index, 2, lengths, sequences, counts, parts,
                    job->buffer, &job->options, job->name);
        free(mate);
#ifdef RUBY_MINIMAP2_TESTING
        --live_pair_buffers;
#endif
        for (i = 0; i < counts[1]; ++i) parts[1][i].rev = !parts[1][i].rev;
        job->n_regs = counts[0] + counts[1];
        if (job->n_regs > 0) {
            mm_reg1_t *combined = realloc(parts[0], sizeof(mm_reg1_t) * (size_t)job->n_regs);
            if (!combined) {
                for (i = 0; i < counts[0]; ++i) free(parts[0][i].p);
                for (i = 0; i < counts[1]; ++i) free(parts[1][i].p);
                free(parts[0]);
                free(parts[1]);
                job->failed = 1;
                return NULL;
            }
            parts[0] = combined;
            if (counts[1] > 0) memcpy(parts[0] + counts[0], parts[1], sizeof(mm_reg1_t) * (size_t)counts[1]);
        }
        free(parts[1]);
        job->regs = parts[0];
    }
    return NULL;
}

typedef struct {
    map_job_t *job;
    VALUE entries;
    VALUE seq1;
    VALUE seq2;
    VALUE name;
    int want_cs;
    int want_ds;
    int want_md;
    long *ordinal;
    int converted;
    char *tag_buffer;
    int tag_capacity;
} convert_ctx_t;

static VALUE alignment_hash(const mm_idx_t *index, const mm_reg1_t *reg, VALUE name, long query_length)
{
    VALUE hash = rb_hash_new();
    int trans_strand = reg->p->trans_strand == 1 ? 1 : reg->p->trans_strand == 2 ? -1 : 0;
    rb_hash_aset(hash, ID2SYM(rb_intern("qname")), NIL_P(name) ? rb_str_new_cstr("*") : rb_str_dup(name));
    rb_hash_aset(hash, ID2SYM(rb_intern("qlen")), LONG2NUM(query_length));
    rb_hash_aset(hash, ID2SYM(rb_intern("ctg")), rb_utf8_str_new_cstr(index->seq[reg->rid].name));
    rb_hash_aset(hash, ID2SYM(rb_intern("ctg_len")), UINT2NUM(index->seq[reg->rid].len));
    rb_hash_aset(hash, ID2SYM(rb_intern("ctg_start")), INT2NUM(reg->rs));
    rb_hash_aset(hash, ID2SYM(rb_intern("ctg_end")), INT2NUM(reg->re));
    rb_hash_aset(hash, ID2SYM(rb_intern("qry_start")), INT2NUM(reg->qs));
    rb_hash_aset(hash, ID2SYM(rb_intern("qry_end")), INT2NUM(reg->qe));
    rb_hash_aset(hash, ID2SYM(rb_intern("blen")), INT2NUM(reg->blen));
    rb_hash_aset(hash, ID2SYM(rb_intern("mlen")), INT2NUM(reg->mlen));
    rb_hash_aset(hash, ID2SYM(rb_intern("NM")), INT2NUM(reg->blen - reg->mlen + reg->p->n_ambi));
    rb_hash_aset(hash, ID2SYM(rb_intern("mapq")), INT2NUM(reg->mapq));
    rb_hash_aset(hash, ID2SYM(rb_intern("is_primary")), reg->id == reg->parent ? INT2FIX(1) : INT2FIX(0));
    rb_hash_aset(hash, ID2SYM(rb_intern("strand")), reg->rev ? INT2FIX(-1) : INT2FIX(1));
    rb_hash_aset(hash, ID2SYM(rb_intern("trans_strand")), INT2NUM(trans_strand));
    rb_hash_aset(hash, ID2SYM(rb_intern("seg_id")), INT2NUM(reg->seg_id));
    return hash;
}

static VALUE convert_regs(VALUE argument)
{
    convert_ctx_t *ctx = (convert_ctx_t *)(uintptr_t)argument;
    map_job_t *job = ctx->job;
    int i;
    void *km = mm_tbuf_get_km(job->buffer);
    for (i = 0; i < job->n_regs; ++i) {
        mm_reg1_t *reg = &job->regs[i];
        if (!reg->p) {
            ctx->converted = i + 1;
            continue;
        }
        VALUE cigar = rb_ary_new_capa(reg->p->n_cigar);
        VALUE cs = Qnil;
        VALUE ds = Qnil;
        VALUE md = Qnil;
        VALUE hash, alignment, entry;
        uint32_t j;
        VALUE query_value = reg->seg_id > 0 && !NIL_P(ctx->seq2) ? ctx->seq2 : ctx->seq1;
        const char *query = RSTRING_PTR(query_value);
        for (j = 0; j < reg->p->n_cigar; ++j) {
            VALUE pair = rb_ary_new_capa(2);
            rb_ary_push(pair, UINT2NUM(reg->p->cigar[j] >> 4));
            rb_ary_push(pair, UINT2NUM(reg->p->cigar[j] & 0xf));
            rb_ary_push(cigar, pair);
        }
        if (ctx->want_cs) {
            int length = mm_gen_cs(km, &ctx->tag_buffer, &ctx->tag_capacity, job->index, reg, query, 1);
            cs = length > 0 ? rb_str_new(ctx->tag_buffer, length) : rb_str_new_cstr("");
        }
        if (ctx->want_ds) {
            int length = mm_gen_ds(km, &ctx->tag_buffer, &ctx->tag_capacity, job->index, reg, query, 1);
            ds = length > 0 ? rb_str_new(ctx->tag_buffer, length) : rb_str_new_cstr("");
        }
        if (ctx->want_md) {
            int length = mm_gen_MD(km, &ctx->tag_buffer, &ctx->tag_capacity, job->index, reg, query);
            md = length > 0 ? rb_str_new(ctx->tag_buffer, length) : rb_str_new_cstr("");
        }
        hash = alignment_hash(job->index, reg, ctx->name, RSTRING_LEN(query_value));
        alignment = rb_funcall(cAlignment, id_new, 5, hash, cigar, cs, ds, md);
        entry = rb_ary_new_capa(7);
        rb_ary_push(entry, alignment);
        rb_ary_push(entry, reg->id == reg->parent ? INT2FIX(1) : INT2FIX(0));
        rb_ary_push(entry, INT2NUM(reg->mapq));
        rb_ary_push(entry, INT2NUM(reg->mlen));
        rb_ary_push(entry, INT2NUM(reg->blen));
        rb_ary_push(entry, INT2NUM(reg->blen - reg->mlen + reg->p->n_ambi));
        rb_ary_push(entry, LONG2NUM((*ctx->ordinal)++));
        rb_ary_push(ctx->entries, entry);
        free(reg->p);
        reg->p = NULL;
        ctx->converted = i + 1;
    }
    return Qnil;
}

static VALUE cleanup_regs(VALUE argument)
{
    convert_ctx_t *ctx = (convert_ctx_t *)(uintptr_t)argument;
    int i;
    if (ctx->job->regs) {
        for (i = ctx->converted; i < ctx->job->n_regs; ++i) free(ctx->job->regs[i].p);
        free(ctx->job->regs);
        ctx->job->regs = NULL;
    }
    free(ctx->tag_buffer);
    ctx->tag_buffer = NULL;
    return Qnil;
}

static VALUE sort_key(VALUE entry, VALUE ignored, int argc, const VALUE *argv, VALUE blockarg)
{
    VALUE key = rb_ary_new_capa(6);
    (void)ignored; (void)argc; (void)argv; (void)blockarg;
    rb_ary_push(key, LONG2NUM(-NUM2LONG(rb_ary_entry(entry, 1))));
    rb_ary_push(key, LONG2NUM(-NUM2LONG(rb_ary_entry(entry, 2))));
    rb_ary_push(key, LONG2NUM(-NUM2LONG(rb_ary_entry(entry, 3))));
    rb_ary_push(key, LONG2NUM(-NUM2LONG(rb_ary_entry(entry, 4))));
    rb_ary_push(key, rb_ary_entry(entry, 5));
    rb_ary_push(key, rb_ary_entry(entry, 6));
    return key;
}

typedef struct {
    rb_mm2_aligner_t *aligner;
    VALUE seq1;
    VALUE seq2;
    VALUE name;
    int want_cs;
    int want_ds;
    int want_md;
    int has_max_frag_len;
    int max_frag_len;
    int has_extra_flags;
    int64_t extra_flags;
    mm_tbuf_t *buffer;
    char *seq1_copy;
    char *seq2_copy;
    char *name_copy;
} align_args_t;

static VALUE align_body(VALUE argument)
{
    align_args_t *args = (align_args_t *)(uintptr_t)argument;
    VALUE entries = rb_ary_new();
    VALUE result;
    const char *seq1 = args->seq1_copy;
    const char *seq2 = args->seq2_copy;
    const char *name = args->name_copy;
    long ordinal = 0;
    size_t part;

    for (part = 0; part < args->aligner->index_count; ++part) {
        map_job_t job;
        convert_ctx_t convert;
        memset(&job, 0, sizeof(job));
        job.index = args->aligner->indexes[part];
        job.name = name;
        job.seq1 = seq1;
        job.seq2 = seq2;
        job.options = args->aligner->map_opt;
        mm_mapopt_update(&job.options, job.index);
        job.options.flag |= MM_F_CIGAR;
        if (args->has_max_frag_len) job.options.max_frag_len = args->max_frag_len;
        if (args->has_extra_flags) job.options.flag |= args->extra_flags;
        job.buffer = args->buffer;
        rb_thread_call_without_gvl(map_without_gvl, &job, RUBY_UBF_IO, NULL);
        if (job.failed) rb_memerror();
        if (!job.regs || job.n_regs <= 0) {
            free(job.regs);
            continue;
        }
        memset(&convert, 0, sizeof(convert));
        convert.job = &job;
        convert.entries = entries;
        convert.seq1 = args->seq1;
        convert.seq2 = args->seq2;
        convert.name = args->name;
        convert.want_cs = args->want_cs;
        convert.want_ds = args->want_ds;
        convert.want_md = args->want_md;
        convert.ordinal = &ordinal;
        rb_ensure(convert_regs, (VALUE)(uintptr_t)&convert, cleanup_regs, (VALUE)(uintptr_t)&convert);
    }

    if (args->aligner->map_opt.best_n > 0 && RARRAY_LEN(entries) > args->aligner->map_opt.best_n) {
        entries = rb_block_call(entries, id_sort_by, 0, NULL, sort_key, Qnil);
        entries = rb_ary_subseq(entries, 0, args->aligner->map_opt.best_n);
    }
    result = rb_ary_new_capa(RARRAY_LEN(entries));
    for (long i = 0; i < RARRAY_LEN(entries); ++i)
        rb_ary_push(result, rb_ary_entry(rb_ary_entry(entries, i), 0));
    return result;
}

static VALUE align_cleanup(VALUE argument)
{
    align_args_t *args = (align_args_t *)(uintptr_t)argument;
    if (args->buffer) {
        mm_tbuf_destroy(args->buffer);
        args->buffer = NULL;
    }
    free(args->seq1_copy);
    free(args->seq2_copy);
    free(args->name_copy);
    args->seq1_copy = NULL;
    args->seq2_copy = NULL;
    args->name_copy = NULL;
    return Qnil;
}

static VALUE align_locked(VALUE argument)
{
    align_args_t *args = (align_args_t *)(uintptr_t)argument;
    if (args->aligner->released || args->aligner->index_count == 0) return rb_ary_new();
    args->seq1_copy = strdup(StringValueCStr(args->seq1));
    if (!NIL_P(args->seq2)) args->seq2_copy = strdup(StringValueCStr(args->seq2));
    if (!NIL_P(args->name)) args->name_copy = strdup(StringValueCStr(args->name));
    if (!args->seq1_copy || (!NIL_P(args->seq2) && !args->seq2_copy) ||
        (!NIL_P(args->name) && !args->name_copy)) {
        align_cleanup(argument);
        rb_memerror();
    }
    args->buffer = mm_tbuf_init();
    if (!args->buffer) {
        align_cleanup(argument);
        rb_memerror();
    }
    return rb_ensure(align_body, argument, align_cleanup, argument);
}

static VALUE align_synchronized(VALUE argument)
{
    align_args_t *args = (align_args_t *)(uintptr_t)argument;
    return rb_mutex_synchronize(args->aligner->mutex, align_locked, argument);
}

static VALUE aligner_align(int argc, VALUE *argv, VALUE self)
{
    static ID keywords[6];
    VALUE seq1, seq2 = Qnil, options = Qnil, values[6];
    align_args_t args;
    rb_mm2_aligner_t *aligner = get_aligner(self);
    if (!keywords[0]) {
        const char *names[] = {"name", "cs", "ds", "md", "max_frag_len", "extra_flags"};
        for (int i = 0; i < 6; ++i) keywords[i] = rb_intern(names[i]);
    }
    rb_scan_args(argc, argv, "11:", &seq1, &seq2, &options);
    for (int i = 0; i < 6; ++i) values[i] = Qundef;
    if (!NIL_P(options)) rb_get_kwargs(options, keywords, 0, 6, values);
    seq1 = StringValue(seq1);
    if (!NIL_P(seq2)) seq2 = StringValue(seq2);
    memset(&args, 0, sizeof(args));
    args.aligner = aligner;
    args.seq1 = seq1;
    args.seq2 = seq2;
    args.name = keyword_given(values[0]) ? rb_obj_as_string(values[0]) : Qnil;
    args.want_cs = keyword_given(values[1]) && RTEST(values[1]);
    args.want_ds = keyword_given(values[2]) && RTEST(values[2]);
    args.want_md = keyword_given(values[3]) && RTEST(values[3]);
    args.has_max_frag_len = keyword_given(values[4]);
    if (args.has_max_frag_len) args.max_frag_len = NUM2INT(values[4]);
    args.has_extra_flags = keyword_given(values[5]);
    if (args.has_extra_flags) args.extra_flags = NUM2LL(values[5]);
    VALUE result = align_synchronized((VALUE)(uintptr_t)&args);
    RB_GC_GUARD(seq1);
    RB_GC_GUARD(seq2);
    RB_GC_GUARD(args.name);
    return result;
}

static void fastx_close_native(rb_mm2_fastx_t *reader)
{
    if (!reader || reader->closed) return;
    reader->closed = 1;
    if (reader->seq) kseq_destroy(reader->seq);
    if (reader->file) gzclose(reader->file);
    reader->seq = NULL;
    reader->file = NULL;
#ifdef RUBY_MINIMAP2_TESTING
    --live_fastx_readers;
#endif
}

static void fastx_free(void *ptr)
{
    rb_mm2_fastx_t *reader = ptr;
    fastx_close_native(reader);
    xfree(reader);
}

static size_t fastx_memsize(const void *ptr)
{
    return ptr ? sizeof(rb_mm2_fastx_t) : 0;
}

static const rb_data_type_t fastx_type = {
    "Minimap2::Native::FastxReader",
    {NULL, fastx_free, fastx_memsize, NULL},
    NULL, NULL,
    RUBY_TYPED_FREE_IMMEDIATELY
};

static VALUE fastx_alloc(VALUE klass)
{
    rb_mm2_fastx_t *reader;
    VALUE object = TypedData_Make_Struct(klass, rb_mm2_fastx_t, &fastx_type, reader);
    memset(reader, 0, sizeof(*reader));
    reader->closed = 1;
    return object;
}

static VALUE fastx_initialize(VALUE self, VALUE path)
{
    rb_mm2_fastx_t *reader;
    VALUE path_string = rb_get_path(path);
    const char *path_ptr = StringValueCStr(path_string);
    int first;
    TypedData_Get_Struct(self, rb_mm2_fastx_t, &fastx_type, reader);
    if (strcmp(path_ptr, "-") == 0) {
#ifdef _WIN32
        int fd = _dup(_fileno(stdin));
        if (fd >= 0) _setmode(fd, _O_BINARY);
#else
        int fd = dup(fileno(stdin));
#endif
        if (fd >= 0) {
            reader->file = gzdopen(fd, "r");
            if (!reader->file) {
#ifdef _WIN32
                _close(fd);
#else
                close(fd);
#endif
            }
        }
    } else {
        reader->file = gzopen(path_ptr, "r");
    }
    if (!reader->file) rb_raise(eMinimap2Error, "Cannot open FASTA/FASTQ file: %s", StringValueCStr(path_string));
    first = gzgetc(reader->file);
    if (first != '>' && first != '@') {
        gzclose(reader->file);
        reader->file = NULL;
        rb_raise(eMinimap2Error, "Invalid FASTA/FASTQ file: %s", path_ptr);
    }
    if (gzungetc(first, reader->file) == -1) {
        gzclose(reader->file);
        reader->file = NULL;
        rb_raise(eMinimap2Error, "Cannot read FASTA/FASTQ file: %s", path_ptr);
    }
    reader->seq = kseq_init(reader->file);
    if (!reader->seq) {
        gzclose(reader->file);
        reader->file = NULL;
        rb_raise(eMinimap2Error, "Cannot initialize FASTA/FASTQ reader");
    }
    reader->closed = 0;
#ifdef RUBY_MINIMAP2_TESTING
    ++live_fastx_readers;
#endif
    return self;
}

static VALUE fastx_next(VALUE self, VALUE read_comment)
{
    rb_mm2_fastx_t *reader;
    VALUE result;
    int status;
    TypedData_Get_Struct(self, rb_mm2_fastx_t, &fastx_type, reader);
    if (reader->closed) return Qnil;
    status = kseq_read(reader->seq);
    if (status == -1) {
        fastx_close_native(reader);
        return Qnil;
    }
    if (status < -1) {
        fastx_close_native(reader);
        rb_raise(eMinimap2Error, "Malformed FASTA/FASTQ record");
    }
    if (reader->seq->name.l == 0 || reader->seq->seq.l == 0) {
        fastx_close_native(reader);
        rb_raise(eMinimap2Error, "Malformed FASTA/FASTQ record");
    }
    result = rb_ary_new_capa(RTEST(read_comment) ? 4 : 3);
    rb_ary_push(result, rb_str_new(reader->seq->name.s, reader->seq->name.l));
    rb_ary_push(result, rb_str_new(reader->seq->seq.s, reader->seq->seq.l));
    rb_ary_push(result, reader->seq->qual.l > 0 ? rb_str_new(reader->seq->qual.s, reader->seq->qual.l) : Qnil);
    if (RTEST(read_comment))
        rb_ary_push(result, reader->seq->comment.l > 0 ? rb_str_new(reader->seq->comment.s, reader->seq->comment.l) : Qnil);
    return result;
}

static VALUE fastx_close(VALUE self)
{
    rb_mm2_fastx_t *reader;
    TypedData_Get_Struct(self, rb_mm2_fastx_t, &fastx_type, reader);
    fastx_close_native(reader);
    return Qnil;
}

static VALUE native_revcomp(VALUE module, VALUE sequence)
{
    VALUE input = StringValue(sequence);
    long length = RSTRING_LEN(input), i;
    VALUE output = rb_str_new(NULL, length);
    const unsigned char *source = (const unsigned char *)RSTRING_PTR(input);
    char *target = RSTRING_PTR(output);
    (void)module;
    for (i = 0; i < length; ++i) target[length - i - 1] = (char)seq_comp_table[source[i]];
    return output;
}

static VALUE native_verbose(VALUE module)
{
    (void)module;
    return INT2NUM(mm_verbose);
}

static VALUE native_set_verbose(VALUE module, VALUE value)
{
    (void)module;
    mm_verbose = NUM2INT(value);
    return value;
}

typedef struct {
    int argc;
    char **argv;
    int result;
    int allocated;
} execute_job_t;

static void *execute_without_gvl(void *argument)
{
    execute_job_t *job = argument;
    job->result = mm2_embedded_main(job->argc, job->argv);
    return NULL;
}

static VALUE native_execute_locked(VALUE argument)
{
    execute_job_t *job = (execute_job_t *)(uintptr_t)argument;
    int old_verbose = mm_verbose;
    int old_debug = mm_dbg_flag;
    double old_timer = mm_realtime0;
    rb_thread_call_without_gvl(execute_without_gvl, job, RUBY_UBF_IO, NULL);
    mm_verbose = old_verbose;
    mm_dbg_flag = old_debug;
    mm_realtime0 = old_timer;
    return INT2NUM(job->result);
}

static VALUE native_execute_synchronized(VALUE argument)
{
    return rb_mutex_synchronize(execute_mutex, native_execute_locked, argument);
}

static VALUE native_execute_cleanup(VALUE argument)
{
    execute_job_t *job = (execute_job_t *)(uintptr_t)argument;
    int i;
    for (i = 0; i < job->allocated; ++i) free(job->argv[i]);
    xfree(job->argv);
    job->argv = NULL;
    return Qnil;
}

static VALUE native_execute(int argc, VALUE *argv, VALUE module)
{
    execute_job_t job;
    VALUE result;
    int i;
    (void)module;
    job.argc = argc + 1;
    job.allocated = 0;
    job.argv = ALLOC_N(char *, (size_t)job.argc + 1);
    job.argv[0] = strdup("minimap2");
    if (!job.argv[0]) {
        xfree(job.argv);
        rb_memerror();
    }
    job.allocated = 1;
    for (i = 0; i < argc; ++i) {
        VALUE string = rb_obj_as_string(argv[i]);
        job.argv[i + 1] = strdup(StringValueCStr(string));
        if (!job.argv[i + 1]) {
            native_execute_cleanup((VALUE)(uintptr_t)&job);
            rb_memerror();
        }
        ++job.allocated;
    }
    job.argv[job.argc] = NULL;
    result = rb_ensure(native_execute_synchronized, (VALUE)(uintptr_t)&job,
                       native_execute_cleanup, (VALUE)(uintptr_t)&job);
    return result;
}

#ifdef RUBY_MINIMAP2_TESTING
static VALUE native_resource_counts(VALUE module)
{
    VALUE result = rb_hash_new();
    (void)module;
    rb_hash_aset(result, ID2SYM(rb_intern("indexes")), SIZET2NUM(live_indexes));
    rb_hash_aset(result, ID2SYM(rb_intern("fastx_readers")), SIZET2NUM(live_fastx_readers));
    rb_hash_aset(result, ID2SYM(rb_intern("pair_buffers")), SIZET2NUM(live_pair_buffers));
    return result;
}
#endif

void Init_minimap2_ext(void)
{
    mm_realtime0 = realtime();
    id_new = rb_intern("new");
    id_sort_by = rb_intern("sort_by");
    mMinimap2 = rb_define_module("Minimap2");
    eMinimap2Error = rb_define_class_under(mMinimap2, "Error", rb_eStandardError);
    mNative = rb_define_module_under(mMinimap2, "Native");
    cAlignment = rb_define_class_under(mMinimap2, "Alignment", rb_cObject);
    cAligner = rb_define_class_under(mMinimap2, "Aligner", rb_cObject);
    rb_define_alloc_func(cAligner, aligner_alloc);
    rb_define_method(cAligner, "initialize", aligner_initialize, -1);
    rb_define_method(cAligner, "free_index", aligner_free_index, 0);
    rb_define_method(cAligner, "align", aligner_align, -1);
    rb_define_method(cAligner, "seq", aligner_seq, -1);
    rb_define_method(cAligner, "k", aligner_k, 0);
    rb_define_method(cAligner, "w", aligner_w, 0);
    rb_define_method(cAligner, "n_seq", aligner_n_seq, 0);
    rb_define_method(cAligner, "seq_names", aligner_seq_names, 0);
    rb_define_method(cAligner, "index?", aligner_index_p, 0);

    cFastxReader = rb_define_class_under(mNative, "FastxReader", rb_cObject);
    rb_define_alloc_func(cFastxReader, fastx_alloc);
    rb_define_method(cFastxReader, "initialize", fastx_initialize, 1);
    rb_define_method(cFastxReader, "next_record", fastx_next, 1);
    rb_define_method(cFastxReader, "close", fastx_close, 0);

    execute_mutex = rb_mutex_new();
    rb_global_variable(&execute_mutex);
    rb_define_singleton_method(mNative, "revcomp", native_revcomp, 1);
    rb_define_singleton_method(mNative, "verbose", native_verbose, 0);
    rb_define_singleton_method(mNative, "verbose=", native_set_verbose, 1);
    rb_define_singleton_method(mNative, "execute", native_execute, -1);
#ifdef RUBY_MINIMAP2_TESTING
    rb_define_singleton_method(mNative, "resource_counts", native_resource_counts, 0);
#endif
}
