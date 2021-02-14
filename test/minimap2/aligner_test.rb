# frozen_string_literal: true

require_relative "../test_helper"
class AlignerTest < Minitest::Test
  def setup
    path = File.expand_path("../../minimap2/test/MT-human.fa", __dir__)
    @a = MM2::Aligner.new(path)
  end

  def test_initialize
    assert_instance_of MM2::Aligner, @a
  end

  def test_seq
    assert_nil @a.seq("MT_human", 0, 0)
    assert_equal "G", @a.seq("MT_human", 0, 1)
    assert_equal "GA", @a.seq("MT_human", 0, 2)
    assert_equal "CACAG", @a.seq("MT_human", 3, 8)
    assert_equal "ATCACGATG", @a.seq("MT_human", 16_560)
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

  def test_k
    assert_equal 15, @a.k
  end

  def test_w
    assert_equal 10, @a.w
  end

  def test_n_seq
    assert_equal 1, @a.n_seq
  end

  def test_seq_names
    path = File.expand_path("../../minimap2/test/q-inv.fa", __dir__)
    @a = MM2::Aligner.new(path)
    assert_equal %w[read1 read2], @a.seq_names
  end
end
