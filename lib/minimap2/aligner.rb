# frozen_string_literal: true

module Minimap2
  class Aligner
    attr_reader :index_options, :map_options, :index

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

      @index_options = FFI::IdxOpt.new
      @map_options = FFI::MapOpt.new

      if preset
        FFI.mm_set_opt(preset, index_options, map_options)
      else
        # set the default options
        FFI.mm_set_opt(0, index_options, map_options)
      end

      # always perform alignment
      map_options[:flag] |= 4
      index_options[:batch_size] = 0x7fffffffffffffff

      # override preset options
      index_options[:k] = k if k
      index_options[:w] = w if w
      map_options[:min_cnt] = min_cnt if min_cnt
      map_options[:min_chain_score] = min_chain_score if min_chain_score
      map_options[:min_dp_max] = min_dp_score if min_dp_score
      map_options[:bw] = bw if bw
      map_options[:best_n] = best_n if best_n
      map_options[:max_frag_len] = max_frag_len if max_frag_len
      map_options[:flag] |= extra_flags if extra_flags
      if scoring && scoring.size >= 4
        map_options[:a] = scoring[0]
        map_options[:b] = scoring[1]
        map_options[:q] = scoring[2]
        map_options[:e] = scoring[3]
        map_options[:q2] = map_options.q
        map_options[:e2] = map_options.e
        if scoring.size >= 6
          map_options[:q2] = scoring[4]
          map_options[:e2] = scoring[5]
          map_options[:sc_ambi] = scoring[6] if scoring.size >= 7
        end
      end

      if seq
        @index = FFI.mappy_idx_seq(
          index_options.w, index_options.k, index_options & 1,
          index_options.bucket_bits, seq, seq.size
        )
        FFI.mm_mapopt_update(map_options, index)
        map_options.mid_occ = 1000 # don't filter high-occ seeds
      else
        reader = FFI.mm_idx_reader_open(fn_idx_in, index_options, fn_idx_out)

        # The Ruby version raises an error here
        raise "Cannot open : #{fn_idx_in}" if reader.null?

        @index = FFI.mm_idx_reader_read(reader, n_threads)
        FFI.mm_idx_reader_close(reader)
        FFI.mm_mapopt_update(map_options, index)
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

      map_options.max_frag_len = max_frag_len if max_frag_len
      map_options.flag |= extra_flags if extra_flags

      buf ||= FFI::TBuf.new
      km = FFI.mm_tbuf_get_km(buf)
      n_regs_ptr = ::FFI::MemoryPointer.new :int

      ptr = FFI.mm_map_aux(index, seq, seq2, n_regs_ptr, buf, map_options)
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
