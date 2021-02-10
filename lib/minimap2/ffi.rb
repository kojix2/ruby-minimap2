# frozen_string_literal: true

require_relative "ffi_helper"

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
  end
end

require_relative "ffi/functions"
require_relative "ffi/constants"
require_relative "ffi/mappy"
