# frozen_string_literal: true

require "bundler/gem_tasks"
require "rake/testtask"
require "tty-command"

cmd = TTY::Command.new

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
end

task default: :test

namespace :minimap2 do
  desc "Compile Minimap2"
  task :build do
    Dir.chdir("minimap2") do
      # Add -fPIC option to Makefile
      cmd.run "git apply ../minimap2.patch"
      cmd.run "cp ../cmappy/cmappy.h ../cmappy/cmappy.c ."
      cmd.run "make"
      case RbConfig::CONFIG["host_os"]
      when /mswin|msys|mingw|cygwin|bccwin|wince|emc/
        warn "windows not supported"
      when /darwin|mac os/
        libsuffix = "dylib"
        cmd.run "clang -dynamiclib -undefined dynamic_lookup -o libminimap2.#{libsuffix} *.o"
      else
        libsuffix = "so"
        cmd.run "cc -shared -o libminimap2.so *.o"
      end
      cmd.run "rm cmappy.h cmappy.c"
      cmd.run "git apply -R ../minimap2.patch"
      cmd.run "mkdir -p ../vendor"
      cmd.run "mv libminimap2.#{libsuffix} ../vendor/libminimap2.#{libsuffix}"
    end
  end

  desc "Cleanup"
  task :clean do
    Dir.chdir("minimap2") do
      cmd.run "make clean"
    end
  end
end

namespace :c2ffi do
  desc "Generate metadata files (JSON format) using c2ffi"
  task :generate do
    cmd.run "mkdir -p codegen"
    header_files = FileList["minimap2/**/*.h"]
    header_files.each do |file|
      cmd.run "c2ffi #{file}" \
             " -o codegen/#{File.basename(file, ".h")}.json"
    end
  end

  desc "Remove metadata files"
  task :remove do
    FileList["codegen/*.json"].each do |path|
      cmd.run "rm #{path}" if File.exist?(path)
    end
  end
end
