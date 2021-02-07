# frozen_string_literal: true

require "ffi"
require_relative "minimap2/ffi_helper"
require_relative "minimap2/version"

module Minimap2
  class Error < StandardError; end

  class << self
    attr_accessor :ffi_lib
  end

  suffix = ::FFI::Platform::LIBSUFFIX

  self.ffi_lib = if ENV["MINIMAPDIR"]
                   File.expand_path("libminimap2.#{suffix}", ENV["MINIMAPDIR"])
                 else
                   File.expand_path("../vendor/libminimap2.#{suffix}", __dir__)
                 end
  autoload :FFI, "minimap2/ffi"
end

require_relative "minimap2/aligner"
require_relative "minimap2/alignment"
