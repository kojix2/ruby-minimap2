# Minimap2

[![Gem Version](https://img.shields.io/gem/v/minimap2?color=brightgreen)](https://rubygems.org/gems/minimap2)
[![CI](https://github.com/kojix2/ruby-minimap2/workflows/CI/badge.svg)](https://github.com/kojix2/ruby-minimap2/actions)
[![The MIT License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE.txt)
[![Docs Latest](https://img.shields.io/badge/docs-stable-blue.svg)](https://rubydoc.info/gems/minimap2)
[![DOI](https://zenodo.org/badge/325711305.svg)](https://zenodo.org/badge/latestdoi/325711305)



:dna: [minimap2](https://github.com/lh3/minimap2) - the long-read mapper - for [Ruby](https://github.com/ruby/ruby)

## Installation

You need to install ruby-minimap2 from the source code. Because you need to build minimap2 and create a shared library. Open your terminal and type the following commands in order. 

Build

```sh
git clone --recursive https://github.com/kojix2/ruby-minimap2
cd ruby-minimap2
bundle install
bundle exec rake minimap2:build
```

Install

```
bundle exec rake install
```

Ruby-minimap2 is tested on Ubuntu and macOS. 

## Quick Start

```ruby
require "minimap2"
```

create aligner

```ruby
aligner = Minimap2::Aligner.new("minimap2/test/MT-human.fa")
```

retrieve a subsequence from the index

```ruby
seq = aligner.seq("MT_human", 100, 200)
```

mapping

```ruby
hits = aligner.align(seq)
pp hits[0].to_h
# {:ctg          => "MT_human",
#  :ctg_len      => 16569,
#  :r_st         => 100,
#  :r_en         => 200,
#  :strand       => 1,
#  :trans_strand => 0,
#  :blen         => 100,
#  :mlen         => 100,
#  :nm           => 0,
#  :primary      => 1,
#  :q_st         => 0,
#  :q_en         => 100,
#  :mapq         => 60,
#  :cigar        => [[100, 0]],
#  :read_num     => 1,
#  :cs           => "",
#  :md           => "",
#  :cigar_str    => "100M"}
```

## APIs Overview

See the [RubyDoc.info document](https://rubydoc.info/gems/minimap2) for details.

```markdown
* Minimap2 module
  - fastx_read
  - revcomp

  * Aligner class
    * attributes
      - index
      - idx_opt
      - map_opt
    * methods
      - new(path, preset: nil)
      - align

  * Alignment class
    * attributes
      - ctg
      - ctg_len
      - r_st
      - r_en
      - strand
      - trans_strand
      - blen
      - mlen
      - nm
      - primary
      - q_st
      - q_en
      - mapq
      - cigar
      - read_num
      - cs
      - md
      - cigar_str
    * methods
      - to_h
      - to_s

  * FFI module
    * IdxOpt class
    * MapOpt class
```

The ruby-minimap2 API is compliant with mappy, the official Python binding for Minimap2. However, there are a few differences. For example, the `map` method has been renamed to `align` since map is the common name for iterators in Ruby.

* [Mappy: Minimap2 Python Binding](https://github.com/lh3/minimap2/tree/master/python)

ruby-minimap2 is built on top of [Ruby-FFI](https://github.com/ffi/ffi). Native functions can be called from the FFI module, which also provides a way to access some C structs such as IdxOpt and MapOpt.

## Development

Fork your repository and clone.

```sh
git clone --recursive https://github.com/kojix2/ruby-minimap2
# git clone https://github.com/kojix2/ruby-minimap2
# cd ruby-minimap2
# git submodule update -i
```

Build.

```sh
cd ruby-minimap2
bundle install # Install dependent packages including Ruby-FFI
bundle exec rake minimap2:build
```

Run tests.

```
bundle exec rake test
```

## Contributing

ruby-minimap2 is a library under development and there are many points to be improved. Please feel free to send us your pull request. 

* [Report bugs](https://github.com/kojix2/ruby-minimap2/issues)
* Fix bugs and [submit pull requests](https://github.com/kojix2/ruby-minimap2/pulls)
* Write, clarify, or fix documentation
* Suggest or add new features
* Create tools based on ruby-minimap2
* Update minimap2 in github submodule

## License

[MIT License](https://opensource.org/licenses/MIT).
