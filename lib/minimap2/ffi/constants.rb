# frozen_string_literal: true

module Minimap2
  module FFI
    MM_F_NO_DIAG      = 0x001 # no exact diagonal hit
    MM_F_NO_DUAL      = 0x002 # skip pairs where query name is lexicographically larger than target name
    MM_F_CIGAR        = 0x004
    MM_F_OUT_SAM      = 0x008
    MM_F_NO_QUAL      = 0x010
    MM_F_OUT_CG       = 0x020
    MM_F_OUT_CS       = 0x040
    MM_F_SPLICE       = 0x080 # splice mode
    MM_F_SPLICE_FOR   = 0x100 # match GT-AG
    MM_F_SPLICE_REV   = 0x200 # match CT-AC, the reverse complement of GT-AG
    MM_F_NO_LJOIN     = 0x400
    MM_F_OUT_CS_LONG  = 0x800
    MM_F_SR           = 0x1000
    MM_F_FRAG_MODE    = 0x2000
    MM_F_NO_PRINT_2ND = 0x4000
    MM_F_2_IO_THREADS = 0x8000
    MM_F_LONG_CIGAR   = 0x10000
    MM_F_INDEPEND_SEG = 0x20000
    MM_F_SPLICE_FLANK = 0x40000
    MM_F_SOFTCLIP     = 0x80000
    MM_F_FOR_ONLY     = 0x100000
    MM_F_REV_ONLY     = 0x200000
    MM_F_HEAP_SORT    = 0x400000
    MM_F_ALL_CHAINS   = 0x800000
    MM_F_OUT_MD       = 0x1000000
    MM_F_COPY_COMMENT = 0x2000000
    MM_F_EQX          = 0x4000000 # use =/X instead of M
    MM_F_PAF_NO_HIT   = 0x8000000 # output unmapped reads to PAF
    MM_F_NO_END_FLT   = 0x10000000
    MM_F_HARD_MLEVEL  = 0x20000000
    MM_F_SAM_HIT_ONLY = 0x40000000

    MM_I_HPC          = 0x1
    MM_I_NO_SEQ       = 0x2
    MM_I_NO_NAME      = 0x4

    MM_IDX_MAGIC      = "MMI\2"

    MM_MAX_SEG        = 255

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
        :max_gap,              :int,     # break a chain if there are no minimizers in a max_gap window
        :max_gap_ref,          :int,
        :max_frag_len,         :int,
        :max_chain_skip,       :int,
        :max_chain_iter,       :int,
        :min_cnt,              :int,     # min number of minimizers on each chain
        :min_chain_score,      :int,     # min chaining score
        :chain_gap_scale,      :float,
        :mask_level,           :float,
        :mask_len,             :int,
        :pri_ratio,            :float,
        :best_n,               :int,     # top best_n chains are subjected to DP alignment
        :max_join_long,        :int,
        :max_join_short,       :int,
        :min_join_flank_sc,    :int,
        :min_join_flank_ratio, :float,
        :alt_drop,             :float,
        :a,                    :int,     # matching score
        :b,                    :int,     # mismatch
        :q,                    :int,     # gap-open
        :e,                    :int,     # gap-ext
        :q2,                   :int,     # gap-open
        :e2,                   :int,     # gap-ext
        :sc_ambi,              :int,     # score when one or both bases are "N"
        :noncan,               :int,     # cost of non-canonical splicing sites
        :junc_bonus,           :int,
        :zdrop,                :int,     # break alignment if alignment score drops too fast along the diagonal
        :zdrop_inv,            :int,
        :end_bonus,            :int,
        :min_dp_max,           :int,     # drop an alignment if the score of the max scoring segment is below this threshold
        :min_ksw_len,          :int,
        :anchor_ext_len,       :int,
        :anchor_ext_shift,     :int,
        :max_clip_ratio,       :float,   # drop an alignment if BOTH ends are clipped above this ratio
        :pe_ori,               :int,
        :pe_bonus,             :int,
        :mid_occ_frac,         :float,   # only used by mm_mapopt_update(); see below
        :min_mid_occ,          :int32_t,
        :mid_occ,              :int32_t, # ignore seeds with occurrences above this threshold
        :max_occ,              :int32_t,
        :mini_batch_size,      :int64_t, # size of a batch of query bases to process in parallel
        :max_sw_mat,           :int64_t,
        :split_prefix,         :string
    end

    # minimap2 index
    class IdxSeq < ::FFI::Struct
      layout \
        :name,   :string,    # name of the db sequence
        :offset, :uint64_t,  # offset in mm_idx_t::S
        :len,    :uint32_t,  # length
        :is_alt, :uint32_t
    end

    class Idx < ::FFI::Struct
      layout \
        :b,     :int32_t,
        :w,     :int32_t,
        :k,     :int32_t,
        :flag,  :int32_t,
        :n_seq, :uint32_t,   # number of reference sequences
        :index, :int32_t,
        :n_alt, :int32_t,
        :seq,   IdxSeq.ptr,  # sequence name, length and offset
        :S,     :pointer,    # 4-bit packed sequence
        :B,     :pointer,    # index (hidden)
        :I,     :pointer,    # intervals (hidden)
        :km,    :pointer,
        :h,     :pointer
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

    # minimap2 alignment
    class Extra < ::FFI::BitStruct
      layout \
        :capacity,            :uint32,  # the capacity of cigar[]
        :dp_score,            :int32,   # DP score
        :dp_max,              :int32,   # score of the max-scoring segment
        :dp_max2,             :int32,   # score of the best alternate mappings
        :n_ambi_trans_strand, :uint32,
        :n_cigar,             :uint32

      bitfields :n_ambi_trans_strand,
                :n_ambi, 30,      # number of ambiguous bases
                :trans_strand, 2  # transcript strand: 0 for unknown, 1 for +, 2 for -

      def [](name)
        if name == :cigar
          pointer.get_array_of_uint32(size, self[:n_cigar])
        else
          super
        end
      end
    end

    class Reg1 < ::FFI::BitStruct
      layout \
        :id,     :int32_t, # ID for internal uses (see also parent below)
        :cnt,    :int32_t, # number of minimizers; if on the reverse strand
        :rid,    :int32_t, # reference index; if this is an alignment from inversion rescue
        :score,  :int32_t, # DP alignment score
        :qs,     :int32_t, # query start
        :qe,     :int32_t, # query end
        :rs,     :int32_t, # reference start
        :re,     :int32_t, # reference end
        :parent, :int32_t, # parent==id if primary
        :subsc,  :int32_t, # best alternate mapping score
        :as,     :int32_t, # offset in the a[] array (for internal uses only)
        :mlen,   :int32_t, # seeded exact match length
        :blen,   :int32_t, # seeded alignment block length
        :n_sub,  :int32_t, # number of suboptimal mappings
        :score0, :int32_t, # initial chaining score (before chain merging/spliting)
        :fields, :uint32_t,
        :hash,   :uint32_t,
        :div,    :float,
        :p,      Extra.ptr

      bitfields :fields,
                :mapq,        8,
                :split,       2,
                :rev,         1,
                :inv,         1,
                :sam_pri,     1,
                :proper_frag, 1,
                :pe_thru,     1,
                :seg_split,   1,
                :seg_id,      8,
                :split_inv,   1,
                :is_alt,      1,
                :dummy,       6
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
