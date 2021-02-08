# frozen_string_literal: true

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
  end
end
