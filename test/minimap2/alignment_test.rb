# frozen_string_literal: true

require_relative "../test_helper"
class AlignmentTest < Minitest::Test
  def setup
    path = File.expand_path("../../minimap2/test/MT-human.fa", __dir__)
    aligner = MM2::Aligner.new(path)
    seq = aligner.seq("MT_human", 100, 300)
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

  def test_ctg
    assert_equal "MT_human", @a.ctg
  end

  def test_ctg_len
    assert_equal 16_569, @a.ctg_len
  end

  def test_r_st
    assert_equal 100, @a.r_st
  end

  def test_r_en
    assert_equal 300, @a.r_en
  end

  def test_strand
    assert_equal 1, @a.strand
  end

  def test_trans_strand
    assert_equal 0, @a.trans_strand
  end

  def test_blen
    assert_equal 200, @a.blen
  end

  def test_mlen
    assert_equal 200, @a.mlen
  end

  def test_nm
    assert_equal 0, @a.nm
  end

  def test_primary
    assert_equal 1, @a.primary
  end

  def test_q_st
    assert_equal 0, @a.q_st
  end

  def test_q_en
    assert_equal 200, @a.q_en
  end

  def test_mapq
    assert_equal 60, @a.mapq
  end

  def test_cigar
    assert_equal [[200, 0]], @a.cigar
  end

  def test_read_num
    assert_equal 1, @a.read_num
  end

  def test_cs
    assert_equal ":200", @a.cs
  end

  def test_md
    assert_equal "200", @a.md
  end

  def test_cigar
    assert_equal "200M", @a.cigar_str
  end

  def test_primary?
    assert_equal true, @a.primary?
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

  def test_to_s
    assert_equal "0\t200\t+\tMT_human\t16569\t100\t300\t200\t200\t60\ttp:A:P\tts:A:.\tcg:Z:200M\tcs:Z::200", @a.to_s
  end
end
