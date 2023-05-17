# frozen_string_literal: true

require "bundler/gem_tasks"
require "rake/testtask"

# Prevent releasing the gem including htslib shared library.

task :check_shared_library_exist do
  unless Dir.glob("vendor/*.{so,dylib,dll}").empty?
    magenta = "\e[35m"
    clear = "\e[0m"
    abort "#{magenta}Shared library exists in the vendor directory.#{clear}"
  end
end

Rake::Task["release:guard_clean"].enhance(["check_shared_library_exist"])

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
end

task default: :test

load "ext/Rakefile"
