#!/bin/bash

../configure --prefix=/tools  \
	     --with-sysroot=$LFS  \
	     --with-lib-path=/tools/lib \
	     --target=$LFS_TGT    \
	     --disable-nls \
	     --disable-werror 
