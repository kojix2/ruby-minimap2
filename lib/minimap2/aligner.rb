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
    # @param min_cnt [Integer] minimum number of minimizers on a chain.
    # @param min_chain_score [Integer] minimum chain score.
    # @param min_dp_score
    # @param bw [Integer] chaining and alignment band width. (initial chaining and extension)
    # @param bw_long [Integer] chaining and alignment band width (RMQ-based rechaining and closing gaps)
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
      bw_long: nil,
      best_n: nil,
      n_threads: 3,
      fn_idx_out: nil,
      max_frag_len: nil,
      extra_flags: nil,
      scoring: nil,
      sc_ambi: nil,
      max_chain_skip: nil,
      batch_size: nil
    )
      @idx_opt = FFI::IdxOpt.new
      @map_opt = FFI::MapOpt.new

      r = FFI.mm_set_opt(preset, idx_opt, map_opt)
      raise ArgumentError, "Unknown preset name: #{preset}" if r == -1

      # always perform alignment
      map_opt[:flag] |= 4

      # Keep a large batch_size by default (mappy-compatible behavior) to avoid
      # splitting indexes unless explicitly requested.
      idx_opt[:batch_size] = 0x7fffffffffffffff
      idx_opt[:batch_size] = batch_size if batch_size

      # override preset options
      idx_opt[:k] = k if k
      idx_opt[:w] = w if w
      map_opt[:min_cnt] = min_cnt if min_cnt
      map_opt[:min_chain_score] = min_chain_score if min_chain_score
      map_opt[:min_dp_max] = min_dp_score if min_dp_score
      map_opt[:bw] = bw if bw
      map_opt[:bw_long] = bw_long if bw_long
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
      map_opt[:sc_ambi] = sc_ambi if sc_ambi
      map_opt[:max_chain_skip] = max_chain_skip if max_chain_skip

      if fn_idx_in
        warn "Since fn_idx_in is specified, the seq argument will be ignored." if seq
        reader = FFI.mm_idx_reader_open(fn_idx_in, idx_opt, fn_idx_out)

        # The Ruby version raises an error here
        raise "Cannot open : #{fn_idx_in}" if reader.null?

        @indexes = []
        begin
          loop do
            idx = FFI.mm_idx_reader_read(reader, n_threads)
            break if idx.nil? || idx.null?

            # Initialize sequence name index for each part
            FFI.mm_idx_index_name(idx)
            @indexes << idx
          end
        ensure
          FFI.mm_idx_reader_close(reader)
        end

        raise "Failed to read index parts from: #{fn_idx_in}" if @indexes.empty?

        # Keep backward-compatible accessor for a single index
        @index = @indexes[0]
        FFI.mm_mapopt_update(map_opt, index)
      elsif seq
        @index = FFI.mappy_idx_seq(
          idx_opt[:w], idx_opt[:k], idx_opt[:flag] & 1,
          idx_opt[:bucket_bits], seq, seq.size
        )
        @indexes = [@index]
        FFI.mm_mapopt_update(map_opt, index)
        map_opt[:mid_occ] = 1000 # don't filter high-occ seeds
      else
        @indexes = []
        @index = FFI::Idx.new(::FFI::Pointer::NULL)
      end
    end

    # Explicitly releases the memory of the index object.

    def free_index
      indexes = @indexes
      if indexes && !indexes.empty?
        indexes.each do |idx|
          FFI.mm_idx_destroy(idx) unless idx.nil? || idx.null?
        end
      elsif defined?(@index) && !@index.nil? && !@index.null?
        FFI.mm_idx_destroy(@index)
      end
    ensure
      @indexes = []
      @index = FFI::Idx.new(::FFI::Pointer::NULL)
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
      name: nil,
      buf: nil,
      cs: false,
      md: false,
      max_frag_len: nil,
      extra_flags: nil
    )
      return if index.null?
      return if (map_opt[:flag] & 4).zero? && (index[:flag] & 2).zero?

      orig_map_opt_bytes = map_opt.to_ptr.read_bytes(FFI::MapOpt.size)
      orig_best_n = map_opt[:best_n]

      owned_buf = false
      if buf.nil?
        buf = FFI.mm_tbuf_init
        owned_buf = true
      end

      km = FFI.mm_tbuf_get_km(buf)
      alignments = []

      idx_parts = @indexes
      idx_parts = [index] if idx_parts.nil? || idx_parts.empty?

      begin
        idx_parts.each do |idx_part|
          next if idx_part.nil? || idx_part.null?

          # Update options for this specific index part
          FFI.mm_mapopt_update(map_opt, idx_part)

          # Per-call options (do not leak across calls)
          map_opt[:flag] |= 4
          map_opt[:best_n] = orig_best_n
          map_opt[:max_frag_len] = max_frag_len if max_frag_len
          map_opt[:flag] |= extra_flags if extra_flags

          n_regs_ptr = ::FFI::MemoryPointer.new :int
          regs_ptr = FFI.mm_map_aux(idx_part, name, seq, seq2, n_regs_ptr, buf, map_opt)
          n_regs = n_regs_ptr.read_int

          next if regs_ptr.nil? || regs_ptr.null? || n_regs <= 0

          regs = Array.new(n_regs) do |i|
            FFI::Reg1.new(regs_ptr + i * FFI::Reg1.size)
          end

          hit = FFI::Hit.new

          cs_buf_ptr = nil
          m_cs_ptr = nil
          if cs || md
            cs_buf_ptr = ::FFI::MemoryPointer.new(:pointer)
            cs_buf_ptr.write_pointer(::FFI::Pointer::NULL)
            m_cs_ptr = ::FFI::MemoryPointer.new(:int)
            m_cs_ptr.write_int(0)
          end

          i = 0
          begin
            while i < n_regs
              FFI.mm_reg2hitpy(idx_part, regs[i], hit)

              c = hit[:cigar32].read_array_of_uint32(hit[:n_cigar32])
              cigar = c.map { |x| [x >> 4, x & 0xf] } # 32-bit CIGAR encoding -> Ruby array

              _cs = ""
              _md = ""
              if cs or md
                cur_seq = hit[:seg_id] > 0 && seq2 ? seq2 : seq

                if cs
                  l_cs_str = FFI.mm_gen_cs(km, cs_buf_ptr, m_cs_ptr, idx_part, regs[i], cur_seq, 1)
                  cs_ptr = cs_buf_ptr.read_pointer
                  _cs = cs_ptr.null? || l_cs_str <= 0 ? "" : cs_ptr.read_string(l_cs_str)
                end

                if md
                  l_cs_str = FFI.mm_gen_md(km, cs_buf_ptr, m_cs_ptr, idx_part, regs[i], cur_seq)
                  cs_ptr = cs_buf_ptr.read_pointer
                  _md = cs_ptr.null? || l_cs_str <= 0 ? "" : cs_ptr.read_string(l_cs_str)
                end
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

            if cs_buf_ptr
              cs_ptr = cs_buf_ptr.read_pointer
              FFI.mappy_free(cs_ptr) unless cs_ptr.nil? || cs_ptr.null?
            end

            # Free the mm_map/mm_map_aux return value array itself
            FFI.mappy_free(regs_ptr) unless regs_ptr.nil? || regs_ptr.null?
          end
        end
      ensure
        FFI.mm_tbuf_destroy(buf) if owned_buf

        # Restore map_opt to the state before this call
        map_opt.to_ptr.put_bytes(0, orig_map_opt_bytes)
      end

      if orig_best_n && orig_best_n > 0 && alignments.length > orig_best_n
        alignments.sort_by! do |aln|
          [
            aln.primary? ? 1 : 0,
            aln.mapq,
            aln.mlen,
            aln.blen,
            -aln.nm
          ]
        end
        alignments.reverse!
        alignments = alignments.take(orig_best_n)
      end

      alignments
    end

    # Retrieve a subsequence from the index.
    # @param name
    # @param start
    # @param stop

    def seq(name, start = 0, stop = 0x7fffffff)
      return if index.null?
      return if (map_opt[:flag] & 4).zero? && (index[:flag] & 2).zero?

      idx_parts = @indexes
      idx_parts = [index] if idx_parts.nil? || idx_parts.empty?

      idx_parts.each do |idx_part|
        next if idx_part.nil? || idx_part.null?

        lp = ::FFI::MemoryPointer.new(:int)
        s = FFI.mappy_fetch_seq(idx_part, name, start, stop, lp)
        l = lp.read_int
        if l == 0
          FFI.mappy_free(s) unless s.nil? || s.null?
          next
        end

        begin
          return s.read_string(l)
        ensure
          FFI.mappy_free(s) unless s.nil? || s.null?
        end
      end

      nil
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
      return 0 if index.null?

      indexes = @indexes
      return index[:n_seq] if indexes.nil? || indexes.empty?

      indexes.sum { |idx| idx.nil? || idx.null? ? 0 : idx[:n_seq] }
    end

    def seq_names
      return [] if index.null?

      indexes = @indexes
      indexes = [index] if indexes.nil? || indexes.empty?

      names = []
      seen = {}
      indexes.each do |idx|
        next if idx.nil? || idx.null?

        ptr = idx[:seq].to_ptr
        idx[:n_seq].times do |i|
          name = FFI::IdxSeq.new(ptr + i * FFI::IdxSeq.size)[:name]
          next if seen[name]

          seen[name] = true
          names << name
        end
      end
      names
    end
  end
end
