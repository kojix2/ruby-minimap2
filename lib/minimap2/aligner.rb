# frozen_string_literal: true

require_relative "ffi"
require_relative "ffi/mappy"

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
        unless @r.null?
          @idx = FFI.mm_idx_reader_read(@r, n_threads)
          FFI.mm_idx_reader_close0(@r)
          FFI.mm_mapopt_update(@map_opt, @idx)
          FFI.mm_idx_index_name(@idx)
        end
      end
    end

    def destroy
      FFI.mm_idx_destroy(@idx) unless @idx.null?
    end

    # FIXME: naming
    def map(
      seq, seq2 = nil,
      buf: nil,
      cs: false,
      md: false,
      max_frag_len: nil,
      extra_flags: nil
    )

      return if @idx.null?

      h = FFI::Hit.new
      map_opt = @map_opt # FIXME: should clone?
      map_opt.max_frag_len = max_frag_len if max_frag_len
      map_opt.flag |= extra_flags if extra_flags

      b = (buf || FFI::TBuf.new)
      km = FFI.mm_tbuf_get_km(b)

      n_regs = ::FFI::MemoryPointer.new(:int)
      regs = if seq2
               FFI.mm_map_aux(@idx, seq, seq2, n_regs, b)
             else
               FFI.mm_map_aux(@idx, seq, nil, n_regs, b)
             end

      begin
        i = 0
        while i < n_regs
          FFI.mm_reg2hitpy(@idx, regs[i], h)
          cigar = []
          _cs = ""
          _MD = ""
          # for k in ...
          # if cs or MD
          # if cs cmappy.mm_gen_cs
          # if MD cmappy.mm_gen_MD
          # yield Alignment(
          #   h.ctg,
          #   h.ctg_len,
          #   h.ctg_start,
          #   h.ctg_end,
          #   h.strand,
          #   h.qry_start,
          #   h.qry_end,
          #   h.mapq,
          #   cigar,
          #   h.is_primary,
          #   h.mlen,
          #   h.blen,
          #   h.NM,
          #   h.trans_strand,
          #   h.seg_id,
          #   _cs,
          #   _MD
          # )

          # cmappy.mm_free_reg1
          i += 1
        end
      ensure
        while i < n_regs
          # cmappy.mm_free_reg1
          # free(regs)
          # free(cs_str)
        end
      end
    end

    def seq; end

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
      Array.new(@idx[:n_seq]) { |i| @idx[:seq][i][:name] }
    end
  end
end
