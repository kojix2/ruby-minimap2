# frozen_string_literal: true

require_relative "ffi_helper"
require_relative "ffi/constants"

module Minimap2
  module FFI
    extend ::FFI::Library

    begin
      ffi_lib Minimap2.ffi_lib
    rescue LoadError => e
      raise LoadError, "Could not find #{Minimap2.ffi_lib} \n#{e}"
    end

    def self.attach_function(*)
      super
    rescue ::FFI::NotFoundError => e
      warn e.message
    end

    attach_function \
      :mm_set_opt,
      [:string, IdxOpt.by_ref, MapOpt.by_ref],
      :int

    attach_function \
      :mm_idx_reader_open,
      [:string, IdxOpt.by_ref, :string],
      IdxReader.by_ref

    attach_function \
      :mm_idx_reader_read,
      [IdxReader.by_ref, :int],
      Idx.by_ref

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
      [MapOpt.by_ref, Idx.by_ref],
      :void

    attach_function \
      :mm_idx_index_name,
      [Idx.by_ref],
      :int

    attach_function \
      :mm_tbuf_init,
      [],
      TBuf.by_ref

    attach_function \
      :mm_tbuf_destroy,
      [TBuf.by_ref],
      :void

    attach_function \
      :mm_tbuf_get_km,
      [TBuf.by_ref],
      :pointer

    attach_function \
      :mm_gen_cs,
      [:pointer, :pointer, :int, Idx.by_ref, Reg1.by_ref, :string, :int],
      :int

    attach_function \
      :mm_gen_MD,
      [:pointer, :pointer, :int, Idx.by_ref, Reg1.by_ref, :string],
      :int
  end
end

require_relative "ffi/mappy"
