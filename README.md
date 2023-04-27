# ruby-minimap2

[![Gem Version](https://img.shields.io/gem/v/minimap2?color=brightgreen)](https://rubygems.org/gems/minimap2)
[![CI](https://github.com/kojix2/ruby-minimap2/workflows/CI/badge.svg)](https://github.com/kojix2/ruby-minimap2/actions)
[![Docs Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://rubydoc.info/gems/minimap2)
[![Docs Latest](https://img.shields.io/badge/docs-latest-blue.svg)](https://kojix2.github.io/ruby-minimap2/)
[![The MIT License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE.txt)
[![DOI](https://zenodo.org/badge/325711305.svg)](https://zenodo.org/badge/latestdoi/325711305)

:dna: [minimap2](https://github.com/lh3/minimap2) - the long-read mapper - for [Ruby](https://github.com/ruby/ruby)

## Installation

```
gem install minimap2
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

aligner = Minimap2::Aligner.new("ext/minimap2/test/MT-human.fa")
seq     = aligner.seq("MT_human", 100, 200)
hits    = aligner.align(seq)
pp hits
```
```
[#<Minimap2::Alignment:0x000055bbfde2d128
  @blen=100,
  @cigar=[[100, 0]],
  @cigar_str="100M",
  @cs="",
  @ctg="MT_human",
  @ctg_len=16569,
  @mapq=60,
  @md="",
  @mlen=100,
  @nm=0,
  @primary=1,
  @q_en=100,
  @q_st=0,
  @r_en=200,
  @r_st=100,
  @read_num=1,
  @strand=1,
  @trans_strand=0>]
```
 
</details>

## APIs Overview

```markdown
* Minimap2 module
  - fastx_read                  Read fasta/fastq file.
  - revcomp                     Reverse complement sequence.

  * Aligner class
    * attributes
      - index                   Returns the value of attribute index.
      - idx_opt                 Returns the value of attribute idx_opt.
      - map_opt                 Returns the value of attribute map_opt.
    * methods
      - new(path, preset: nil)  Create a new aligner. (presets: sr, map-pb, map-out, map-hifi, splice, asm5, etc.)
      - align                   Maps and returns alignments.
      - seq                     Retrieve a subsequence from the index.

  * Alignment class
    * attributes
      - ctg                     Returns name of the reference sequence the query is mapped to.
      - ctg_len                 Returns total length of the reference sequence.
      - r_st                    Returns start positions on the reference.
      - r_en                    Returns end positions on the reference.
      - strand                  Returns +1 if on the forward strand; -1 if on the reverse strand.
      - trans_strand            Returns transcript strand. +1 if on the forward strand; -1 if on the reverse strand; 0 if unknown.
      - blen                    Returns length of the alignment, including both alignment matches and gaps but excluding ambiguous bases.
      - mlen                    Returns length of the matching bases in the alignment, excluding ambiguous base matches.
      - nm                      Returns number of mismatches, gaps and ambiguous poistions in the alignment.
      - primary                 Returns if the alignment is primary (typically the best and the first to generate).
      - q_st                    Returns start positions on the query.
      - q_en                    Returns end positions on the query.
      - mapq                    Returns mapping quality.
      - cigar                   Returns CIGAR returned as an array of shape (n_cigar,2). The two numbers give the length and the operator of each CIGAR operation.
      - read_num                Returns read number that the alignment corresponds to; 1 for the first read and 2 for the second read.
      - cs                      Returns the cs tag.
      - md                      Returns the MD tag as in the SAM format. It is an empty string unless the md argument is applied when calling Aligner#align.
      - cigar_str               Returns CIGAR string.
    * methods
      - to_h                    Convert Alignment to hash.
      - to_s                    Convert to the PAF format without the QueryName and QueryLength columns.

  ## FFI module
    * IdxOpt class              Indexing options.
    * MapOpt class              Mapping options.
```

* API is based on [Mappy](https://github.com/lh3/minimap2/tree/master/python), the official Python binding for Minimap2. 
* `Aligner#map` has been changed to `align`, because `map` means iterator in Ruby.
* See [documentation](https://kojix2.github.io/ruby-minimap2/) for details.

<details>
<summary><b>C Structures and Functions</b></summary>

### FFI
* Ruby-Minimap2 is built on top of [Ruby-FFI](https://github.com/ffi/ffi). 
  * Native C functions can be called from the `Minimap2::FFI` module. 
  * Native C structure members can be accessed.
  * Bitfields are supported by [ffi-bitfield](https://github.com/kojix2/ffi-bitfield) gems.
 
```ruby
aligner.idx_opt.members
# => [:k, :w, :flag, :bucket_bits, :mini_batch_size, :batch_size]
aligner.kds_opt.values
# => [15, 10, 0, 14, 50000000, 9223372036854775807]
aligner.idx_opt[:k]
# => 15
aligner.idx_opt[:k] = 14
aligner.idx_opt[:k]
# => 14
```
 
</details>

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

Build Minimap2 and Mappy.

```sh
cd ruby-minimap2
bundle install # Install dependent packages including Ruby-FFI
bundle exec rake minimap2:build
```

A shared library will be created in the vendor directory.

```
└── vendor
   └── libminimap2.so
```

Run tests.

```
bundle exec rake test
```

</details>

ruby-minimap2 is a library under development and there are many points to be improved.

Please feel free to report [bugs](https://github.com/kojix2/ruby-minimap2/issues) and [pull requests](https://github.com/kojix2/ruby-minimap2/pulls)!

Many OSS projects become abandoned because only the founder has commit rights to the original repository. 
If you need commit rights to my repository or want to get admin rights and take over the project, please feel free to contact me @kojix2.

## License

[MIT License](https://opensource.org/licenses/MIT).

## Acknowledgements

I would like to thank Heng Li for making Minimap2, and all the readers who read the README to the end.
