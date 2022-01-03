#!/bin/bash

CC=$LFS_TGT-gcc \
AR=$LFS_TGT-ar  \
RANLIB=$LFS_TGT-ranlib  \
../configure  \
  --prefix=/tools \
  --disable-nls   \
  --disable-werror  \
  --with-lib-path=/tools/lib  \
  --with-sysroot

