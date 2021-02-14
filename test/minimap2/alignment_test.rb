# frozen_string_literal: true

require_relative "../test_helper"
class AlignmentTest < Minitest::Test
  def setup
    path = File.expand_path("../../minimap2/test/MT-human.fa", __dir__)
    aligner = MM2::Aligner.new(path)
    seq = aligner.seq("MT_human", 100, 300)
    # FIXME
    @a = nil
    aligner.align(seq, cs: true, md: true) do |h|
      @a = h
    end
  end

  def test_keys
    assert_instance_of Array, MM2::Alignment.keys
  end

  def test_initialize
    assert_instance_of MM2::Alignment, @a
  end

  def test_to_h
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
      cs: ":200",
      md: "200",
      cigar_str: "200M"
    }
    assert_equal hit, @a.to_h
  end
end
