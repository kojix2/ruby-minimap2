# frozen_string_literal: true

class Minimap2
  class Aligner
    def initialize(
      fn_idx_in: nil,
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
        FFI.mm_set_opt(nil, @idx_opt, @map_opt)
      end

      # always perform alignment
      @map_opt.flag |= 4
      @idx_opt.batch_size = 0x7fffffffffffffff
      @idx_opt.k if k
      @idx_opt.w if w
      @map_opt.min_cnt = min_cnt if min_cnt
      @map_opt.min_chain_score = min_chain_score if min_chain_score
      @map_opt.min_dp_max = min_dp_score if min_dp_score
      @map_opt.bw = bw if bw
      @map_opt.best_n = best_n if best_n
      @map_opt.max_frag_len = max_frag_len if max_frag_len
      @map_opt.flag |= extra_flags if extra_flags
      if scoring && scoring.size >= 4
        @map_opt.a = scoring[0]
        @map_opt.b = scoring[1]
        @map_opt.q = scoring[2]
        @map_opt.e = scoring[3]
        @map_opt.q2 = @map_opt.q
        @map_opt.e2 = @map_opt.e
        if scoring.size >= 6
          @map_opt.q2 = scoring[4]
          @map_opt.e2 = scoring[5]
          @map_opt.sc_ambi = scoring[6] if scoring.size >= 7
        end
      end

      r = FFI::IdxReader.new

      if seq
        @idx = FFI.mappy_idx_seq(
          @idx_opt.w, @idx_opt.k, @idx_opt & 1, @idx_opt.bucket_bits, seq, seq.size
        )
        FFI.mm_mapopt_update(@map_opt, @idx)
        @map_opt.mid_occ = 1000 # don't filter high-occ seeds
      else
        r = if fn_idx_out
              FFI.mm_idx_reader_open(fn_idx_in, @idx_opt, nil)
            else
              FFI.mm_idx_reader_open(fn_idx_in, @idx_opt, fn_idx_out)
            end
        unless @r.null?
          @idx = FFI.mm_idx_reader_read(@r, n_threads)
          FFI.mm_idx_reader_close(r)
          FFI.mm_mapopt_update(@map_opt, @idx)
          FFI.mm_idx_index_name(@idx)
        end
      end
    end

    # FIXME: naming
    def map; end

    def seq; end
  end
end
