# frozen_string_literal: true

require "bundler/gem_tasks"
require "rake/clean"
require "rake/extensiontask"
require "rake/testtask"

spec = Gem::Specification.load("minimap2.gemspec")

CLOBBER.include "ext/ruby_minimap2/build"

Rake::ExtensionTask.new("minimap2_ext", spec) do |ext|
  ext.ext_dir = "ext/ruby_minimap2"
  ext.lib_dir = "lib/minimap2"
  ext.config_options << "--enable-testing"
end

namespace :minimap2 do
  task build: :compile
  task clean: :clean
  task cleanall: :clobber
end

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
end
task test: :compile

task default: :test
