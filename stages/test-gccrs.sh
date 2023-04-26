#!/bin/bash -xe
# Wrapper around regression testing for OR1K GCC Builds

# Copyright (C) 2020 Embecosm Limited

# Contributor: Simon Cook <simon.cook@embecosm.com>

# SPDX-License-Identifier: GPL-3.0-or-later

WORKSPACE=$PWD

# Allow environment to control parallelism
if [ "x${PARALLEL_JOBS}" == "x" ]; then
  PARALLEL_JOBS=$(nproc)
fi

# Run tests
cd ${WORKSPACE}/build/gccrs
set +e
export PATH=${WORKSPACE}/install/bin:${PATH}

make -j${PARALLEL_JOBS} check-rust

# Run the testsuite in 32-bit mode - we compiled with multilib enabled so it's fine
make -j${PARALLEL_JOBS} check-rust RUNTESTFLAGS="--target_board=unix\{-m32}"

# If this is Windows, then the log merging script only generates the correct
# output if we run unix2dos on the log files first, so in this case transform
# the test output and then regenerate combined logs
if [ $(uname -o) == "Msys" ]; then
  unix2dos gcc/testsuite/*/*.sum.sep
  unix2dos gcc/testsuite/*/*.log.sep
  mv gcc/testsuite/gcc/gcc.log gcc/testsuite/gcc/gcc.log.orig
  mv gcc/testsuite/gcc/gcc.sum gcc/testsuite/gcc/gcc.sum.orig
  mv gcc/testsuite/g++/g++.log gcc/testsuite/g++/g++.log.orig
  mv gcc/testsuite/g++/g++.sum gcc/testsuite/g++/g++.sum.orig
  ${WORKSPACE}/gcc/contrib/dg-extract-results.sh    gcc/testsuite/*/gcc.sum.sep > gcc/testsuite/gcc/gcc.sum
  ${WORKSPACE}/gcc/contrib/dg-extract-results.sh -L gcc/testsuite/*/gcc.log.sep > gcc/testsuite/gcc/gcc.log
  ${WORKSPACE}/gcc/contrib/dg-extract-results.sh    gcc/testsuite/*/g++.sum.sep > gcc/testsuite/g++/g++.sum
  ${WORKSPACE}/gcc/contrib/dg-extract-results.sh -L gcc/testsuite/*/g++.log.sep > gcc/testsuite/g++/g++.log
fi
exit 0