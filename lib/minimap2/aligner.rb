# frozen_string_literal: true

module Minimap2
  # Builds or loads a minimap2 index and maps sequences against it.
  #
  # Calls on the same Aligner are thread-safe and serialized. Different Aligner
  # instances can map concurrently.
  #
  # @!method initialize(path = nil, seq: nil, preset: nil, k: nil, w: nil, min_cnt: nil, min_chain_score: nil, min_dp_score: nil, bw: nil, bw_long: nil, best_n: nil, n_threads: 3, fn_idx_out: nil, max_frag_len: nil, extra_flags: nil, scoring: nil, sc_ambi: nil, max_chain_skip: nil, batch_size: nil)
  #   Creates an aligner from a FASTA/FASTQ/index file or one in-memory sequence.
  #   @param path [String, nil] sequence or index file
  #   @param seq [String, nil] single sequence to index when path is nil
  #   @param preset [String, Symbol, nil] minimap2 preset such as map-ont, map-pb, map-hifi, sr, splice, or asm5
  #   @param k [Integer, nil] k-mer length in the range 1..28
  #   @param w [Integer, nil] minimizer window size in the range 1..255
  #   @param min_cnt [Integer, nil] minimum number of minimizers on a chain
  #   @param min_chain_score [Integer, nil] minimum chaining score
  #   @param min_dp_score [Integer, nil] minimum DP alignment score
  #   @param bw [Integer, nil] chaining and alignment bandwidth
  #   @param bw_long [Integer, nil] bandwidth for long-gap rechaining
  #   @param best_n [Integer, nil] maximum number of alignments to return
  #   @param n_threads [Integer] number of indexing threads
  #   @param fn_idx_out [String, nil] path at which to write the generated index
  #   @param max_frag_len [Integer, nil] maximum fragment length
  #   @param extra_flags [Integer, nil] additional minimap2 mapping flags
  #   @param scoring [Array<Integer>, nil] four, six, or seven scoring values
  #   @param sc_ambi [Integer, nil] score for ambiguous bases
  #   @param max_chain_skip [Integer, nil] maximum chain-skip count
  #   @param batch_size [Integer, nil] index batch size; small values create a multipart index
  #   @raise [ArgumentError] if a preset, k, or w is invalid
  #   @raise [Minimap2::Error] if the index cannot be initialized or lacks sequence data
  #
  # @!method align(seq, seq2 = nil, name: nil, cs: false, ds: false, md: false, max_frag_len: nil, extra_flags: nil)
  #   Maps one sequence or a paired sequence.
  #   @param seq [String] query sequence
  #   @param seq2 [String, nil] paired query sequence
  #   @param name [String, nil] query name stored in Alignment; defaults to "*"
  #   @param cs [Boolean] generate the cs tag
  #   @param ds [Boolean] generate the ds tag
  #   @param md [Boolean] generate the MD tag
  #   @param max_frag_len [Integer, nil] per-call maximum fragment length
  #   @param extra_flags [Integer, nil] per-call additional mapping flags
  #   @return [Array<Alignment>] alignments, or an empty array when no index or hit is available
  #
  # @!method seq(name, start = 0, stop = -1)
  #   Retrieves a subsequence from the index.
  #   @return [String, nil] an ASCII-8BIT sequence, or nil if unavailable
  #
  # @!method k
  #   @return [Integer] minimizer k-mer length
  #   @raise [Minimap2::Error] if no index is available
  #
  # @!method w
  #   @return [Integer] minimizer window size
  #   @raise [Minimap2::Error] if no index is available
  #
  # @!method n_seq
  #   @return [Integer] number of sequences across all index parts
  #
  # @!method seq_names
  #   Returns names in index order, including duplicate names.
  #   @return [Array<String>] UTF-8 sequence names
  #
  # @!method index?
  #   @return [Boolean] whether a live index is available
  #
  # @!method free_index
  #   Releases every native index owned by this object. Calling it repeatedly is safe.
  #   @return [nil]
  class Aligner
  end
end
