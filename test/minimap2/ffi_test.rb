# frozen_string_literal: true

require_relative '../test_helper'

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
    assert_instance_of MM2::FFI::IdxOpt, obj
    assert_equal 0, obj[:k]
    assert_equal 0, obj[:w]
    assert_equal 0, obj[:flag]
    assert_equal 0, obj[:bucket_bits]
    assert_equal 0, obj[:mini_batch_size]
    assert_equal 0, obj[:batch_size]
  end

  def test_mapopt
    obj = MM2::FFI::MapOpt.new
    assert_instance_of MM2::FFI::MapOpt, obj
    assert_equal 0, obj[:flag]
    assert_equal 0, obj[:seed]
    assert_equal 0, obj[:sdust_thres]
    assert_equal 0, obj[:max_qlen]
    assert_equal 0, obj[:bw]
    assert_equal 0, obj[:bw_long]
    assert_equal 0, obj[:max_gap]
    assert_equal 0, obj[:max_gap_ref]
    assert_equal 0, obj[:max_frag_len]
    assert_equal 0, obj[:max_chain_skip]
    assert_equal 0, obj[:max_chain_iter]
    assert_equal 0, obj[:min_cnt]
    assert_equal 0, obj[:min_chain_score]
    assert_equal 0, obj[:chain_gap_scale]
    assert_equal 0, obj[:rmq_size_cap]
    assert_equal 0, obj[:rmq_inner_dist]
    assert_equal 0, obj[:rmq_rescue_size]
    assert_equal 0, obj[:rmq_rescue_ratio]
    assert_equal 0, obj[:mask_level]
    assert_equal 0, obj[:mask_len]
    assert_equal 0, obj[:pri_ratio]
    assert_equal 0, obj[:best_n]
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
    assert_equal 0, obj[:rank_min_len]
    assert_equal 0, obj[:rank_frac]
    assert_equal 0, obj[:pe_ori]
    assert_equal 0, obj[:pe_bonus]
    assert_equal 0, obj[:mid_occ_frac]
    assert_equal 0, obj[:q_occ_frac]
    assert_equal 0, obj[:min_mid_occ]
    assert_equal 0, obj[:mid_occ]
    assert_equal 0, obj[:max_occ]
    assert_equal 0, obj[:mini_batch_size]
    assert_equal 0, obj[:max_sw_mat]
    assert_equal 0, obj[:cap_kalloc]
    assert_nil obj[:split_prefix]
  end

  def test_idxseq
    obj = MM2::FFI::IdxSeq.new
    assert_instance_of MM2::FFI::IdxSeq, obj
    assert_nil obj[:name]
    assert_equal 0, obj[:offset]
    assert_equal 0, obj[:len]
    assert_equal 0, obj[:is_alt]
  end

  def test_idx
    obj = MM2::FFI::Idx.new
    assert_instance_of MM2::FFI::Idx, obj
    assert_equal 0, obj[:b]
    assert_equal 0, obj[:w]
    assert_equal 0, obj[:flag]
    assert_equal 0, obj[:n_seq]
    assert_equal 0, obj[:index]
    assert_equal 0, obj[:n_alt]
    assert_equal true, obj[:seq].null?
    assert_equal true, obj[:S].null?
    assert_equal true, obj[:B].null?
    assert_equal true, obj[:I].null?
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
    cigar = [4, 5, 6]
    obj = MM2::FFI::Extra.new(::FFI::MemoryPointer.new(MM2::FFI::Extra.size + ::FFI.type_size(:uint32) * cigar.size))
    assert_instance_of MM2::FFI::Extra, obj
    assert_equal 0, obj[:capacity]
    assert_equal 0, obj[:dp_score]
    assert_equal 0, obj[:dp_max]
    assert_equal 0, obj[:dp_max2]
    # assert_equal 0, obj[:n_ambi_trans_strand]
    assert_equal 0, obj[:n_ambi]
    assert_equal 0, obj[:trans_strand]
    cigar = [4, 5, 6]
    obj[:n_cigar] = cigar.size
    obj.pointer.put_array_of_uint32(obj.size, cigar)
    assert_equal cigar, obj.cigar
  end

  def test_reg1
    obj = MM2::FFI::Reg1.new
    assert_instance_of MM2::FFI::Reg1, obj
    assert_equal 0, obj[:id]
    assert_equal 0, obj[:cnt]
    assert_equal 0, obj[:rid]
    assert_equal 0, obj[:score]
    assert_equal 0, obj[:qs]
    assert_equal 0, obj[:qe]
    assert_equal 0, obj[:rs]
    assert_equal 0, obj[:re]
    assert_equal 0, obj[:parent]
    assert_equal 0, obj[:subsc]
    assert_equal 0, obj[:as]
    assert_equal 0, obj[:mlen]
    assert_equal 0, obj[:blen]
    assert_equal 0, obj[:n_sub]
    assert_equal 0, obj[:score0]
    # assert_equal 0, obj[:fields]
    assert_equal 0, obj[:hash]
    assert_equal 0, obj[:div]
    assert_equal true, obj[:p].null?

    assert_equal 0, obj[:mapq]
    assert_equal 0, obj[:split]
    assert_equal 0, obj[:rev]
    assert_equal 0, obj[:inv]
    assert_equal 0, obj[:sam_pri]
    assert_equal 0, obj[:proper_frag]
    assert_equal 0, obj[:pe_thru]
    assert_equal 0, obj[:seg_split]
    assert_equal 0, obj[:seg_id]
    assert_equal 0, obj[:split_inv]
    assert_equal 0, obj[:is_alt]
    assert_equal 0, obj[:dummy]
  end

  def test_tbuf
    obj = MM2::FFI::TBuf.new
    assert_instance_of MM2::FFI::TBuf, obj
    assert_equal true, obj[:km].null?
    assert_equal 0, obj[:rep_len]
    assert_equal 0, obj[:frag_gap]
  end

  def test_mm_set_opt_0
    iopt = MM2::FFI::IdxOpt.new
    mopt = MM2::FFI::MapOpt.new
    MM2::FFI.mm_set_opt(nil, iopt, mopt)
    assert_equal [15, 10, 0, 14, 50_000_000, 4_000_000_000], iopt.values
  end

  def test_mm_set_opt_short
    iopt = MM2::FFI::IdxOpt.new
    mopt = MM2::FFI::MapOpt.new
    MM2::FFI.mm_set_opt('short', iopt, mopt)
    assert_equal [21, 11, 0, 0, 0, 0], iopt.values
    assert MM2::FFI.mm_set_opt(':asm10', iopt, mopt)
  end
end
