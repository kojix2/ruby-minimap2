# frozen_string_literal: true

require_relative "../test_helper"
class AlignmentTest < Minitest::Test
  def setup
    path = File.expand_path("../../minimap2/test/MT-human.fa", __dir__)
    @a = MM2::Aligner.new(path)
  end

  def test_align
    seq = @a.seq("MT_human", 100, 300)
    hit = {
      ctg: "MT_human",
      ctg_len: 16_569,
      r_st: 100,
      r_en: 300,
      strand: 1,
      trans_strand: 0,
      blen: 200,
      mlen: 200,
      nm: 0,
      primary: 1,
      q_st: 0,
      q_en: 200,
      mapq: 60,
      cigar: [[200, 0]],
      read_num: 1,
      cs: "",
      md: "",
      cigar_str: "200M"
    }
    @a.align(seq) do |h|
      assert_equal hit, h.to_h
    end
  end
end
