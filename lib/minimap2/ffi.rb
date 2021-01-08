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
      :x, :uint64_t,
      :y, :uint64_t
    end

    class MM128V < ::FFI::Struct
      :n, :size_t,
      :m, :size_t,
      :a, MM128
    end

    class IdxBucket < ::FFI::Struct
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
                    [:string, IdxOpt.by_ref, MapOpt.by_ref],
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
        :B,     :ointer, # IdxBucket
        :km,    :pointer,
        :h,     :pointer
    end

    class IdxReader < ::FFI::Struct
      layout \
        :is_idx,      :int
        :n_parts,     :int
        :idx_size,    :int64_t
        :opt,         Idxopt,
        :fp_out,      :pointer # FILE
        :
    end

    attach_function :mm_idx_reader_open,
    [:string, Idxopt, :string], IdxReader
    attach_function :mm_idx_reader_read
    attach_function :mm_idx_reader_close
    attach_function :mm_idx_destroy
    attach_function :mm_mapopt_update

    attach_function :mm_idx_index_name

  end
end
