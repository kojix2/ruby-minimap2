# frozen_string_literal: true

module Minimap2
  module FFI
    attach_function \
      :main,
      %i[int pointer],
      :int

    # int mm_set_opt(const char *preset, mm_idxopt_t *io, mm_mapopt_t *mo);
    attach_function \
      :mm_set_opt_raw, :mm_set_opt,
      [:pointer, IdxOpt.by_ref, MapOpt.by_ref],
      :int

    private_class_method :mm_set_opt_raw

    def self.mm_set_opt(preset, io, mo)
      ptr = case preset
            when 0, nil
              ::FFI::Pointer.new(:int, 0)
            else
              ::FFI::MemoryPointer.from_string(preset.to_s)
            end
      mm_set_opt_raw(ptr, io, mo)
    end

    # int mm_check_opt(const mm_idxopt_t *io, const mm_mapopt_t *mo);
    attach_function \
      :mm_check_opt,
      [IdxOpt.by_ref, MapOpt.by_ref],
      :int

    # void mm_mapopt_update(mm_mapopt_t *opt, const mm_idx_t *mi);
    attach_function \
      :mm_mapopt_update,
      [MapOpt.by_ref, Idx.by_ref],
      :void

    # void mm_mapopt_max_intron_len(mm_mapopt_t *opt, int max_intron_len);
    attach_function \
      :mm_mapopt_max_intron_len,
      [MapOpt.by_ref, :int],
      :void

    # mm_idx_reader_t *mm_idx_reader_open(const char *fn, const mm_idxopt_t *opt, const char *fn_out);
    attach_function \
      :mm_idx_reader_open,
      [:string, IdxOpt.by_ref, :string],
      IdxReader.by_ref

    # mm_idx_t *mm_idx_reader_read(mm_idx_reader_t *r, int n_threads);
    attach_function \
      :mm_idx_reader_read,
      [IdxReader.by_ref, :int],
      Idx.by_ref

    # void mm_idx_reader_close(mm_idx_reader_t *r);
    attach_function \
      :mm_idx_reader_close,
      [IdxReader.by_ref],
      :void

    # int mm_idx_reader_eof(const mm_idx_reader_t *r);
    attach_function \
      :mm_idx_reader_eof,
      [IdxReader.by_ref],
      :int

    # int64_t mm_idx_is_idx(const char *fn);
    attach_function \
      :mm_idx_is_idx,
      [:string],
      :int64_t

    # mm_idx_t *mm_idx_load(FILE *fp);
    attach_function \
      :mm_idx_load,
      [:pointer], # FILE pointer
      Idx.by_ref

    # void mm_idx_dump(FILE *fp, const mm_idx_t *mi);
    attach_function \
      :mm_idx_dump,
      [:pointer, Idx.by_ref], # FILE pointer
      :void

    # mm_idx_t *mm_idx_str(int w, int k, int is_hpc, int bucket_bits, int n, const char **seq, const char **name);
    attach_function \
      :mm_idx_str,
      %i[int int int int int pointer pointer],
      Idx.by_ref

    # void mm_idx_stat(const mm_idx_t *idx);
    attach_function \
      :mm_idx_stat,
      [Idx.by_ref],
      :void

    # void mm_idx_destroy(mm_idx_t *mi);
    attach_function \
      :mm_idx_destroy,
      [Idx.by_ref],
      :void

    # mm_tbuf_t *mm_tbuf_init(void);
    attach_function \
      :mm_tbuf_init,
      [],
      TBuf.by_ref

    # void mm_tbuf_destroy(mm_tbuf_t *b);
    attach_function \
      :mm_tbuf_destroy,
      [TBuf.by_ref],
      :void

    # void *mm_tbuf_get_km(mm_tbuf_t *b);
    attach_function \
      :mm_tbuf_get_km,
      [TBuf.by_ref],
      :pointer

    # mm_reg1_t *mm_map(const mm_idx_t *mi, int l_seq, const char *seq, int *n_regs, mm_tbuf_t *b, const mm_mapopt_t *opt, const char *name);
    attach_function \
      :mm_map,
      [Idx.by_ref, :int, :string, :pointer, TBuf.by_ref, MapOpt.by_ref, :string],
      Reg1.by_ref

    # void mm_map_frag(const mm_idx_t *mi, int n_segs, const int *qlens, const char **seqs, int *n_regs, mm_reg1_t **regs, mm_tbuf_t *b, const mm_mapopt_t *opt, const char *qname);
    attach_function \
      :mm_map_frag,
      [Idx.by_ref, :int, :pointer, :pointer, :pointer, :pointer, TBuf.by_ref, MapOpt.by_ref, :string],
      :void

    # int mm_map_file(const mm_idx_t *idx, const char *fn, const mm_mapopt_t *opt, int n_threads);
    attach_function \
      :mm_map_file,
      [Idx.by_ref, :string, MapOpt.by_ref, :int],
      :int

    # int mm_map_file_frag(const mm_idx_t *idx, int n_segs, const char **fn, const mm_mapopt_t *opt, int n_threads);
    attach_function \
      :mm_map_file_frag,
      [Idx.by_ref, :int, :pointer, MapOpt.by_ref, :int],
      :int

    # int mm_gen_cs(void *km, char **buf, int *max_len, const mm_idx_t *mi, const mm_reg1_t *r, const char *seq, int no_iden);
    attach_function \
      :mm_gen_cs,
      [:pointer, :pointer, :pointer, Idx.by_ref, Reg1.by_ref, :string, :int],
      :int

    # int mm_gen_MD(void *km, char **buf, int *max_len, const mm_idx_t *mi, const mm_reg1_t *r, const char *seq);
    attach_function \
      :mm_gen_md, :mm_gen_MD, # Avoid uppercase letters in method names.
      [:pointer, :pointer, :pointer, Idx.by_ref, Reg1.by_ref, :string],
      :int

    # int mm_idx_index_name(mm_idx_t *mi);
    attach_function \
      :mm_idx_index_name,
      [Idx.by_ref],
      :int

    # int mm_idx_name2id(const mm_idx_t *mi, const char *name);
    attach_function \
      :mm_idx_name2id,
      [Idx.by_ref, :string],
      :int

    # int mm_idx_getseq(const mm_idx_t *mi, uint32_t rid, uint32_t st, uint32_t en, uint8_t *seq);
    attach_function \
      :mm_idx_getseq,
      [Idx.by_ref, :uint32, :uint32, :uint32, :pointer],
      :int

    # int mm_idx_alt_read(mm_idx_t *mi, const char *fn);
    attach_function \
      :mm_idx_alt_read,
      [Idx.by_ref, :string],
      :int

    # int mm_idx_bed_read(mm_idx_t *mi, const char *fn, int read_junc);
    attach_function \
      :mm_idx_bed_read,
      [Idx.by_ref, :string, :int],
      :int

    # int mm_idx_bed_junc(const mm_idx_t *mi, int32_t ctg, int32_t st, int32_t en, uint8_t *s);
    attach_function \
      :mm_idx_bed_junc,
      [Idx.by_ref, :int32, :int32, :int32, :pointer],
      :int

    # int mm_max_spsc_bonus(const mm_mapopt_t *mo);
    attach_function \
      :mm_max_spsc_bonus,
      [MapOpt.by_ref],
      :int

    # int32_t mm_idx_spsc_read(mm_idx_t *idx, const char *fn, int32_t max_sc);
    attach_function \
      :mm_idx_spsc_read,
      [Idx.by_ref, :string, :int32],
      :int32

    # int32_t mm_idx_spsc_read2(mm_idx_t *idx, const char *fn, int32_t max_sc, float scale);
    attach_function \
      :mm_idx_spsc_read2,
      [Idx.by_ref, :string, :int32, :float],
      :int32

    # int64_t mm_idx_spsc_get(const mm_idx_t *db, int32_t cid, int64_t st0, int64_t en0, int32_t rev, uint8_t *sc);
    attach_function \
      :mm_idx_spsc_get,
      [Idx.by_ref, :int32, :int64, :int64, :int32, :pointer],
      :int64

    # void mm_mapopt_init(mm_mapopt_t *opt);
    attach_function \
      :mm_mapopt_init,
      [MapOpt.by_ref],
      :void

    # mm_idx_t *mm_idx_build(const char *fn, int w, int k, int flag, int n_threads);
    attach_function \
      :mm_idx_build,
      %i[string int int int int],
      Idx.by_ref

    # mmpriv.h

    attach_function \
      :mm_idxopt_init,
      [IdxOpt.by_ref],
      :void
  end
end
