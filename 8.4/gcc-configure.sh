#!/usr/bin/bash

../configure  \
    --target=$LFS_TGT  \
    --prefix=/tools    \
    --with-glibc-version=2.11 \
    --with-sysroot=$LFS       \
    --with-newlib             \
    --without-headers         \
    --with-local-prefix=/tools \
    --with-native-system-header-dir=/tools/include  \
    --disable-nls              \
    --disable-shared           \
    --disable-multilib         \
    --disable-decimal-float    \
    --disable-threads          \
    --disable-libatomic        \
    --disable-libgomp          \
    --disable-libmpx           \
    --disable-libquadmath      \
    --disable-libssp           \
    --disable-libvtv           \
    --disable-libstdcxx        \
    --enable-languages=c,c++

