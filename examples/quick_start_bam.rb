# frozen_string_literal: true

require "minimap2"
require "htslib"

# load or build index
aligner = Minimap2::Aligner.new("#{__dir__}/../ext/minimap2/test/MT-human.fa")

# retrieve a subsequence from the index
seq = aligner.seq("MT_human", 100, 200)

# mapping
hits = aligner.align(seq)
hit = hits[0]

# save result to BAM file
HTS::Bam.open("test.bam", "wb") do |bam|
  header = HTS::Bam::Header.new do |h|
    h << %w[SQ SN MT_human LN 16569]
    h << "@PG\tID:ruby-minimap2\tPN:ruby-minimap2\tVN:#{Minimap2::VERSION}"
  end
  bam.header = header
  record = HTS::Bam::Record.new(
    header,
    qname: "Read1",
    flag: 0,
    tid: 0,
    pos: hit.r_st,
    mapq: hit.mapq,
    cigar: hit.cigar_str,
    mtid: 0,
    mpos: 0,
    isize: 0,
    seq: seq,
    qual: [20] * 100,
    l_aux: 0
  )
  bam << record
end
