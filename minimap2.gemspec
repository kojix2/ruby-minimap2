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
  spec.required_ruby_version = ">= 2.5"

  # If you include the lib/simde code, the Gem size will be 1MB.
  # Build with lib/simde is currently not supported, so simde code is not included in the Gem.
  spec.files         = (Dir["*.{md,txt}", "{lib,ext}/**/*", "vendor/libminimap2.{so,dylib,dll}"] -
                        Dir["ext/minimap2/lib/**/*"])
  spec.require_paths = ["lib"]

  spec.extensions    = %w[ext/Rakefile]

  spec.add_dependency "ffi"
  spec.add_dependency "ffi-bitfield"
end
