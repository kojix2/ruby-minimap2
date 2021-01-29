# frozen_string_literal: true

module Minimap2
  class Alignment
    def self.keys
      %i[ctg ctg_len r_st r_en strand trans_strand blen mlen nm primary
         q_st q_en mapq cigar read_num cs md cigar_str]
    end

    # Read only
    attr_reader(*keys)

    def initialize; end

    def destroy; end

    def is_primary?; end

    def to_s; end
  end
end
