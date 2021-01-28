# frozen_string_literal: true

require "test_helper"

MM2 = Minimap2

class Minimap2Test < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Minimap2::VERSION
  end
end
