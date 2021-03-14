# frozen_string_literal: true

require 'minimap2'

# load or build index
aligner = Minimap2::Aligner.new('minimap2/test/MT-human.fa')

# retrieve a subsequence from the index
seq = aligner.seq('MT_human', 100, 200)

# mapping
aligner.align(seq) do |h|
  pp h.to_h
end
