#!/bin/bash


../configure  \
    --prefix=/tools  \
    --host=$LFS_TGT  \
    --build=$(../scripts/config.guess)  \
    --enable-kernel=3.2    \
    --with-headers=/tools/include
