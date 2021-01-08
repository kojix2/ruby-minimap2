module FFI
  class Struct
    def self.union_layout(*args)
      Class.new(FFI::Union) { layout(*args) }
    end

    def self.struct_layout(*args)
      Class.new(FFI::Struct) { layout(*args) }
    end
  end
end

module Minimap2
  module FFI
    extend ::FFI::Library

    begin
      ffi_lib Minimap2.ffi_lib
    rescue LoadError => e
      raise LoadError, "Could not find #{Minimap2.ffi_lib}"
    end

    def self.attach_function(*)
      super
    rescue ::FFI::NotFoundError => e
      warn e.message
    end

    class MM128 < ::FFI::Struct
      layout \
        :x, :uint64_t,
        :y, :uint64_t
    end

    class MM128V < ::FFI::Struct
      layout \
        :n, :size_t,
        :m, :size_t,
        :a, MM128.ptr
    end

    class IdxBucket < ::FFI::Struct
      layout \
        :a, MM128,
        :n, :int32_t,
        :p, :pointer,
        :h, :pointer
    end

    class Idxopt < ::FFI::Struct
      layout \
        :k,               :short,
        :w,               :short,
        :flag,            :short,
        :bucket_bits,     :short,
        :mini_batch_size, :int64_t,
        :batch_size,      :uint64_t
    end

    class Mapopt < ::FFI::Struct
      layout \
        :flag,                 :int64_t,
        :seed,                 :int,
        :sdust_thres,          :int,
        :max_qlen,             :int,
        :bw,                   :int,
        :max_gap,              :int,
        :max_gap_ref,          :int,
        :max_frag_len,         :int,
        :max_chain_skip,       :int,
        :max_chain_iter,       :int,
        :min_cnt,              :int,
        :min_chain_score,      :int,
        :chain_gap_scale,      :float,
        :mask_level,           :float,
        :mask_len,             :int,
        :pri_ratio,            :float,
        :best_n,               :int,
        :max_join_long,        :int,
        :max_join_short,       :int,
        :min_join_flank_sc,    :int,
        :min_join_flank_ratio, :float,
        :alt_drop,             :float,
        :a,                    :int,
        :b,                    :int,
        :q,                    :int,
        :e,                    :int,
        :q2,                   :int,
        :e2,                   :int,
        :sc_ambi,              :int,
        :noncan,               :int,
        :junc_bonus,           :int,
        :zdrop,                :int,
        :zdrop_inv,            :int,
        :end_bonus,            :int,
        :min_dp_max,           :int,
        :min_ksw_len,          :int,
        :anchor_ext_len,       :int,
        :anchor_ext_shift,     :int,
        :max_clip_ratio,       :float,
        :pe_ori,               :int,
        :pe_bonus,             :int,
        :mid_occ_frac,         :float,
        :min_mid_occ,          :int32_t,
        :mid_occ,              :int32_t,
        :max_occ,              :int32_t,
        :mini_batch_size,      :int64_t,
        :max_sw_mat,           :int64_t,
        :split_prefix,         :string
    end

    attach_function :mm_set_opt,
                    [:string, Idxopt.by_ref, Mapopt.by_ref],
                    :int

    class IdxSeq < ::FFI::Struct
      layout \
        :name,   :string,
        :offset, :uint64_t,
        :len,    :uint32_t
    end

    class Idx < ::FFI::Struct
      layout \
        :b,     :int32_t,
        :w,     :int32_t,
        :k,     :int32_t,
        :flag,  :int32_t,
        :n_seq, :uint32_t,
        :seq,   IdxSeq.ptr,
        :S,     :pointer,
        :B,     :pointer, # IdxBucket
        :km,    :pointer,
        :h,     :pointer
    end

    class IdxReader < ::FFI::Struct
      layout \
        :is_idx,      :int,
        :n_parts,     :int,
        :idx_size,    :int64_t,
        :opt,         Idxopt,
        :fp_out,      :pointer, # FILE
        :seq_or_idx,  :pointer  # Union mm_bseq_files or FILE
    end

    class Extra < FFI::Struct
      layout \
        :capacity,            :uint32,
        :dp_score,            :int32,
        :dp_max,              :int32,
        :dp_max2,             :int32,
        :n_ambi_trans_strand, :uint32, # FIXME
        :n_cigar,             :uint32
    end

    class REG1 < ::FFI::Struct
      layout \
        :id,     :int32_t,
        :cnt,    :int32_t,
        :rid,    :int32_t,
        :score,  :int32_t,
        :qs,     :int32_t,
        :qe,     :int32_t,
        :rs,     :int32_t,
        :re,     :int32_t,
        :parent, :int32_t,
        :subsc,  :int32_t,
        :as,     :int32_t,
        :mlen,   :int32_t,
        :blen,   :int32_t,
        :n_sub,  :int32_t,
        :score0, :int32_t,
        :hoge,   :uint32_t, # FIXME
        :hash,   :uint32_t,
        :div,    :float,
        :p       Extra.ptr
    end

    attach_function \
      :mm_idx_reader_open,
      [:string, Idxopt.by_ref, :string],
      IdxReader

    attach_function \
      :mm_idx_reader_read,
      [IdxReader.by_ref, :int],
      Idx

    attach_function \
      :mm_idx_reader_close,
      [IdxReader.by_ref],
      :void

    attach_function \
      :mm_idx_destroy,
      [Idx.by_ref],
      :void

    attach_function \
      :mm_mapopt_update,
      [Mapopt.by_ref, Idx.by_ref],
      :void

    attach_function \
      :mm_idx_index_name,
      [Idx.by_ref],
      :int
  end
end
