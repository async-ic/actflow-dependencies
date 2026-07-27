<!--
SPDX-License-Identifier: Apache-2.0
Copyright 2026 Ole Richter - Technical University of Denmark
-->

# Build dependency overview

Two stacked builds install into a shared `$ACT_HOME` (may be incomplete):

1. **act-actflow-dependencies** (this repo) — toolchain + libs + Xyce, via
   `build_scripts/0NN-*.sh` in numeric order.
2. **yale-asyncvlsi-actflow** (upstream, unmodified) — ACT flow tools into the same
   `$ACT_HOME`, ordered by its top-level `build`.

The `# deps: … | used by: …` header in each `build_scripts/*.sh` is authoritative;
this is the summary.

## 1. act-actflow-dependencies

Toolchain (to `$ACT_HOME/bin`, on PATH; 004/006/008 build-only):
- 004 flex → 006, 072 · 005 cmake → all cmake builds · 006 bison → 072
- 007 gcc16 → everything after · 008 automake → 022-libffi, 030, 044

Libraries (built with gcc16):
- 010 ncurses → 012, 020 · 010 zlib → 022-tcl, 042
- 030 mpich → 042, 057, 060, 072
- 050 fftw → 060, 072 · 052 eigen → 060 · 054 openblas → 060 (BLAS/LAPACK) · 056 AMD → 060
- 057 metis → 060 (ShyLU-Basker)
- 060 trilinos → 072 · 072 xyce → actsim
- 044 numactl → actflow Galois/BiPart/PWRoute/SPRoute (libnuma)
- runtime/downstream only: 012 libedit, 020 readline, 022 libffi/tcl, 042 boost, 046 fmt

Notes: 048 superlu + 058 superlu_dist disabled (unused; Xyce comments them out). 057
metis feeds trilinos ShyLU-Basker (TPL_ENABLE_METIS); its parmetis/gklib build but are
unused. 060 matches Xyce's recommended config (MueLu off, COMPLEX_DOUBLE). boost/fmt
are downstream-only. Trilinos exports no MPI lib, so 060/072 build with `mpicc/mpicxx/mpif90`.

## 2. yale-asyncvlsi-actflow (order from `./build`)

act → Galois → lefdef → annotate → phyDB → layout → BiPart(lefdef,Galois) →
Dali(phyDB,lefdef) → PWRoute/SPRoute/TritonRoute(phyDB,lefdef) → stdlib →
expropt → chp2prs(expropt) → interact → dflowmap →
fpga_proto/xcell/dflow2dot/sky130l/utils → actsim(xyce)

`act` is the base for every tool; Galois is built here, not in the deps package.

## 3. Bridge (deps package → flow)

gcc16 + cmake → all · xyce → actsim · readline/libedit/tcl → interact ·
mpich/boost/fmt → various
