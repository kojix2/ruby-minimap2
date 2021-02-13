# frozen_string_literal: true

# dependencies
require "ffi"

# bit fields
require_relative "minimap2/ffi_helper"

# modules
require_relative "minimap2/aligner"
require_relative "minimap2/alignment"
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

  # methods from mappy
  class << self
    def fastx_read(fn, _read_comment = false)
      ks = FFI.mm_fastx_open(fn)
      while FFI.kseq_read(ks) >= 0
        qual = ks[:qual][:s] if (ks[:qual][:l]).positive?
        name = ks[:name][:s]
        seq  = ks[:seq][:s]
        comment = ks[:comment][:s] if (ks[:comment][:l]).positive?
        yield [name, seq, qual, comment]
      end
      FFI.mm_fastx_close(ks)
    end

    def revcomp(seq)
      l = seq.size
      bseq = ::FFI::MemoryPointer.new(:char, l)
      bseq.put_bytes(0, seq)
      FFI.mappy_revcomp(l, bseq)
    end

    def verbose(v = -1)
      FFI.mm_verbose_level(v)
    end
  end
end
