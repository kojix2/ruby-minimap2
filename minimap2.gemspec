# frozen_string_literal: true

require_relative 'lib/minimap2/version'

Gem::Specification.new do |spec|
  spec.name          = 'minimap2'
  spec.version       = Minimap2::VERSION
  spec.authors       = ['kojix2']
  spec.email         = ['2xijok@gmail.com']

  spec.summary       = 'minimap2'
  spec.description   = 'Ruby bindings to the Minimap2 aligner.'
  spec.homepage      = 'https://github.com/kojix2/ruby-minimap2'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 2.5'

  spec.files         = Dir['*.{md,txt}', '{lib,ext}/**/*', 'vendor/libminimap2.{so,dylib}']
  spec.require_paths = ['lib']

  spec.extensions    = %w[ext/Rakefile]

  spec.add_dependency 'ffi'
  spec.add_dependency 'ffi-bitfield'
end
