# example.c
require "minimap2"

MM2 = Minimap2

iopt = MM2::FFI::IdxOpt.new
mopt = MM2::FFI::MapOpt.new

n_threads = 3

p MM2::FFI.mm_set_opt("default", iopt, mopt)

p iopt.values
p mopt.values
