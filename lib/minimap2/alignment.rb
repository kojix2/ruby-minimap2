# frozen_string_literal: true

module Minimap2
  # Alignment result.
  #
  # @!attribute ctg
  #   @return [String] name of the reference sequence the query is mapped to.
  # @!attribute ctg_len
  #   @return [Integer] total length of the reference sequence.
  # @!attribute r_st
  #   @return [Integer] start positions on the reference.
  # @!attribute r_en
  #   @return [Integer] end positions on the reference.
  # @!attribute strand
  #   @return [Integer] +1 if on the forward strand; -1 if on the reverse strand.
  # @!attribute trans_strand
  #   @return [Integer] transcript strand.
  #     +1 if on the forward strand; -1 if on the reverse strand; 0 if unknown.
  # @!attribute blen
  #   @return [Integer] length of the alignment, including both alignment matches and gaps
  #      but excluding ambiguous bases.
  # @!attribute mlen
  #   @return [Integer] length of the matching bases in the alignment,
  #     excluding ambiguous base matches.
  # @!attribute nm
  #   @return [Integer] number of mismatches, gaps and ambiguous poistions in the alignment.
  # @!attribute primary
  #   @return [Integer] if the alignment is primary (typically the best and the first to generate)
  # @!attribute q_st
  #   @return [Integer] start positions on the query.
  # @!attribute q_en
  #   @return [Integer] end positions on the query.
  # @!attribute mapq
  #   @return [Integer] mapping quality.
  # @!attribute cigar
  #   @return [Array] CIGAR returned as an array of shape (n_cigar,2).
  #     The two numbers give the length and the operator of each CIGAR operation.
  # @!attribute read_num
  #   @return [Integer] read number that the alignment corresponds to;
  #     1 for the first read and 2 for the second read.
  # @!attribute cs
  #   @return [String] the cs tag.
  # @!attribute md
  #   @return [String] the MD tag as in the SAM format.
  #     It is an empty string unless the md argument is applied when calling Aligner#align.
  # @!attribute cigar_str
  #   @return [String] CIGAR string.

  class Alignment
    def self.keys
      %i[ctg ctg_len r_st r_en strand trans_strand blen mlen nm primary
         q_st q_en mapq cigar read_num cs md cigar_str]
    end

    attr_reader(*keys)

    def initialize(h, cigar, cs = nil, md = nil)
      @ctg          = h[:ctg]
      @ctg_len      = h[:ctg_len]
      @r_st         = h[:ctg_start]
      @r_en         = h[:ctg_end]
      @strand       = h[:strand]
      @trans_strand = h[:trans_strand]
      @blen         = h[:blen]
      @mlen         = h[:mlen]
      @nm           = h[:NM]
      @primary      = h[:is_primary]
      @q_st         = h[:qry_start]
      @q_en         = h[:qry_end]
      @mapq         = h[:mapq]
      @cigar        = cigar
      @read_num     = h[:seg_id] + 1
      @cs           = cs
      @md           = md

      @cigar_str = cigar.map { |x| x[0].to_s + FFI::CIGAR_STR[x[1]] }.join
    end

    def primary?
      @primary == 1
    end

    # Convert Alignment to hash.

    def to_h
      self.class.keys.map { |k| [k, __send__(k)] }.to_h
    end

    # Convert to the PAF format without the QueryName and QueryLength columns.

    def to_s
      strand = if @strand.positive?
                 '+'
               elsif @strand.negative?
                 '-'
               else
                 '?'
               end
      tp = @primary != 0 ? 'tp:A:P' : 'tp:A:S'
      ts = if @trans_strand.positive?
             'ts:A:+'
           elsif @trans_strand.negative?
             'ts:A:-'
           else
             'ts:A:.'
           end
      a = [@q_st, @q_en, strand, @ctg, @ctg_len, @r_st, @r_en,
           @mlen, @blen, @mapq, tp, ts, "cg:Z:#{@cigar_str}"]
      a << "cs:Z:#{@cs}" if @cs
      a.join("\t")
    end
  end
end
