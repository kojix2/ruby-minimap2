# frozen_string_literal: true

module Minimap2
  class Aligner
    def initialize(
      fn_idx_in, # FIXME
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
      seq: nil,
      scoring: nil
    )

      @idx_opt = FFI::IdxOpt.new
      @map_opt = FFI::MapOpt.new

      if preset
        FFI.mm_set_opt(preset, @idx_opt, @map_opt)
      else
        # set the default options
        # FIXME: minimap2 patch
        FFI.mm_set_opt("default", @idx_opt, @map_opt)
      end

      # always perform alignment
      @map_opt[:flag] |= 4
      @idx_opt[:batch_size] = 0x7fffffffffffffff
      @idx_opt[:k] = k if k
      @idx_opt[:w] = w if w
      @map_opt[:min_cnt] = min_cnt if min_cnt
      @map_opt[:min_chain_score] = min_chain_score if min_chain_score
      @map_opt[:min_dp_max] = min_dp_score if min_dp_score
      @map_opt[:bw] = bw if bw
      @map_opt[:best_n] = best_n if best_n
      @map_opt[:max_frag_len] = max_frag_len if max_frag_len
      @map_opt[:flag] |= extra_flags if extra_flags
      if scoring && scoring.size >= 4
        @map_opt[:a] = scoring[0]
        @map_opt[:b] = scoring[1]
        @map_opt[:q] = scoring[2]
        @map_opt[:e] = scoring[3]
        @map_opt[:q2] = @map_opt.q
        @map_opt[:e2] = @map_opt.e
        if scoring.size >= 6
          @map_opt[:q2] = scoring[4]
          @map_opt[:e2] = scoring[5]
          @map_opt[:sc_ambi] = scoring[6] if scoring.size >= 7
        end
      end

      if seq
        @idx = FFI.mappy_idx_seq(
          @idx_opt.w, @idx_opt.k, @idx_opt & 1, @idx_opt.bucket_bits, seq, seq.size
        )
        FFI.mm_mapopt_update(@map_opt, @idx)
        @map_opt.mid_occ = 1000 # don't filter high-occ seeds
      else
        @r = FFI.mm_idx_reader_open(fn_idx_in, @idx_opt, fn_idx_out)
        raise "Cannot open : #{fn_idx_in}" if @r.null?

        @idx = FFI.mm_idx_reader_read(@r, n_threads)
        FFI.mm_idx_reader_close(@r)
        FFI.mm_mapopt_update(@map_opt, @idx)
        FFI.mm_idx_index_name(@idx)
      end
    end

    # FIXME: naming
    def destroy
      FFI.mm_idx_destroy(@idx) unless @idx.null?
    end

    # NOTE: Name change: map -> align
    # In the Ruby language, the name map means iterator.
    # The original name is map, but here I use the method name align.
    def align(
      seq, seq2 = nil,
      buf: nil,
      cs: false,
      md: false,
      max_frag_len: nil,
      extra_flags: nil
    )

      return if @idx.null?

      h = FFI::Hit.new
      n_regs_ptr = ::FFI::MemoryPointer.new(:int)
      cs_str = ::FFI::MemoryPointer.new(:string)
      l_cs_str = ::FFI::MemoryPointer.new(:int)
      m_cs_str = ::FFI::MemoryPointer.new(:int)
      km = ::FFI::MemoryPointer.new(:void)

      map_opt = @map_opt # FIXME: should clone?
      map_opt.max_frag_len = max_frag_len if max_frag_len
      map_opt.flag |= extra_flags if extra_flags

      b = (buf || FFI::TBuf.new)
      km = FFI.mm_tbuf_get_km(b)

      ptr = if seq2
              FFI.mm_map_aux(@idx, seq, seq2, n_regs_ptr, b, map_opt)
            else
              FFI.mm_map_aux(@idx, seq, nil, n_regs_ptr, b, map_opt)
            end
      n_regs = n_regs_ptr.read_int
      regs = Array.new(n_regs) { |i| FFI::Reg1.new(ptr + i * FFI::Reg1.size) }

      begin
        i = 0
        while i < n_regs
          FFI.mm_reg2hitpy(@idx, regs[i], h)
          cigar = []
          _cs = ""
          _MD = ""

          c = h[:cigar32].read_array_of_uint32(h[:n_cigar32])
          cigar = c.map { |i| [i >> 4, i & 0xf] }

          raise NotImplementedError if cs # FIXME
          raise NotImplementedError if md # FIXME

          yield Alignment.new(h, cigar, cs, md)

          FFI.mm_free_reg1(regs[i])
          i += 1
        end
      ensure
        while i < n_regs
          FFI.mm_free_reg1(regs[i])
          i += 1
        end
      end
    end

    def seq(name, start = 0, stop = 0x7fffffff)
      lp = ::FFI::MemoryPointer.new(:int)
      s = FFI.mappy_fetch_seq(@idx, name, start, stop, lp)
      l = lp.read_int
      return nil if l.zero?

      s[0, l]
      # s.free
    end

    def k
      @idx[:k]
    end

    def w
      @idx[:w]
    end

    def n_seq
      @idx[:n_seq]
    end

    def seq_names
      ptr = @idx[:seq].to_ptr
      Array.new(@idx[:n_seq]) do |i|
        FFI::IdxSeq.new(ptr + i * FFI::IdxSeq.size)[:name]
      end
    end
  end
end
