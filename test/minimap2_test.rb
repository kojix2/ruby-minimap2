# frozen_string_literal: true

require "test_helper"

class Minimap2Test < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Minimap2::VERSION
  end

  # unique features of ruby bindings

  def test_execute_with_string_arg
    assert_equal 0, MM2.execute("--version")
    assert_equal 1, MM2.execute("--lh 3")
    # After executing the "--version" command, the verbosity is changed to 3.
    # To prevent test_get_verbose from failing, set it back to 1.
    MM2.verbose = 1
  end

  def test_if_minimap2_version_numbers_match
    begin
      out, err = capture_subprocess_io do
        pid = fork do
          MM2.execute("--version")
        end
        Process.waitpid(pid)
      end
    rescue NotImplementedError
      # Windows does not support fork.
      skip "Fork not supported on this platform"
    end
    assert_match(/^[\d.\-r]+\n/, out)
    # The version number of the gem should match the version number of the
    # Minimap2 shared library. Prevent version mismatch before release.
    assert_includes Minimap2::VERSION, out.split("-r")[0]
    assert_equal "", err
  end

  # mappy

  def test_fastx_read
    n1, s1, n2, s2 = File.readlines("ext/minimap2/test/q-inv.fa").map(&:chomp)
    names = [n1, n2].map { |n| n.sub(">", "") }
    seqs = [s1, s2]
    MM2.fastx_read("ext/minimap2/test/q-inv.fa") do |n, s|
      assert_equal names.shift, n
      assert_equal seqs.shift, s
    end
    # comment should be nil if there is no comment.
    MM2.fastx_read("ext/minimap2/test/q-inv.fa", comment: true) do |_n, _s, c|
      assert_nil c
    end
  end

  def test_fastx_read_comment
    require "tempfile"
    require "zlib"
    Tempfile.create("comment.fq.gz") do |fq|
      Zlib::GzipWriter.open(fq.path) do |gz|
        gz.write <<~FASTQ
          >chat katze
          CATCATCATCAT
          +
          GATOGATOGATO
        FASTQ
      end
      MM2.fastx_read(fq.path, comment: true) do |n, s, q, c|
        assert_equal "chat", n
        assert_equal "CATCATCATCAT", s
        assert_equal "GATOGATOGATO", q
        assert_equal "katze", c
      end
    end
  end

  def test_fastx_read_comment_enumerator
    require "tempfile"
    require "zlib"
    Tempfile.create("comment.fq.gz") do |fq|
      Zlib::GzipWriter.open(fq.path) do |gz|
        gz.write <<~FASTQ
          >chat katze
          CATCATCATCAT
          +
          GATOGATOGATO
        FASTQ
      end
      enum = MM2.fastx_read(fq.path, comment: true)
      arr = enum.to_a
      n, s, q, c = arr[0]
      assert_equal 1, arr.size
      assert_equal "chat", n
      assert_equal "CATCATCATCAT", s
      assert_equal "GATOGATOGATO", q
      assert_equal "katze", c
    end
  end

  def test_revcomp
    assert_equal "TCCCAAAGGGTTT", MM2.revcomp("AAACCCTTTGGGA")
  end

  def test_get_verbose
    assert_equal 1, MM2.verbose
  end

  def test_set_verbose
    assert_equal 3, MM2.verbose = 3
    assert_equal 3, MM2.verbose
    assert_equal 1, MM2.verbose = 1
  end
end
