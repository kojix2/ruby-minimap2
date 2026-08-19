# ruby-minimap2

[![Gem Version](https://img.shields.io/gem/v/minimap2?color=brightgreen)](https://rubygems.org/gems/minimap2)
[![test](https://github.com/kojix2/ruby-minimap2/actions/workflows/ci.yml/badge.svg)](https://github.com/kojix2/ruby-minimap2/actions/workflows/ci.yml)
[![Docs Latest](https://img.shields.io/badge/docs-latest-blue.svg)](https://kojix2.github.io/ruby-minimap2/)
[![The MIT License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE.txt)
[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.18489817.svg)](https://doi.org/10.5281/zenodo.18489817)
[![Lines of Code](https://img.shields.io/endpoint?url=https%3A%2F%2Ftokei.kojix2.net%2Fbadge%2Fgithub%2Fkojix2%2Fruby-minimap2%2Flines)](https://tokei.kojix2.net/github/kojix2/ruby-minimap2)

:dna: [minimap2](https://github.com/lh3/minimap2) - the long-read mapper - for [Ruby](https://github.com/ruby/ruby)

## Installation

ruby-minimap2 bundles the Minimap2 C source code and builds a native extension during installation.

Ruby 3.3 or later is required. Works on Linux, macOS, and Windows.

```
gem install minimap2
```

Show minimap2 version (check installation)

```sh
ruby -r minimap2 -e 'Minimap2.execute("--version")'
```

<details>
<summary><b>Compiling from source</b></summary>

    git clone --recursive https://github.com/kojix2/ruby-minimap2
    cd ruby-minimap2
    bundle install
    bundle exec rake minimap2:build
    bundle exec rake install

</details>

## Quick Start

```ruby
require "minimap2"

reference = <<~DNA.delete("\n")
  GATCACAGGTCTATCACCCTATTAACCACTCACGGGAGCTCTCCATGCATTTGGTATTTTCGTCTGGGGGGTATGCACGC
  GATAGCATTGCGAGACGCTGGAGCCGGAGCACCCTATGTCGCAGTATCTGTCTTTGATTCCTGCCTCATCCTATTATTTAT
  CGCACCTACGTTCAATATTACAGGCGAACATACTTACTAAAGTGTGTTAATTAATTAATGCTTGTAGGACATAATAATAACA
  ATTGAATGTCTGCACAGCCACTTTCCACACAGACATCATAACAAAAAATTTCCACCAAACCCCCCCTCCCCCGCTTC
DNA

aligner = Minimap2::Aligner.new(seq: reference)
query   = reference[50, 200]
hits    = aligner.align(query, name: "query", cs: true, ds: true)
pp hits
```

```
[#<Minimap2::Alignment:0x000055bbfde2d128
  @blen=200,
  @cigar=[[200, 0]],
  @cigar_str="200M",
  @cs=":200",
  @ctg="N/A",
  @ctg_len=320,
  @ds=":200",
  @mapq=60,
  @md=nil,
  @mlen=200,
  @nm=0,
  @primary=1,
  @q_en=200,
  @q_st=0,
  @qlen=200,
  @qname="query",
  @r_en=250,
  @r_st=50,
  @read_num=1,
  @strand=1,
  @trans_strand=0>]
```

## APIs Overview

```markdown
* Minimap2 module
  - fastx_read                  Read fasta/fastq file.
  - revcomp                     Reverse complement sequence.
  - execute                     Calls the main function of Minimap2 with arguments. `Minimap2.execute("--version")`
  - verbose                     Returns the Minimap2 verbosity level.
  - verbose=                    Sets the Minimap2 verbosity level.

  * Aligner class
    * methods
      - new(path, preset: nil)  Create a new aligner. (presets: sr, map-pb, map-ont, map-hifi, splice, asm5, etc.)
      - align                   Maps and returns alignments.
      - seq                     Retrieve a subsequence from the index.
      - k                       Returns the minimizer k-mer length.
      - w                       Returns the minimizer window size.
      - n_seq                   Returns the number of sequences in the index.
      - seq_names               Returns sequence names in the index.
      - index?                  Returns whether the aligner has a live index.
      - free_index              Releases the index.

  * Alignment class
    * attributes
      - qname                   Returns the query sequence name.
      - qlen                    Returns the query sequence length.
      - ctg                     Returns name of the reference sequence the query is mapped to.
      - ctg_len                 Returns total length of the reference sequence.
      - r_st                    Returns start positions on the reference.
      - r_en                    Returns end positions on the reference.
      - strand                  Returns +1 if on the forward strand; -1 if on the reverse strand.
      - trans_strand            Returns transcript strand. +1 if on the forward strand; -1 if on the reverse strand; 0 if unknown.
      - blen                    Returns length of the alignment, including both alignment matches and gaps but excluding ambiguous bases.
      - mlen                    Returns length of the matching bases in the alignment, excluding ambiguous base matches.
      - nm                      Returns number of mismatches, gaps and ambiguous positions in the alignment.
      - primary                 Returns if the alignment is primary (typically the best and the first to generate).
      - q_st                    Returns start positions on the query.
      - q_en                    Returns end positions on the query.
      - mapq                    Returns mapping quality.
      - cigar                   Returns CIGAR returned as an array of shape (n_cigar,2). The two numbers give the length and the operator of each CIGAR operation.
      - read_num                Returns read number that the alignment corresponds to; 1 for the first read and 2 for the second read.
      - cs                      Returns the cs tag, or nil unless requested.
      - ds                      Returns the ds tag, or nil unless requested.
      - md                      Returns the MD tag, or nil unless requested.
      - cigar_str               Returns CIGAR string.
    * methods
      - to_h                    Convert Alignment to hash.
      - to_s                    Convert to the PAF format.
```

- API is based on [Mappy](https://github.com/lh3/minimap2/tree/master/python), the official Python binding for Minimap2.
- `Aligner#map` has been changed to `align`, because `map` means iterator in Ruby.
- Calls on the same Aligner are thread-safe and serialized. Different Aligner instances can run concurrently.
- Multipart indexes are supported, but primary alignments and mapping quality are calculated independently for each part.
- Sequence data uses ASCII-8BIT. Names read from an index use UTF-8.
- See [documentation](https://kojix2.github.io/ruby-minimap2/) for details.

## Contributing

<details>
<summary><b>Development</b></summary>

Fork your repository.
then clone.

```sh
git clone --recursive https://github.com/kojix2/ruby-minimap2
# git clone https://github.com/kojix2/ruby-minimap2
# cd ruby-minimap2
# git submodule update -i
```

Build the native extension.

```sh
cd ruby-minimap2
bundle install
bundle exec rake minimap2:build
```

Run tests.

```
bundle exec rake test
```

Release a Gem.

```
bundle exec rake minimap2:cleanall
bundle exec rake build
ls -l pkg # Check the size of the Gem.
bundle exec rake release
```

</details>

ruby-minimap2 is a library under development and there are many points to be improved.

Please feel free to report [bugs](https://github.com/kojix2/ruby-minimap2/issues) and [pull requests](https://github.com/kojix2/ruby-minimap2/pulls)!

Many OSS projects become abandoned because only the founder has commit rights to the original repository.
If you need commit rights to ruby-minimap2 repository or want to get admin rights and take over the project, please feel free to contact me @kojix2.

## License

[MIT License](LICENSE.txt)

## Acknowledgements

I would like to thank Heng Li for making Minimap2, and all the readers who read the README to the end.
