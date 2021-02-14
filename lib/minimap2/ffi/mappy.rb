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

    class KString < ::FFI::Struct
      layout \
        :l,            :size_t,
        :m,            :size_t,
        :s,            :string
    end

    class KSeq < ::FFI::Struct
      layout \
        :name,           KString,
        :comment,        KString,
        :seq,            KString,
        :qual,           KString,
        :last_char,      :int,
        :f,              :pointer # FIXME: KStream
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
      KSeq.by_ref

    attach_function \
      :mm_fastx_close,
      [KSeq.by_ref],
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
      :pointer # Reg1

    attach_function \
      :mappy_revcomp,
      %i[int pointer],
      :string

    attach_function \
      :mappy_fetch_seq,
      [Idx.by_ref, :string, :int, :int, :pointer],
      :pointer # Use pointer instead of string to read with a specified length

    attach_function \
      :mappy_idx_seq,
      %i[int int int int pointer int],
      Idx.by_ref

    attach_function \
      :kseq_read,
      [KSeq.by_ref],
      :int
  end
end
