#ifndef CMAPPY_H
#define CMAPPY_H

#include <stdlib.h>
#include <string.h>
#include <zlib.h>
#include "minimap.h"
#include "kseq.h"
KSEQ_DECLARE(gzFile)

typedef struct {
	const char *ctg;
	int32_t ctg_start, ctg_end;
	int32_t qry_start, qry_end;
	int32_t blen, mlen, NM, ctg_len;
	uint8_t mapq, is_primary;
	int8_t strand, trans_strand;
	int32_t seg_id;
	int32_t n_cigar32;
	uint32_t *cigar32;
} mm_hitpy_t;

void mm_reg2hitpy(const mm_idx_t *mi, mm_reg1_t *r, mm_hitpy_t *h);

void mm_free_reg1(mm_reg1_t *r);

kseq_t *mm_fastx_open(const char *fn);

void mm_fastx_close(kseq_t *ks);

int mm_verbose_level(int v);

void mm_reset_timer(void);

extern unsigned char seq_comp_table[256];
mm_reg1_t *mm_map_aux(const mm_idx_t *mi, const char *seq1, const char *seq2, int *n_regs, mm_tbuf_t *b, const mm_mapopt_t *opt);

char *mappy_revcomp(int len, const uint8_t *seq);

char *mappy_fetch_seq(const mm_idx_t *mi, const char *name, int st, int en, int *len);

mm_idx_t *mappy_idx_seq(int w, int k, int is_hpc, int bucket_bits, const char *seq, int len);

#endif
