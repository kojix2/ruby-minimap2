# frozen_string_literal: true

require_relative "../test_helper"
class AlignerTest < Minitest::Test
  def fa_path
    File.expand_path("../../ext/minimap2/test/MT-human.fa", __dir__)
  end

  def setup
    @a = MM2::Aligner.new(fa_path)
  end

  def abandon_aligner
    MM2::Aligner.new(seq: "ACGT" * 100)
    nil
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

  def test_low_level_ffi_api_is_removed
    refute MM2.const_defined?(:FFI, false)
    refute_respond_to @a, :index
    refute_respond_to @a, :idx_opt
    refute_respond_to @a, :map_opt
  end

  def test_index_is_released_by_finalizer
    GC.start(full_mark: true, immediate_sweep: true)
    baseline = MM2::Native.resource_counts[:indexes]
    abandon_aligner
    assert_equal baseline + 1, MM2::Native.resource_counts[:indexes]

    10.times do
      GC.start(full_mark: true, immediate_sweep: true)
      break if MM2::Native.resource_counts[:indexes] == baseline
    end

    assert_equal baseline, MM2::Native.resource_counts[:indexes]
  end

  def test_free_index_does_not_release_index_twice
    aligner = MM2::Aligner.new(seq: "ACGT" * 100)
    before = MM2::Native.resource_counts[:indexes]
    aligner.free_index
    aligner.free_index

    assert_equal before - 1, MM2::Native.resource_counts[:indexes]
    assert_equal 0, aligner.n_seq
    assert_equal [], aligner.seq_names
    assert_nil aligner.align("ACGT")
    assert_nil aligner.seq("N/A")
    assert_raises(MM2::Error) { aligner.k }
    assert_raises(MM2::Error) { aligner.w }
  end

  def test_align
    qseq = @a.seq("MT_human", 100, 200)
    alignments = @a.align(qseq)
    assert_instance_of Array, alignments
    alignments.each do |h|
      assert_instance_of MM2::Alignment, h
    end
  end

  def test_align_without_index_returns_empty_array
    assert_equal [], MM2::Aligner.new.align("ACGT")
  end

  def test_align_with_ds
    qseq = @a.seq("MT_human", 100, 200)
    alignment = @a.align(qseq, ds: true).first

    refute_nil alignment
    assert_equal ":100", alignment.ds
  end

  def test_align_without_tags_keeps_them_nil
    qseq = @a.seq("MT_human", 100, 200)
    alignment = @a.align(qseq).first

    refute_nil alignment
    assert_nil alignment.cs
    assert_nil alignment.ds
    assert_nil alignment.md
    refute_includes alignment.to_s, "\tds:Z:"
  end

  def test_alignment_records_query_name_and_length
    qseq = @a.seq("MT_human", 100, 200)
    alignment = @a.align(qseq, name: "query1").first

    assert_equal "query1", alignment.qname
    assert_equal 100, alignment.qlen
  end

  def test_align2
    qseq = MM2.revcomp(@a.seq("MT_human", 300, 400))
    alignments = @a.align(qseq)
    assert_instance_of Array, alignments
    alignments.each do |h|
      assert_instance_of MM2::Alignment, h
    end
  end

  def test_align_seq
    qseq = @a.seq("MT_human", 100, 200)
    ref = @a.seq("MT_human", 0, 3000)
    a = MM2::Aligner.new(seq: ref)
    alignments = a.align(qseq)
    assert_instance_of Array, alignments
    alignments.each do |h|
      assert_instance_of MM2::Alignment, h
    end
  end

  def test_align2_seq
    qseq1 = @a.seq("MT_human", 100, 200)
    qseq2 = MM2.revcomp(@a.seq("MT_human", 300, 400))
    ref = @a.seq("MT_human", 0, 3000)
    a = MM2::Aligner.new(seq: ref)
    alignments = a.align(qseq1, qseq2)
    assert_instance_of Array, alignments
    alignments.each do |h|
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

  def test_multi_part_index_from_fasta
    # minimap2 can only split between sequences (contigs). The bundled MT-human.fa
    # is a single contig, so it cannot produce a multi-part index even if
    # batch_size is tiny. Generate a temporary multi-contig FASTA instead.
    require "tmpdir"

    Dir.mktmpdir("ruby-minimap2-") do |dir|
      tmp_fa = File.join(dir, "multi_contig.fa")
      File.open(tmp_fa, "w") do |f|
        12.times do |i|
          f.puts ">ctg#{i + 1}"
          f.puts "A" * 600
        end
      end

      # Force index splitting by using a very small batch_size.
      # This validates that ruby-minimap2 reads all parts from mm_idx_reader_read.
      a = MM2::Aligner.new(tmp_fa, batch_size: 1000, n_threads: 1, best_n: 1)
      assert_operator MM2::Native.resource_counts[:indexes], :>, 2

      qseq = a.seq("ctg1", 0, 100)
      refseq = a.seq("ctg1", 0, 600)
      refute_nil qseq
      refute_nil refseq

      alignments = a.align(qseq)
      assert_instance_of Array, alignments
      assert_operator alignments.length, :<=, 1
    end
  end

  def test_align_does_not_leak_map_opt
    a = MM2::Aligner.new(fa_path, n_threads: 1)
    qseq = a.seq("MT_human", 100, 200)

    expected = a.align(qseq).map(&:to_h)
    a.align(qseq, extra_flags: (1 << 20), max_frag_len: 1234)
    assert_equal expected, a.align(qseq).map(&:to_h)
  end

  def test_invalid_k_and_w_raise_before_native_code
    [0, 29, -1].each do |k|
      assert_raises(ArgumentError) { MM2::Aligner.new(seq: "ACGT", k: k) }
    end
    [0, 256, -1].each do |w|
      assert_raises(ArgumentError) { MM2::Aligner.new(seq: "ACGT", w: w) }
    end
  end

  def test_invalid_k_does_not_abort_subprocess
    require "open3"
    ruby = RbConfig.ruby
    script = <<~RUBY
      require "minimap2"
      begin
        Minimap2::Aligner.new(seq: "ACGT", k: 29)
      rescue ArgumentError
        exit 0
      end
      exit 1
    RUBY
    _out, err, status = Open3.capture3(ruby, "-Ilib", "-e", script)

    assert_predicate status, :success?, err
  end

  def test_empty_or_directory_index_raises
    require "tempfile"
    require "tmpdir"

    Tempfile.create(["empty", ".fa"]) do |file|
      assert_raises(MM2::Error) { MM2::Aligner.new(file.path) }
    end
    Dir.mktmpdir do |dir|
      assert_raises(MM2::Error) { MM2::Aligner.new(dir) }
    end
  end

  def test_paired_alignment_releases_temporary_buffer
    qseq1 = @a.seq("MT_human", 100, 200)
    qseq2 = MM2.revcomp(@a.seq("MT_human", 300, 400))
    20.times { @a.align(qseq1, qseq2) }

    assert_equal 0, MM2::Native.resource_counts[:pair_buffers]
  end

  def test_equal_score_alignments_keep_native_order
    query = @a.seq("MT_human", 16_000, 16_500) * 2
    starts = @a.align(query).map(&:q_st)

    # This is mm_map()'s order for the bundled minimap2 version. Do not reverse
    # ties as the former sort_by! + reverse! implementation did.
    assert_equal [500, 0], starts
  end

  def test_same_aligner_can_be_called_from_multiple_threads
    query = @a.seq("MT_human", 100, 300)
    expected = @a.align(query, cs: true).map(&:to_h)
    results = 4.times.map do
      Thread.new do
        10.times.map { @a.align(query, cs: true).map(&:to_h) }
      end
    end.flat_map(&:value)

    assert(results.all? { |result| result == expected })
  end

  def test_mapping_releases_the_gvl
    query = @a.seq("MT_human", 0, 16_000) * 20
    running = true
    ticks = 0
    ticker = Thread.new do
      ticks += 1 while running
    end

    @a.align(query)
    running = false
    ticker.join

    assert_operator ticks, :>, 0
  end
end
