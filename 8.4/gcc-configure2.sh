#!/usr/bin/bash

CC=$LFS_TGT-gcc
CXX=$LFS_TGT-g++
AR=$LFS_TGT-ar
RANLIB=$LFS_TGT-ranlib

../configure  \
    --prefix=/tools    \
    --with-local-prefix=/tools \
    --with-native-system-header-dir=/tools/include  \
    --enable-languages=c,c++  \
    --disable-libstdcxx-pch   \
    --disable-multilib         \
    --disable-bootstrap       \
    --disable-libgomp              
    



