# frozen_string_literal: true

# https://github.com/lh3/minimap2/blob/master/python/cmappy.h

module Minimap2
  module FFI
    class Hit < ::FFI::Struct
      layout \
        :ctg,          :string,
        :ctg_start,    :int32_t,
        :ctg_end,      :int32_t,
        :qry_start,    :int32_t,
        :qry_end,      :int32_t,
        :blen,         :int32_t,
        :mlen,         :int32_t,
        :NM,           :int32_t,
        :ctg_len,      :int32_t,
        :mapq,         :uint8_t,
        :is_primary,   :uint8_t,
        :strand,       :int8_t,
        :trans_strand, :int8_t,
        :seg_id,       :int32_t,
        :n_cigar32,    :int32_t,
        :cigar32,      :pointer
    end

    attach_function \
      :mm_reg2hitpy,
      [Idx.by_ref, Reg1.by_ref, Hit.by_ref],
      :void

    attach_function \
      :mm_free_reg1,
      [Reg1.by_ref],
      :void

    attach_function \
      :mm_fastx_open,
      [:string],
      :pointer # FIXME: KSeq.by_ref

    attach_function \
      :mm_fastx_close,
      [:pointer], # FIXME: KSeq.by_ref
      :void

    attach_function \
      :mm_verbose_level,
      [:int],
      :int

    attach_function \
      :mm_reset_timer,
      [:void],
      :void

    attach_function \
      :mm_map_aux,
      [Idx.by_ref, :string, :string, :pointer, TBuf.by_ref, MapOpt.by_ref],
      Reg1.by_ref
  end
end
