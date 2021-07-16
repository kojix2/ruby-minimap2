# frozen_string_literal: true

# dependencies
require 'ffi'

# bit fields
require_relative 'minimap2/ffi_helper'

# modules
require_relative 'minimap2/aligner'
require_relative 'minimap2/alignment'
require_relative 'minimap2/version'

# Minimap2 mapper for long read sequences
# https://github.com/lh3/minimap2
# Li, H. (2018). Minimap2: pairwise alignment for nucleotide sequences. Bioinformatics, 34:3094-3100.
# doi:10.1093/bioinformatics/bty191
module Minimap2
  class Error < StandardError; end

  class << self
    attr_accessor :ffi_lib
  end

  lib_name = ::FFI.map_library_name('minimap2')
  self.ffi_lib = if ENV['MINIMAPDIR']
                   File.expand_path(lib_name, ENV['MINIMAPDIR'])
                 else
                   File.expand_path("../vendor/#{lib_name}", __dir__)
                 end

  # friendlier error message
  autoload :FFI, 'minimap2/ffi'

  # methods from mappy
  class << self
    # Read fasta/fastq file.
    # @param [String] file_path
    # @param [Boolean] comment If True, the comment will be read.
    # @yield [name, seq, qual, comment]
    # Note: You can also use a generic library such as BioRuby instead of this method.

    def fastx_read(file_path, comment: false)
      path = File.expand_path(file_path)
      ks = FFI.mm_fastx_open(path)
      while FFI.kseq_read(ks) >= 0
        qual = ks[:qual][:s] if (ks[:qual][:l]).positive?
        name = ks[:name][:s]
        seq  = ks[:seq][:s]
        if comment
          comment = ks[:comment][:s] if (ks[:comment][:l]).positive?
          yield [name, seq, qual, comment]
        else
          yield [name, seq, qual]
        end
      end
      FFI.mm_fastx_close(ks)
    end

    # Reverse complement sequence.
    # @param [String] seq
    # @return [string] seq

    def revcomp(seq)
      l = seq.size
      bseq = ::FFI::MemoryPointer.new(:char, l)
      bseq.put_bytes(0, seq)
      FFI.mappy_revcomp(l, bseq)
    end

    # Set verbosity level.
    # @param [Integer] level

    def verbose(level = -1)
      FFI.mm_verbose_level(level)
    end
  end
end
