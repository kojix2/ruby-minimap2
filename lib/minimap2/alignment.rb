# frozen_string_literal: true

require_relative "ffi"

module Minimap2
  class Alignment
    def self.keys
      %i[ctg ctg_len r_st r_en strand trans_strand blen mlen nm primary
         q_st q_en mapq cigar read_num cs md cigar_str]
    end

    # Read only
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

      @cigar_str = cigar.map { |x| x[0].to_s + "MIDNSH"[x[1]] }.join
    end

    def is_primary?
      @primary
    end

    def to_h
      self.class.keys.map { |k| [k, __send__(k)] }.to_h
    end

    def to_s
      strand = if @strand.positive?
                 "+"
               elsif @strand.negative?
                 "-"
               else
                 "?"
               end
      tp = @primary != 0 ? "tp:A:P" : "tp:A:S"
      ts = if @trans_strand.positive?
             "ts:A:+"
           elsif @trans_strand.negative?
             "ts:A:-"
           else
             "ts:A:."
           end
      a = [@q_st, @q_en, strand, @ctg, @ctg_len, @r_st, @r_en,
           @mlen, @blen, @mapq, tp, ts, "cg:Z:#{@cigar_str}"]
      a << "cs:Z:#{@cs}" if @cs
      a.join("\t")
    end
  end
end
