# frozen_string_literal: true

module Minimap2
  class Error < StandardError; end
end

begin
  require "minimap2/minimap2_ext"
rescue LoadError => e
  # Allow running directly from a source checkout after `rake compile`.
  extension = File.expand_path("../ext/ruby_minimap2/minimap2_ext", __dir__)
  raise e unless Dir["#{extension}.{so,bundle,dylib,dll}"].any?

  require extension
end

require_relative "minimap2/alignment"
require_relative "minimap2/version"

# Ruby bindings for the minimap2 sequence aligner.
module Minimap2
  class << self
    # Run minimap2's command entry point. Each Ruby argument is one argv item.
    def execute(*arguments)
      Native.execute(*arguments)
    end

    def verbose
      Native.verbose
    end

    def verbose=(level)
      Native.verbose = level
    end

    # Read records from a FASTA or FASTQ file.
    def fastx_read(file_path, comment: false)
      path = file_path.to_s == "-" ? "-" : File.expand_path(file_path)
      raise Error, "Cannot open FASTA/FASTQ file: #{path}" unless path == "-" || File.file?(path)

      reader = Native::FastxReader.new(path)
      if block_given?
        begin
          while (record = reader.next_record(comment))
            yield record
          end
        ensure
          reader.close
        end
      else
        Enumerator.new do |yielder|
          while (record = reader.next_record(comment))
            yielder << record
          end
        ensure
          reader.close
        end
      end
    end

    def revcomp(sequence)
      Native.revcomp(sequence)
    end
  end
end
