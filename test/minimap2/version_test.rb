# frozen_string_literal: true

require_relative '../test_helper'
class VersionTest < Minitest::Test
  def test_version
    refute_nil ::Minimap2::VERSION
  end
end
