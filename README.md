# lfs-prj
I am trying to run Linux from scratch tutorial.

## Version 11.3
### chapter 1-4, host system side
 生成一个新的分区,建议为30GB partition, 我可以用一个新硬盘来做这件事情,
 cfdisk, fdisk, 

 export LFS=/mnt/lfs, 

 export LFS=/media/ruff/compile,


#### 步骤:
##### 生成加载目录,

##### 生成目录结构 
```
sudo mkdir -pv $LFS/{etc,var} $LFS/usr/{bin,lib,sbin}
for i in bin lib sbin; do
ln -sv usr/$i $LFS/$i
done
$ sudo mkdir -pv $LFS/lib64
```
建立一个普通用户，进行安装, 
lfs,

更改目录的权限,

```
chown -v lfs $LFS/{usr{,/*},lib,var,etc,bin,sbin,tools}
su - lfs

```

linux cd, Permission denied,添加+x权限即可



### chapter 5-6, /mnt/lfs partition, mounted,
可以用一个文件来代替,

as user lfs,

#### 5.2 编译Binutils-2.40, Pass 1
1 SBU, 639 MB,

```
../configure  --prefix=$LFS/tools --with-sysroot=$LFS --target=$LFS_TGT  --disable-nls --enable-gprofng=no  --disable-werror
```
begin: 15:13, end: 15:15, dur: 2minutes

安装在tools/目录下面,

#### 5.3 GCC-12.2.0, Pass 1
需要GMP, MPFR, MPC packages,将这几个包都解压到GCC的源码目录里,

```
../configure  \
    --target=$LFS_TGT  \
    --prefix=$LFS/tools  \
    --with-glibc-version=2.37  \
    --with-sysroot=$LFS        \
    --with-newlib              \
    --without-headers          \
    --enable-default-pie       \
    --enable-default-ssp       \
    --disable-nls              \
    --disable-shared           \
    --disable-multilib         \
    --disable-threads          \
    --disable-libatomic        \
    --disable-libgomp          \
    --disable-libquadmath      \
    --disable-libssp           \
    --disable-libvtv           \
    --disable-libstdcxx        \
    --enable-languages=c,c++   \
    --disable-bootstrap        \
```

make

遇见了问题,

```
checking build system type... x86_64-pc-linux-gnu
checking host system type... x86_64-lfs-linux-gnu
checking target system type... x86_64-lfs-linux-gnu
checking for x86_64-lfs-linux-gnu-gcc... /media/ruff/compile/sources/11.3/gcc-12.2.0/build/./gcc/xgcc -B/media/ruff/compile/sources/11.3/gcc-12.2.0/build/./gcc/ -B/media/ruff/compile/tools/x86_64-lfs-linux-gnu/bin/ -B/media/ruff/compile/tools/x86_64-lfs-linux-gnu/lib/ -isystem /media/ruff/compile/tools/x86_64-lfs-linux-gnu/include -isystem /media/ruff/compile/tools/x86_64-lfs-linux-gnu/sys-include

checking whether the C compiler works... no
configure: error: in `/media/ruff/compile/sources/11.3/gcc-12.2.0/build/x86_64-lfs-linux-gnu/libbacktrace':
configure: error: C compiler cannot create executables

lfs gcc link tests are not allowed after GCC_NO_EXECUTABLES

```

无法生成可执行文件，实际上编译已经成功了。

If you're building this on a x86_64 machine and you have x86_64 as target, you're not actually building a cross compiler.
You seem to be building an isolated stage1 compiler, so you have to add **--disable-bootstrap flag**. GCC by default disables bootstrap if your build target platform is not the native platform (a cross compiler).

```
--disable-bootstrap
# 还是不行, 但是上一个错误已经没有了
checking dynamic linker characteristics... configure: error: Link tests are not allowed after GCC_NO_EXECUTABLES.
make[1]: *** [Makefile:15714: **configure-target-libobjc**] Error 1

lfs-linux-gnu/bin/ld: cannot find Scrt1.o: No such file or directory
lfs-linux-gnu/bin/ld: cannot find crti.o: No such file or directory
lfs-linux-gnu/bin/ld: cannot find -lc: No such file or directory
lfs-linux-gnu/bin/ld: cannot find crtn.o: No such file or directory

checking dynamic linker characteristics... configure: error: Link tests are not allowed after GCC_NO_EXECUTABLES.
make[1]: *** [Makefile:15714: configure-target-libobjc] Error 1
make[1]: Leaving directory '/media/ruff/compile/sources/gcc-12.2.0/build'

```

Second - that error indicates that you didn't tell the compiler what platform it should be targeting. Without that information, the compiler will complain that it cannot link executables (which is the behavior you're seeing).

现在发现了一处错误--enable-languages, 居然拼写错误,lto, objc is compiled by default.这下成功了,

configure --help, 可以查看一些配置选项,

```
$ cat gcc/limitx.h  gcc/glimits.h gcc/limity.h  > `dirname $($LFS_TGT-gcc -print-libgcc-file-name)`/install-tools/include/limits.h
```

#### 5.4 Linux-6.1.11 API headers,
将linux kernel 的编程接口提供给C library, Glibc, 

```
make headers 
find usr/include -type f ! -name '*.h' -delete
cp -rv usr/include $LFS/usr

```
#### 5.5 Glibc-2.37
main C library,

```
$ ln -sfv ../lib/ld-linux-x86-64.so.2 #LFS/lib64

patch -p1 < ../xx.patch file,

../configure  \
    --prefix=/usr \
    --host=$LFS_TGT \
    --build=$(../scripts/config.guess) \
    --enable-kernel=3.2 \
    --with-headers=$LFS/usr/include \
    libc_cv_slibdir=/usr/lib

make DESTDIR=$LFS install
sed '/RTLDLIST=/s@/usr@@g' -i $LFS/usr/bin/ldd

$LFS/tools/libexec/gcc/$LFS_TGT/12.2.0/install-tools/mkheaders
```

#### 5.6 Libstdc++ from GCC-12.2.0

### chapters 7-10, /mnt/lfs partition,


