# frozen_string_literal: true

require "test_helper"

MM2 = Minimap2

class Minimap2Test < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Minimap2::VERSION
  end

  # mappy

  def test_fastx_read
    n = %w[read1 read2]
    MM2.fastx_read("minimap2/test/q-inv.fa") do |i, _j|
      assert_equal i, n.shift
    end
  end

  def test_revcomp
    assert_equal "TCCCAAAGGGTTT", MM2.revcomp("AAACCCTTTGGGA")
  end

  def test_verbose
    assert_equal 1, MM2.verbose
  end
end
