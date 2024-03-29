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
    io = MM2::FFI::IdxOpt.new
    assert_instance_of MM2::FFI::IdxOpt, io
    assert_equal 0, io[:k]
    MM2::FFI.mm_idxopt_init(io)
    assert_equal 15, io[:k]
    assert_equal 10, io[:w]
    assert_equal 0, io[:flag]
    assert_equal 14, io[:bucket_bits]
    assert_equal 50_000_000, io[:mini_batch_size]
    assert_equal 8_000_000_000, io[:batch_size]
  end

  def test_mapopt
    mo = MM2::FFI::MapOpt.new
    assert_instance_of MM2::FFI::MapOpt, mo
    assert_equal 0, mo[:seed]
    MM2::FFI.mm_mapopt_init(mo)
    assert_equal 11, mo[:seed]
    assert_equal 0, mo[:flag]
    assert_equal 0, mo[:sdust_thres]
    assert_equal 0, mo[:max_qlen]
    assert_equal 500, mo[:bw]
    assert_equal 20_000, mo[:bw_long]
    assert_equal 5000, mo[:max_gap]
    assert_equal(-1, mo[:max_gap_ref])
    assert_equal 0, mo[:max_frag_len]
    assert_equal 25, mo[:max_chain_skip]
    assert_equal 5000, mo[:max_chain_iter]
    assert_equal 3, mo[:min_cnt]
    assert_equal 40, mo[:min_chain_score]
    assert_in_epsilon 0.8, mo[:chain_gap_scale]
    assert_in_epsilon 0, mo[:chain_skip_scale]
    assert_equal 100_000, mo[:rmq_size_cap]
    assert_equal 1000, mo[:rmq_inner_dist]
    assert_equal 1000, mo[:rmq_rescue_size]
    assert_in_epsilon 0.1, mo[:rmq_rescue_ratio]
    assert_in_epsilon 0.5, mo[:mask_level]
    # assert_equal INT_MAX, mo[:mask_len]
    assert_in_epsilon 0.8, mo[:pri_ratio]
    assert_equal 5, mo[:best_n]
    assert_in_epsilon 0.15, mo[:alt_drop]
    assert_equal 2, mo[:a]
    assert_equal 4, mo[:b]
    assert_equal 4, mo[:q]
    assert_equal 2, mo[:e]
    assert_equal 24, mo[:q2]
    assert_equal 1, mo[:e2]
    assert_equal 1, mo[:sc_ambi]
    assert_equal 0, mo[:noncan]
    assert_equal 0, mo[:junc_bonus]
    assert_equal 400, mo[:zdrop]
    assert_equal 200, mo[:zdrop_inv]
    assert_equal(-1, mo[:end_bonus])
    assert_equal (mo[:min_chain_score] * mo[:a]), mo[:min_dp_max]
    assert_equal 200, mo[:min_ksw_len]
    assert_equal 20, mo[:anchor_ext_len]
    assert_equal 6, mo[:anchor_ext_shift]
    assert_in_epsilon 1.0, mo[:max_clip_ratio]
    assert_equal 500, mo[:rank_min_len]
    assert_in_epsilon 0.9, mo[:rank_frac]
    assert_equal 0, mo[:pe_ori]
    assert_equal 33, mo[:pe_bonus]
    assert_in_epsilon 0.0002, mo[:mid_occ_frac]
    assert_in_epsilon 0.01, mo[:q_occ_frac]
    assert_equal 10, mo[:min_mid_occ]
    assert_equal 1_000_000, mo[:max_mid_occ]
    assert_equal 0, mo[:mid_occ]
    assert_equal 0, mo[:max_occ]
    assert_equal 4095, mo[:max_max_occ]
    assert_equal 500, mo[:occ_dist]
    assert_equal 500_000_000, mo[:mini_batch_size]
    assert_equal 100_000_000, mo[:max_sw_mat]
    assert_equal 500_000_000, mo[:cap_kalloc]
    assert_nil mo[:split_prefix]
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
    assert_equal 0, obj[:strand_retained]
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
    assert_equal [15, 10, 0, 14, 50_000_000, 8_000_000_000], iopt.values
  end

  def test_mm_set_opt_short
    iopt = MM2::FFI::IdxOpt.new
    mopt = MM2::FFI::MapOpt.new
    MM2::FFI.mm_set_opt("short", iopt, mopt)
    assert_equal [21, 11, 0, 0, 0, 0], iopt.values
    assert MM2::FFI.mm_set_opt(":asm10", iopt, mopt)
  end
end
