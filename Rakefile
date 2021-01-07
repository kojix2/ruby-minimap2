# frozen_string_literal: true

require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
end

task default: :test

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

namespace :minimap2 do
  desc "Compile Minimap2"
  task :compile do
    FileUtils.copy("minimap2/Makefile", "minimap2/Makefile_original")
    begin
      # -fPIC
      system 'sed -i -E "s/^CFLAGS=/CFLAGS= -fPIC /" minimap2/Makefile'
      Dir.chdir("minimap2") do
        system `make`
        system "cc -shared -o libminimap2.so *.o"
      end
      FileUtils.move("minimap2/libminimap2.so", "vendor/libminimap2.so")
    ensure
      FileUtils.move("minimap2/Makefile_original", "minimap2/Makefile")
    end
  end

  desc "Cleanup"
  task :clean do
    Dir.chdir("minimap2") do
      system "make clean"
    end
  end
end
