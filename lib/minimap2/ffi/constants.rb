# frozen_string_literal: true

module Minimap2
  module FFI
    # flags
    NO_DIAG          = 0x001 # no exact diagonal hit
    NO_DUAL          = 0x002 # skip pairs where query name is lexicographically larger than target name
    CIGAR            = 0x004
    OUT_SAM          = 0x008
    NO_QUAL          = 0x010
    OUT_CG           = 0x020
    OUT_CS           = 0x040
    SPLICE           = 0x080 # splice mode
    SPLICE_FOR       = 0x100 # match GT-AG
    SPLICE_REV       = 0x200 # match CT-AC, the reverse complement of GT-AG
    NO_LJOIN         = 0x400
    OUT_CS_LONG      = 0x800
    SR               = 0x1000
    FRAG_MODE        = 0x2000
    NO_PRINT_2ND     = 0x4000
    TWO_IO_THREADS   = 0x8000 # Translator's Note. MM_F_2_IO_THREADS. Constants starting with numbers cannot be defined.
    LONG_CIGAR       = 0x10000
    INDEPEND_SEG     = 0x20000
    SPLICE_FLANK     = 0x40000
    SOFTCLIP         = 0x80000
    FOR_ONLY         = 0x100000
    REV_ONLY         = 0x200000
    HEAP_SORT        = 0x400000
    ALL_CHAINS       = 0x800000
    OUT_MD           = 0x1000000
    COPY_COMMENT     = 0x2000000
    EQX              = 0x4000000 # use =/X instead of M
    PAF_NO_HIT       = 0x8000000 # output unmapped reads to PAF
    NO_END_FLT       = 0x10000000
    HARD_MLEVEL      = 0x20000000
    SAM_HIT_ONLY     = 0x40000000
    RMQ              = 0x80000000
    QSTRAND          = 0x100000000
    NO_INV           = 0x200000000
    NO_HASH_NAME     = 0x400000000
    SPLICE_OLD       = 0x800000000
    SECONDARY_SEQ    = 0x1000000000 # output SEQ field for seqondary alignments using hard clipping
    OUT_DS           = 0x2000000000
    WEAK_PAIRING     = 0x4000000000
    SR_RNA           = 0x8000000000
    OUT_JUNC         = 0x10000000000

    HPC              = 0x1
    NO_SEQ           = 0x2
    NO_NAME          = 0x4

    IDX_MAGIC        = "MMI\2"

    MAX_SEG          = 255

    CIGAR_MATCH      = 0
    CIGAR_INS        = 1
    CIGAR_DEL        = 2
    CIGAR_N_SKIP     = 3
    CIGAR_SOFTCLIP   = 4
    CIGAR_HARDCLIP   = 5
    CIGAR_PADDING    = 6
    CIGAR_EQ_MATCH   = 7
    CIGAR_X_MISMATCH = 8

    CIGAR_STR        = "MIDNSHP=XB"

    # emulate 128-bit integers
    class MM128 < ::FFI::Struct
      layout \
        :x, :uint64_t,
        :y, :uint64_t
    end

    # emulate 128-bit arrays
    class MM128V < ::FFI::Struct
      layout \
        :n, :size_t,
        :m, :size_t,
        :a, MM128.ptr
    end

    # minimap2 index
    class IdxSeq < ::FFI::Struct
      layout \
        :name,   :string,    # name of the db sequence
        :offset, :uint64_t,  # offset in mm_idx_t::S
        :len,    :uint32,  # length
        :is_alt, :uint32
    end

    class Idx < ::FFI::Struct
      layout \
        :b,     :int32,
        :w,     :int32,
        :k,     :int32,
        :flag,  :int32,
        :n_seq, :uint32,   # number of reference sequences
        :index, :int32,
        :n_alt, :int32,
        :seq,   IdxSeq.ptr,  # sequence name, length and offset
        :S,     :pointer,    # 4-bit packed sequence
        :B,     :pointer,    # index (hidden)
        :I,     :pointer,    # intervals (hidden)
        :spsc,  :pointer,    # splice score (hidden)
        :J,     :pointer,    # junctions to create jumps (hidden)
        :km,    :pointer,
        :h,     :pointer
    end

    # minimap2 alignment
    class Extra < ::FFI::BitStruct
      layout \
        :capacity,            :uint32,  # the capacity of cigar[]
        :dp_score,            :int32,   # DP score
        :dp_max,              :int32,   # score of the max-scoring segment
        :dp_max2,             :int32,   # score of the best alternate mappings
        :dp_max0,             :int32,   # DP score before mm_update_dp_max() adjustment
        :n_ambi_trans_strand, :uint32,
        :n_cigar,             :uint32
      # :cigar,               :pointer  # variable length array (see cigar method below)

      bit_field :n_ambi_trans_strand,
                :n_ambi, 30,      # number of ambiguous bases
                :trans_strand, 2  # transcript strand: 0 for unknown, 1 for +, 2 for -

      # variable length array
      def cigar
        pointer.get_array_of_uint32(size, self[:n_cigar])
      end
    end

    class Reg1 < ::FFI::BitStruct
      layout \
        :id,     :int32, # ID for internal uses (see also parent below)
        :cnt,    :int32, # number of minimizers; if on the reverse strand
        :rid,    :int32, # reference index; if this is an alignment from inversion rescue
        :score,  :int32, # DP alignment score
        :qs,     :int32, # query start
        :qe,     :int32, # query end
        :rs,     :int32, # reference start
        :re,     :int32, # reference end
        :parent, :int32, # parent==id if primary
        :subsc,  :int32, # best alternate mapping score
        :as,     :int32, # offset in the a[] array (for internal uses only)
        :mlen,   :int32, # seeded exact match length
        :blen,   :int32, # seeded alignment block length
        :n_sub,  :int32, # number of suboptimal mappings
        :score0, :int32, # initial chaining score (before chain merging/spliting)
        :fields, :uint32,
        :hash,   :uint32,
        :div,    :float,
        :p,      Extra.ptr

      bit_field :fields,
                :mapq,            8,
                :split,           2,
                :rev,             1,
                :inv,             1,
                :sam_pri,         1,
                :proper_frag,     1,
                :pe_thru,         1,
                :seg_split,       1,
                :seg_id,          8,
                :split_inv,       1,
                :is_alt,          1,
                :strand_retained, 1,
                :is_spliced,      1,
                :dummy,           4
    end

    # indexing option
    class IdxOpt < ::FFI::Struct
      layout \
        :k,               :short,
        :w,               :short,
        :flag,            :short,
        :bucket_bits,     :short,
        :mini_batch_size, :int64_t,
        :batch_size,      :uint64_t
    end

    # mapping option
    class MapOpt < ::FFI::Struct
      layout \
        :flag,                 :int64_t, # see MM_F_* macros
        :seed,                 :int,
        :sdust_thres,          :int,     # score threshold for SDUST; 0 to disable
        :max_qlen,             :int,     # max query length
        :bw,                   :int,     # bandwidth
        :bw_long,              :int,
        :max_gap,              :int,     # break a chain if there are no minimizers in a max_gap window
        :max_gap_ref,          :int,
        :max_frag_len,         :int,
        :max_chain_skip,       :int,
        :max_chain_iter,       :int,
        :min_cnt,              :int,     # min number of minimizers on each chain
        :min_chain_score,      :int,     # min chaining score
        :chain_gap_scale,      :float,
        :chain_skip_scale,     :float,
        :rmq_size_cap,         :int,
        :rmq_inner_dist,       :int,
        :rmq_rescue_size,      :int,
        :rmq_rescue_ratio,     :float,
        :mask_level,           :float,
        :mask_len,             :int,
        :pri_ratio,            :float,
        :best_n,               :int,     # top best_n chains are subjected to DP alignment
        :alt_drop,             :float,
        :a,                    :int,     # matching score
        :b,                    :int,     # mismatch
        :q,                    :int,     # gap-open
        :e,                    :int,     # gap-ext
        :q2,                   :int,     # gap-open
        :e2,                   :int,     # gap-ext
        :transition,           :int,     # transition mismatch score (A:G, C:T)
        :sc_ambi,              :int,     # score when one or both bases are "N"
        :noncan,               :int,     # cost of non-canonical splicing sites
        :junc_pen,             :int,
        :junc_bonus,           :int,
        :zdrop,                :int,     # break alignment if alignment score drops too fast along the diagonal
        :zdrop_inv,            :int,
        :end_bonus,            :int,
        :min_dp_max,           :int,     # drop an alignment if the score of the max scoring segment is below this threshold
        :min_ksw_len,          :int,
        :anchor_ext_len,       :int,
        :anchor_ext_shift,     :int,
        :max_clip_ratio,       :float,   # drop an alignment if BOTH ends are clipped above this ratio
        :rank_min_len,         :int,
        :rank_frac,            :float,
        :pe_ori,               :int,
        :pe_bonus,             :int,
        :jump_min_match,       :int32,
        :mid_occ_frac,         :float,   # only used by mm_mapopt_update(); see below
        :q_occ_frac,           :float,
        :min_mid_occ,          :int32,
        :max_mid_occ,          :int32,
        :mid_occ,              :int32,   # ignore seeds with occurrences above this threshold
        :max_occ,              :int32,
        :max_max_occ,          :int32,
        :occ_dist,             :int32,
        :mini_batch_size,      :int64_t, # size of a batch of query bases to process in parallel
        :max_sw_mat,           :int64_t,
        :cap_kalloc,           :int64_t,
        :split_prefix,         :string
    end

    # index reader
    class IdxReader < ::FFI::Struct
      layout \
        :is_idx,      :int,
        :n_parts,     :int,
        :idx_size,    :int64_t,
        :opt,         IdxOpt,
        :fp_out,      :pointer, # FILE
        :seq_or_idx,  :pointer  # FIXME: Union mm_bseq_files or FILE
    end

    # memory buffer for thread-local storage during mapping
    class TBuf < ::FFI::Struct
      layout \
        :km,       :pointer,
        :rep_len,  :int,
        :frag_gap, :int
    end
  end
end
