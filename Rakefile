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
    Dir.chdir("minimap2") do
      FileUtils.copy("Makefile", "Makefile.orig")
      FileUtils.copy("options.c", "options.c.orig")
      begin
        # Add -fPIC option to Makefile
        system "patch Makefile ../minimap2_patches/Makefile.patch"
        system "patch options.c ../minimap2_patches/options.patch"
        system "make"
        system "cc -shared -o libminimap2.so *.o"
        FileUtils.mkdir_p("../vendor")
        FileUtils.move("libminimap2.so", "../vendor/libminimap2.so")
      ensure
        FileUtils.move("Makefile.orig", "Makefile")
        FileUtils.move("options.c.orig", "options.c")
      end
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
