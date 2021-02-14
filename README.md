# Minimap2

[![CI](https://github.com/kojix2/ruby-minimap2/workflows/CI/badge.svg)](https://github.com/kojix2/ruby-minimap2/actions)

:dna: [minimap2](https://github.com/lh3/minimap2) - the long-read mapper - for [Ruby](https://github.com/ruby/ruby)

:construction: under development

## Installation

You need to install it from the source code. Because you need to build minimap2 and create a shared library. Open your terminal and type the following commands in order. 

```sh
git clone --recurse-submodules https://github.com/kojix2/ruby-minimap2
cd ruby-minimap2
bundle install
bundle exec rake minimap2:build
bundle exec rake install
```

You can run tests to see if the installation was successful. 

```
bundle exec rake test
```

## Quick Start

```ruby
require "minimap2"

# load or build index
aligner = Minimap2::Aligner.new("minimap2/test/MT-human.fa")

# retrieve a subsequence from the index
seq = aligner.seq("MT_human", 100, 200)

# mapping
aligner.align(seq) do |h|
  pp h.to_h
end
```

## APIs

* [Mappy: Minimap2 Python Binding](https://github.com/lh3/minimap2/tree/master/python)

```markdown
* Minimap2 module
  * Aligner class
  * Alignment class
```

## Development

```sh
git clone --recurse-submodules https://github.com/kojix2/ruby-minimap2
# git clone https://github.com/kojix2/ruby-minimap2
# cd ruby-minimap2
# git submodule update -i
cd ruby-minimap2
bundle install
bundle exec rake minimap2:build
bundle exec rake test
```

## Contributing

ruby-minimap2 is a library under development and there are many points to be improved. 
If you improve the source code, please feel free to send us your pull request. 
Typo corrections are also welcome. 

Bug reports and pull requests are welcome on GitHub at https://github.com/kojix2/ruby-minimap2.

## License

[MIT License](https://opensource.org/licenses/MIT).
