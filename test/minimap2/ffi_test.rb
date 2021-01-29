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
    obj = MM2::FFI::IdxOpt.new
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
    assert_equal true, obj[:h].null?
  end

  def test_mapopt
    obj = MM2::FFI::MapOpt.new
    assert_instance_of MM2::FFI::MapOpt, obj
    assert_equal 0, obj[:flag]
    assert_equal 0, obj[:seed]
    assert_equal 0, obj[:sdust_thres]
    assert_equal 0, obj[:max_qlen]
    assert_equal 0, obj[:bw]
    assert_equal 0, obj[:max_gap]
    assert_equal 0, obj[:max_gap_ref]
    assert_equal 0, obj[:max_frag_len]
    assert_equal 0, obj[:max_chain_skip]
    assert_equal 0, obj[:max_chain_iter]
    assert_equal 0, obj[:min_cnt]
    assert_equal 0, obj[:min_chain_score]
    assert_equal 0, obj[:chain_gap_scale]
    assert_equal 0, obj[:mask_level]
    assert_equal 0, obj[:mask_len]
    assert_equal 0, obj[:pri_ratio]
    assert_equal 0, obj[:best_n]
    assert_equal 0, obj[:max_join_long]
    assert_equal 0, obj[:max_join_short]
    assert_equal 0, obj[:min_join_flank_sc]
    assert_equal 0, obj[:min_join_flank_ratio]
    assert_equal 0, obj[:alt_drop]
    assert_equal 0, obj[:a]
    assert_equal 0, obj[:b]
    assert_equal 0, obj[:q]
    assert_equal 0, obj[:e]
    assert_equal 0, obj[:q2]
    assert_equal 0, obj[:e2]
    assert_equal 0, obj[:sc_ambi]
    assert_equal 0, obj[:noncan]
    assert_equal 0, obj[:junc_bonus]
    assert_equal 0, obj[:zdrop]
    assert_equal 0, obj[:zdrop_inv]
    assert_equal 0, obj[:end_bonus]
    assert_equal 0, obj[:min_dp_max]
    assert_equal 0, obj[:min_ksw_len]
    assert_equal 0, obj[:anchor_ext_len]
    assert_equal 0, obj[:anchor_ext_shift]
    assert_equal 0, obj[:max_clip_ratio]
    assert_equal 0, obj[:pe_ori]
    assert_equal 0, obj[:pe_bonus]
    assert_equal 0, obj[:mid_occ_frac]
    assert_equal 0, obj[:min_mid_occ]
    assert_equal 0, obj[:mid_occ]
    assert_equal 0, obj[:max_occ]
    assert_equal 0, obj[:mini_batch_size]
    assert_equal 0, obj[:max_sw_mat]
    assert_nil obj[:split_prefix]
  end

  def test_idxseq
    obj = MM2::FFI::IdxSeq.new
    assert_instance_of MM2::FFI::IdxSeq, obj
    assert_nil obj[:name]
    assert_equal 0, obj[:offset]
    assert_equal 0, obj[:len]
  end

  def test_idx
    obj = MM2::FFI::Idx.new
    assert_instance_of MM2::FFI::Idx, obj
    assert_equal 0, obj[:b]
    assert_equal 0, obj[:w]
    assert_equal 0, obj[:flag]
    assert_equal 0, obj[:n_seq]
    assert_equal true, obj[:seq].null?
    assert_equal true, obj[:S].null?
    assert_equal true, obj[:B].null?
    assert_equal true, obj[:km].null?
    assert_equal true, obj[:h].null?
  end

  def test_Reader
    obj = MM2::FFI::IdxReader.new
    assert_instance_of MM2::FFI::IdxReader, obj
    assert_equal 0, obj[:is_idx]
    assert_equal 0, obj[:n_parts]
    assert_equal 0, obj[:idx_size]
    assert_instance_of MM2::FFI::IdxOpt, obj[:opt]
    assert_equal true, obj[:fp_out].null?
    assert_equal true, obj[:seq_or_idx].null?
  end

  def test_extra
    obj = MM2::FFI::Extra.new
    assert_instance_of MM2::FFI::Extra, obj
    assert_equal 0, obj[:capacity]
    assert_equal 0, obj[:dp_score]
    assert_equal 0, obj[:dp_max]
    assert_equal 0, obj[:dp_max2]
    assert_equal 0, obj[:n_ambi_trans_strand]
    assert_equal 0, obj[:n_cigar]
  end
end
