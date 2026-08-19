# frozen_string_literal: true

require_relative "lib/minimap2/version"

Gem::Specification.new do |spec|
  spec.name          = "minimap2"
  spec.version       = Minimap2::VERSION
  spec.authors       = ["kojix2"]
  spec.email         = ["2xijok@gmail.com"]

  spec.summary       = "minimap2"
  spec.description   = "Ruby bindings to the Minimap2 aligner."
  spec.homepage      = "https://github.com/kojix2/ruby-minimap2"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 3.3"

  spec.files = Dir[
    "README.md",
    "LICENSE.txt",
    "lib/**/*.rb",
    "ext/ruby_minimap2/*.{c,h,rb}",
    "ext/minimap2/{Makefile,LICENSE.txt}",
    "ext/minimap2/*.{c,h}",
    "ext/minimap2/sse2neon/*.h"
  ]
  spec.require_paths = ["lib"]

  spec.extensions    = %w[ext/ruby_minimap2/extconf.rb]
end
