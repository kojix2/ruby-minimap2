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

    class IdxOpt < ::FFI::Struct
      layout \
        :k,               :short,
        :w,               :short,
        :flag,            :short,
        :bucket_bits,     :short,
        :mini_batch_size, :int64_t,
        :batch_size,      :uint64_t
    end

    class MapOpt < ::FFI::Struct
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
  end
end
