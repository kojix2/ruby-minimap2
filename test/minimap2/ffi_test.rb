# frozen_string_literal: true

require_relative "../test_helper"

class FFITest < Minitest::Test
  def test_mm128
    obj = MM2::FFI::MM128.new
    assert_instance_of MM2::FFI::MM128, obj
    assert_equal 0, obj[:x]
    assert_equal 0, obj[:y]
  end

  def test_mm128v
    obj = MM2::FFI::MM128V.new
    assert_instance_of MM2::FFI::MM128V, obj
    assert_equal 0, obj[:n]
    assert_equal 0, obj[:m]
    assert_instance_of MM2::FFI::MM128, obj[:a]
  end

  def test_idxopt
    obj = MM2::FFI::Idxopt.new
    assert_equal 0, obj[:k]
    assert_equal 0, obj[:w]
    assert_equal 0, obj[:flag]
    assert_equal 0, obj[:bucket_bits]
    assert_equal 0, obj[:mini_batch_size]
    assert_equal 0, obj[:batch_size]
  end

  def test_idx_bucket
    obj = MM2::FFI::IdxBucket.new
    assert_instance_of MM2::FFI::IdxBucket, obj
    assert_instance_of MM2::FFI::MM128, obj[:a]
    assert_equal 0, obj[:n]
    assert_equal true, obj[:p].null?
    assert_equal ture, obj[:h].null?
  end

  def test_mapopt; end
end
