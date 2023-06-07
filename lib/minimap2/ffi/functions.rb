# frozen_string_literal: true

module Minimap2
  module FFI
    attach_function \
      :main,
      %i[int pointer],
      :int

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
      [:pointer, :pointer, :pointer, Idx.by_ref, Reg1.by_ref, :string, :int],
      :int

    attach_function \
      :mm_gen_md, :mm_gen_MD, # Avoid uppercase letters in method names.
      [:pointer, :pointer, :pointer, Idx.by_ref, Reg1.by_ref, :string],
      :int

    attach_function \
      :mm_mapopt_init,
      [MapOpt.by_ref],
      :void

    # mmpriv.h

    attach_function \
      :mm_idxopt_init,
      [IdxOpt.by_ref],
      :void
  end
end
