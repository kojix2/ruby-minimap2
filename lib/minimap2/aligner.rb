# frozen_string_literal: true

module Minimap2
  class Aligner
    attr_reader :idx_opt, :map_opt, :index

    # Create a new aligner.
    #
    # @param fn_idx_in [String] index or sequence file name.
    # @param seq [String] a single sequence to index.
    # @param preset [String] minimap2 preset.
    #   * map-pb : PacBio CLR genomic reads
    #   * map-ont : Oxford Nanopore genomic reads
    #   * map-hifi : PacBio HiFi/CCS genomic reads (v2.19 or later)
    #   * asm20 : PacBio HiFi/CCS genomic reads (v2.18 or earlier)
    #   * sr : short genomic paired-end reads
    #   * splice : spliced long reads (strand unknown)
    #   * splice:hq : Final PacBio Iso-seq or traditional cDNA
    #   * asm5 : intra-species asm-to-asm alignment
    #   * ava-pb : PacBio read overlap
    #   * ava-ont : Nanopore read overlap
    # @param k [Integer] k-mer length, no larger than 28.
    # @param w [Integer] minimizer window size, no larger than 255.
    # @param min_cnt [Integer] mininum number of minimizers on a chain.
    # @param min_chain_score [Integer] minimum chaing score.
    # @param min_dp_score
    # @param bw [Integer] chaining and alignment band width.
    # @param best_n [Integer] max number of alignments to return.
    # @param n_threads [Integer] number of indexing threads.
    # @param fn_idx_out [String] name of file to which the index is written.
    #   This parameter has no effect if seq is set.
    # @param max_frag_len [Integer]
    # @param extra_flags [Integer] additional flags defined in minimap.h.
    # @param scoring [Array] scoring system.
    #   It is a tuple/list consisting of 4, 6 or 7 positive integers.
    #   The first 4 elements specify match scoring, mismatch penalty, gap open and gap extension penalty.
    #   The 5th and 6th elements, if present, set long-gap open and long-gap extension penalty.
    #   The 7th sets a mismatch penalty involving ambiguous bases.

    def initialize(
      fn_idx_in = nil,
      seq: nil,
      preset: nil,
      k: nil,
      w: nil,
      min_cnt: nil,
      min_chain_score: nil,
      min_dp_score: nil,
      bw: nil,
      best_n: nil,
      n_threads: 3,
      fn_idx_out: nil,
      max_frag_len: nil,
      extra_flags: nil,
      scoring: nil
    )

      @idx_opt = FFI::IdxOpt.new
      @map_opt = FFI::MapOpt.new

      r = FFI.mm_set_opt(preset, idx_opt, map_opt)
      raise ArgumentError, "Unknown preset name: #{preset}" if r == -1

      # always perform alignment
      map_opt[:flag] |= 4
      idx_opt[:batch_size] = 0x7fffffffffffffff

      # override preset options
      idx_opt[:k] = k if k
      idx_opt[:w] = w if w
      map_opt[:min_cnt] = min_cnt if min_cnt
      map_opt[:min_chain_score] = min_chain_score if min_chain_score
      map_opt[:min_dp_max] = min_dp_score if min_dp_score
      map_opt[:bw] = bw if bw
      map_opt[:best_n] = best_n if best_n
      map_opt[:max_frag_len] = max_frag_len if max_frag_len
      map_opt[:flag] |= extra_flags if extra_flags
      if scoring && scoring.size >= 4
        map_opt[:a] = scoring[0]
        map_opt[:b] = scoring[1]
        map_opt[:q] = scoring[2]
        map_opt[:e] = scoring[3]
        map_opt[:q2] = map_opt[:q]
        map_opt[:e2] = map_opt[:e]
        if scoring.size >= 6
          map_opt[:q2] = scoring[4]
          map_opt[:e2] = scoring[5]
          map_opt[:sc_ambi] = scoring[6] if scoring.size >= 7
        end
      end

      if fn_idx_in
        warn "Since fn_idx_in is specified, the seq argument will be ignored." if seq
        reader = FFI.mm_idx_reader_open(fn_idx_in, idx_opt, fn_idx_out)

        # The Ruby version raises an error here
        raise "Cannot open : #{fn_idx_in}" if reader.null?

        @index = FFI.mm_idx_reader_read(reader, n_threads)
        FFI.mm_idx_reader_close(reader)
        FFI.mm_mapopt_update(map_opt, index)
        FFI.mm_idx_index_name(index)
      elsif seq
        @index = FFI.mappy_idx_seq(
          idx_opt[:w], idx_opt[:k], idx_opt[:flag] & 1,
          idx_opt[:bucket_bits], seq, seq.size
        )
        FFI.mm_mapopt_update(map_opt, index)
        map_opt[:mid_occ] = 1000 # don't filter high-occ seeds
      end
    end

    # Explicitly releases the memory of the index object.

    def free_index
      FFI.mm_idx_destroy(index) unless index.null?
    end

    # @param seq [String]
    # @param seq2 [String]
    # @param buf [FFI::TBuf]
    # @param cs [true, false]
    # @param md [true, false]
    # @param max_frag_len [Integer]
    # @param extra_flags [Integer]
    # @note Name change: map -> align
    #   In the Ruby language, the name map means iterator.
    #   The original name is map, but here I use the method name align.
    # @note The use of Enumerator is being considered. The method names may change again.
    # @return [Array] alignments

    def align(
      seq, seq2 = nil,
      buf: nil,
      cs: false,
      md: false,
      max_frag_len: nil,
      extra_flags: nil
    )

      return if index.null?

      map_opt[:max_frag_len] = max_frag_len if max_frag_len
      map_opt[:flag] |= extra_flags if extra_flags

      buf ||= FFI::TBuf.new
      km = FFI.mm_tbuf_get_km(buf)

      n_regs_ptr = ::FFI::MemoryPointer.new :int
      regs_ptr = FFI.mm_map_aux(index, seq, seq2, n_regs_ptr, buf, map_opt)
      n_regs = n_regs_ptr.read_int

      regs = Array.new(n_regs) do |i|
        FFI::Reg1.new(regs_ptr + i * FFI::Reg1.size)
      end

      hit = FFI::Hit.new

      cs_str     = ::FFI::MemoryPointer.new(::FFI::MemoryPointer.new(:string))
      m_cs_str   = ::FFI::MemoryPointer.new :int

      alignments = []

      i = 0
      begin
        while i < n_regs
          FFI.mm_reg2hitpy(index, regs[i], hit)

          c = hit[:cigar32].read_array_of_uint32(hit[:n_cigar32])
          cigar = c.map { |x| [x >> 4, x & 0xf] } # 32-bit CIGAR encoding -> Ruby array

          _cs = ""
          if cs
            l_cs_str = FFI.mm_gen_cs(km, cs_str, m_cs_str, @index, regs[i], seq, 1)
            _cs = cs_str.read_pointer.read_string(l_cs_str)
          end

          _md = ""
          if md
            l_cs_str = FFI.mm_gen_md(km, cs_str, m_cs_str, @index, regs[i], seq)
            _md = cs_str.read_pointer.read_string(l_cs_str)
          end

          alignments << Alignment.new(hit, cigar, _cs, _md)

          FFI.mm_free_reg1(regs[i])
          i += 1
        end
      ensure
        while i < n_regs
          FFI.mm_free_reg1(regs[i])
          i += 1
        end
      end
      alignments
    end

    # Retrieve a subsequence from the index.
    # @param name
    # @param start
    # @param stop

    def seq(name, start = 0, stop = 0x7fffffff)
      lp = ::FFI::MemoryPointer.new(:int)
      s = FFI.mappy_fetch_seq(index, name, start, stop, lp)
      l = lp.read_int
      return nil if l == 0

      s.read_string(l)
    end

    # k-mer length, no larger than 28

    def k
      index[:k]
    end

    # minimizer window size, no larger than 255

    def w
      index[:w]
    end

    def n_seq
      index[:n_seq]
    end

    def seq_names
      ptr = index[:seq].to_ptr
      Array.new(index[:n_seq]) do |i|
        FFI::IdxSeq.new(ptr + i * FFI::IdxSeq.size)[:name]
      end
    end
  end
end
