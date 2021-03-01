# frozen_string_literal: true

# example.c
require "minimap2"

MM2 = Minimap2

iopt = MM2::FFI::IdxOpt.new
mopt = MM2::FFI::MapOpt.new

n_threads = 3

MM2::FFI.mm_set_opt(0, iopt, mopt)

mopt[:flag] |= MM2::FFI::MM_F_CIGAR

r = MM2::FFI.mm_idx_reader_open(ARGV[0], iopt, nil)

mi = MM2::FFI.mm_idx_reader_read(r, 3)
MM2::FFI.mm_mapopt_update(mopt, mi)

tbuf = MM2::FFI.mm_tbuf_init

# FIXME