# Minimap2

[![CI](https://github.com/kojix2/ruby-minimap2/workflows/CI/badge.svg)](https://github.com/kojix2/ruby-minimap2/actions)

:dna: [minimap2](https://github.com/lh3/minimap2) - the long-read mapper - for [Ruby](https://github.com/ruby/ruby)

:construction: under development

## Installation

Installing from source code.

```sh
git clone --recurse-submodules https://github.com/kojix2/ruby-minimap2
cd ruby-minimap2
bundle install
bundle exec rake minimap2:build
bundle exec rake install
```

I plan to provide RubyGems in the future.

```sh
gem install minimap2
```

## Usage

```ruby
require 'minimap2'

MM2 = Minimap2
```

## API

```markdown
* Minimap2 module
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

* [Mappy: Minimap2 Python Binding](https://github.com/lh3/minimap2/tree/master/python)

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/kojix2/ruby-minimap2.

## License

[MIT License](https://opensource.org/licenses/MIT).
