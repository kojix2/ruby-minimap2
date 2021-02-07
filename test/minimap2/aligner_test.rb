# frozen_string_literal: true

require_relative "../test_helper"
class AlignerTest < Minitest::Test
  def test_initialize
    MM2::Aligner.new("../../minimap2/test/MT-human.fa")
  end
end
