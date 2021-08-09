# frozen_string_literal: true

# bit fields
require 'ffi/bit_struct'
module Minimap2
  # Native APIs
  module FFI
    extend ::FFI::Library
    begin
      ffi_lib Minimap2.ffi_lib
    rescue LoadError => e
      raise LoadError, "Could not find #{Minimap2.ffi_lib} \n#{e}"
    end

    # Continue even if some functions are not found.
    def self.attach_function(*)
      super
    rescue ::FFI::NotFoundError => e
      warn e.message
    end
  end
end

require_relative 'ffi/constants'
require_relative 'ffi/functions'
require_relative 'ffi/mappy'
