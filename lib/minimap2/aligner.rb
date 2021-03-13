# frozen_string_literal: true

module Minimap2
  class Aligner
    attr_reader :idx_opt, :map_opt, :index

    def initialize(
      fn_idx_in,
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
        FFI.mm_set_opt(preset, idx_opt, map_opt)
      else
        # set the default options
        FFI.mm_set_opt(0, idx_opt, map_opt)
      end

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
        map_opt[:q2] = map_opt.q
        map_opt[:e2] = map_opt.e
        if scoring.size >= 6
          map_opt[:q2] = scoring[4]
          map_opt[:e2] = scoring[5]
          map_opt[:sc_ambi] = scoring[6] if scoring.size >= 7
        end
      end

      if seq
        @index = FFI.mappy_idx_seq(
          idx_opt.w, idx_opt.k, idx_opt & 1,
          idx_opt.bucket_bits, seq, seq.size
        )
        FFI.mm_mapopt_update(map_opt, index)
        map_opt.mid_occ = 1000 # don't filter high-occ seeds
      else
        reader = FFI.mm_idx_reader_open(fn_idx_in, idx_opt, fn_idx_out)

        # The Ruby version raises an error here
        raise "Cannot open : #{fn_idx_in}" if reader.null?

        @index = FFI.mm_idx_reader_read(reader, n_threads)
        FFI.mm_idx_reader_close(reader)
        FFI.mm_mapopt_update(map_opt, index)
        FFI.mm_idx_index_name(index)
      end
    end

    # FIXME: naming
    def destroy
      FFI.mm_idx_destroy(index) unless index.null?
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

      return if index.null?

      map_opt.max_frag_len = max_frag_len if max_frag_len
      map_opt.flag |= extra_flags if extra_flags

      buf ||= FFI::TBuf.new
      km = FFI.mm_tbuf_get_km(buf)
      n_regs_ptr = ::FFI::MemoryPointer.new :int

      ptr = FFI.mm_map_aux(index, seq, seq2, n_regs_ptr, buf, map_opt)
      n_regs = n_regs_ptr.read_int

      regs = Array.new(n_regs) { |i| FFI::Reg1.new(ptr + i * FFI::Reg1.size) }

      hit = FFI::Hit.new
      cs_str     = ::FFI::MemoryPointer.new(::FFI::MemoryPointer.new(:string))
      m_cs_str   = ::FFI::MemoryPointer.new :int
      i = 0
      begin
        while i < n_regs
          FFI.mm_reg2hitpy(index, regs[i], hit)
          cigar = []

          c = hit[:cigar32].read_array_of_uint32(hit[:n_cigar32])
          # convert the 32-bit CIGAR encoding to Ruby array
          cigar = c.map { |x| [x >> 4, x & 0xf] }

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

          yield Alignment.new(hit, cigar, _cs, _md)

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
      s = FFI.mappy_fetch_seq(index, name, start, stop, lp)
      l = lp.read_int
      return nil if l.zero?

      s.read_string(l)
    end

    def k
      index[:k]
    end

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
