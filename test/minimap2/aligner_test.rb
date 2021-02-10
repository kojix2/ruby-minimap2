# frozen_string_literal: true

require_relative "../test_helper"
class AlignerTest < Minitest::Test
  def setup
    @a = MM2::Aligner.new("../../minimap2/test/MT-human.fa")
  end

  def test_initialize
    assert_instance_of MM2::Aligner, @a
  end

  def test_k
    assert_equal nil, @a.k
  end
end
