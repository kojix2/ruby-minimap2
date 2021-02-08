# frozen_string_literal: true

require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
end

task default: :test

namespace :minimap2 do
  desc "Compile Minimap2"
  task :build do
    require "ffi"
    Dir.chdir("minimap2") do
      # Add -fPIC option to Makefile
      system "git apply ../minimap2.patch"
      system "make"
      case RbConfig::CONFIG["host_os"]
      when /mswin|msys|mingw|cygwin|bccwin|wince|emc/
        warn "windows not supported"
      when /darwin|mac os/
        system "clang -dynamiclib -undefined dynamic_lookup -o libminimap2.#{FFI::Platform::LIBSUFFIX} *.o"
      else
        system "cc -shared -o libminimap2.so *.o"
      end
      system "git apply -R ../minimap2.patch"
      FileUtils.mkdir_p("../vendor")
      FileUtils.move("libminimap2.#{FFI::Platform::LIBSUFFIX}", "../vendor/libminimap2.#{FFI::Platform::LIBSUFFIX}")
    end
  end

  desc "Cleanup"
  task :clean do
    Dir.chdir("minimap2") do
      system "make clean"
    end
  end
end

namespace :c2ffi do
  desc "Generate metadata files (JSON format) using c2ffi"
  task :generate do
    header_files = FileList["minimap2/**/*.h"]
    header_files.each do |file|
      system "c2ffi #{file}" \
             " -o codegen/native_functions/#{File.basename(file, ".h")}.json"
    end
  end

  desc "Remove metadata files"
  task :remove do
    FileList["codegen/native_functions/*.json"].each do |path|
      File.unlink(path) if File.exist?(path)
    end
  end
end
