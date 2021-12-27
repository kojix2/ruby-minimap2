# frozen_string_literal: true

require_relative "../test_helper"
class AlignerTest < Minitest::Test
  def fa_path
    File.expand_path("../../ext/minimap2/test/MT-human.fa", __dir__)
  end

  def setup
    @a = MM2::Aligner.new(fa_path)
  end

  def test_initialize
    assert_instance_of MM2::Aligner, @a
  end

  def test_initialize_preset_short
    assert_instance_of MM2::Aligner, MM2::Aligner.new(fa_path, preset: "short")
    assert_instance_of MM2::Aligner, MM2::Aligner.new(fa_path, preset: :short)
  end

  def test_initialize_preset_unknown
    assert_raises(ArgumentError) { MM2::Aligner.new(fa_path, preset: "sort") }
  end

  def test_initialize_with_seq
    assert_instance_of MM2::Aligner, MM2::Aligner.new(seq: "CACAGGTCGAAGGAGTAATTACCCAACAATGGGTCTCTAG")
  end

  def test_idx_opt
    assert_instance_of MM2::FFI::IdxOpt, @a.idx_opt
  end

  def test_map_opt
    assert_instance_of MM2::FFI::MapOpt, @a.map_opt
  end

  def test_index
    assert_instance_of MM2::FFI::Idx, @a.index
  end

  def test_align
    qseq = @a.seq("MT_human", 100, 200)
    @a.align(qseq) do |h|
      assert_instance_of MM2::Alignment, h
    end
  end

  def test_align2
    qseq = MM2.revcomp(@a.seq("MT_human", 300, 400))
    @a.align(qseq) do |h|
      assert_instance_of MM2::Alignment, h
    end
  end

  def test_align_seq
    qseq = @a.seq("MT_human", 100, 200)
    ref = @a.seq("MT_human", 0, 3000)
    a = MM2::Aligner.new(seq: ref)
    a.align(qseq) do |h|
      assert_instance_of MM2::Alignment, h
    end
  end

  def test_align2_seq
    qseq1 = @a.seq("MT_human", 100, 200)
    qseq2 = MM2.revcomp(@a.seq("MT_human", 300, 400))
    ref = @a.seq("MT_human", 0, 3000)
    a = MM2::Aligner.new(seq: ref)
    a.align(qseq1, qseq2) do |h|
      assert_instance_of MM2::Alignment, h
    end
  end

  def test_seq
    assert_nil @a.seq("MT_human", 0, 0)
    assert_equal "G", @a.seq("MT_human", 0, 1)
    assert_equal "GA", @a.seq("MT_human", 0, 2)
    assert_equal "CACAG", @a.seq("MT_human", 3, 8)
    assert_equal "ATCACGATG", @a.seq("MT_human", 16_560)
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
    path = File.expand_path("../../ext/minimap2/test/q-inv.fa", __dir__)
    @a = MM2::Aligner.new(path)
    assert_equal %w[read1 read2], @a.seq_names
  end
end
