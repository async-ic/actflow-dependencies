<!--
SPDX-License-Identifier: Apache-2.0
Copyright 2026 Ole Richter - Technical University of Denmark
-->

# Pinned versions with update stoppers

Dependencies deliberately held back from their newest upstream release. Do not
bump without resolving the stopper below; most other submodules track the latest
release tag and may be updated freely.

| Dependency | Pinned | Stopper |
|---|---|---|
| trilinos (060) | 16.2.1 | Xyce 7.10 does not build against Trilinos newer than 16.x. Bump only together with Xyce. |
| bison (006) | 3.7.6 | 3.8+ raises `AC_PREREQ` to autoconf 2.71; the CentOS7 build host ships 2.69. 3.7.6 keeps `AC_PREREQ 2.68`. |
| llvm-project (038) | 14.0.6 | Newest LLVM that builds fluid unmodified. Coupled to fluid, not a general toolchain bump. |
