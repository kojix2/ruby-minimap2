# frozen_string_literal: true

require "mkmf"
require "fileutils"
require "rbconfig"
require "shellwords"

source_dir = File.expand_path("../minimap2", __dir__)
build_dir = File.expand_path("build/minimap2", Dir.pwd)

abort "minimap2 sources are missing; initialize the git submodule" unless File.file?(File.join(source_dir, "minimap.h"))
abort "zlib is required to build ruby-minimap2" unless have_library("z", "gzopen")
have_func("log") || have_library("m", "log")
if !(RbConfig::CONFIG.fetch("host_os") =~ /mswin/) && !(have_func("pthread_create") || have_library("pthread",
                                                                                                    "pthread_create"))
  abort "pthread is required to build ruby-minimap2"
end

FileUtils.rm_rf(build_dir)
FileUtils.mkdir_p(build_dir)
FileUtils.cp_r(Dir.glob(File.join(source_dir, "*")), build_dir)

host_cpu = RbConfig::CONFIG.fetch("host_cpu")
cflags = %w[-O2 -fPIC -DHAVE_KALLOC]
make_args = ["libminimap2.a", "CFLAGS=#{cflags.join(' ')}"]

case host_cpu
when /arm64|aarch64/
  make_args.concat(["aarch64=1", "INCLUDES=-Isse2neon",
                    "CFLAGS=#{(cflags + %w[-D_FILE_OFFSET_BITS=64 -fsigned-char]).join(' ')}"])
when /arm/
  make_args.concat(["arm_neon=1", "INCLUDES=-Isse2neon",
                    "CFLAGS=#{(cflags + %w[-D_FILE_OFFSET_BITS=64 -mfpu=neon -fsigned-char]).join(' ')}"])
end

Dir.chdir(build_dir) do
  abort "failed to build bundled minimap2" unless system(RbConfig::CONFIG.fetch("MAKE", "make"), *make_args)
end

$INCFLAGS << " -I#{build_dir}"
$LOCAL_LIBS << " #{File.join(build_dir, 'libminimap2.a').shellescape}"
$defs << "-DRUBY_MINIMAP2_TESTING" if enable_config("testing", false)

create_makefile("minimap2/minimap2_ext")
