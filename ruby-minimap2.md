---
title: 'Ruby-Minimap2: A Ruby wrapper for Minimap2'
author:
  - 'kojix2'
date: 7 Jan 2022
bibliography: ruby-minimap2.bib
header-includes:
  - \usepackage[margin=1in]{geometry}
---

# Summary

Ruby-Minimap2 is a Ruby wrapper for Minimap2. It enables users to get alignments of nucleotide sequences using the Ruby API.

Code : [https://github.com/kojix2/ruby-minimap2](https://github.com/kojix2/ruby-minimap2)

# Statement of need

Minimap2 [@li2018] is a widely used alignment program that can map DNA or long mRNA sequences against a reference genome. Minimap2 is implemented in the C language and provides an application programming interface for Python called Mappy. We present Ruby-Minimap2, which gives a Ruby interface to Minimap2. This makes it easy to integrate Minimap2 into web applications beyond traditional scientific research applications.

# Implementation

Ruby-Minimap2 was implemented using Ruby-FFI, a library to call C functions using libffi. The Python interface, Mappy, is implemented in Cython, but there is no Cython equivalent library in Ruby. Ruby minimap2 compiles the Minimap2 shared library, which contains Mappy functions, at installation time and calls it from Ruby.

TODO: benchmark?

## Examples

```ruby
require "minimap2"

# load or build index
aligner = Minimap2::Aligner.new("ext/minimap2/test/MT-human.fa")

# retrieve a subsequence from the index
seq     = aligner.seq("MT_human", 100, 200)

# mapping
hits    = aligner.align(seq)

# show result
pp hits
```

# Reference
