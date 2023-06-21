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

进入gcc目录, libstdc++-v3, 生成一个新的build目录,

```
../libstdc++-v3/configure \
    --host=$LFS_TGT \
    --build=$(../config.guess) \
    --prefix=/usr \
    --disable-multilib \
    --disable-nls \
    --disable-libstdcxx-pch \
    --with-gxx-include-dir=/tools/$LFS_TGT/include/c++/12.2.0
```

### chap 6, Cross Compiling Temporary Tools
目前还是需要使用host上的工具,

#### 6.2 M4
a macro processor,

```
./configure --prefix=/usr \
    --host=$LFS_TGT \
    --build=$(build-aux/config.guess)
```

#### 6.3 Ncurses-6.4
terminal-independent handling of character screens.

```
pushd build
    ../configure
    make -C include
    make -C progs tic
popd

./configure --prefix=/usr \
--host=$LFS_TGT \
--build=$(./config.guess) \
--mandir=/usr/share/man \
--with-manpage-format=normal \
--with-shared \
--without-normal \
--with-cxx-shared \
--without-debug \
--without-ada \
--disable-stripping \
--enable-widec

```

#### 6.4 Bash-5.2
Bash shell,

```
./configure --prefix=/usr \
--build=$(sh support/config.guess) \
--host=$LFS_TGT \
--without-bash-malloc
```

#### 6.5 Coreutils-9.1
basic utility programs , for os, 

```
./configure --prefix=/usr \
--host=$LFS_TGT \
--build=$(build-aux/config.guess) \
--enable-install-program=hostname \
--enable-no-install-program=kill,uptime

```

#### 6.6 Diffutils-3.9
两个文件之间的差别

#### 6.7 File-5.44

```
../configure --disable-bzlib \
--disable-libseccomp \
--disable-xzlib \
--disable-zlib

./configure --prefix=/usr --host=$LFS_TGT --build=$(./config.guess)

make FILE_COMPILE=$(pwd)/build/src/file

```

#### 6.8 Findutils-4.9.0

```
./configure --prefix=/usr \
--localstatedir=/var/lib/locate \
--host=$LFS_TGT \
--build=$(build-aux/config.guess)
```

install-exec-am, install-data-am,

#### 6.9 Gawk-5.2.1
awk manipulating text files,

```
./configure --prefix=/usr \
--host=$LFS_TGT \
--build=$(build-aux/config.guess)
```
#### 6.10 Grep-3.8
查询文件内容,

```
./configure --prefix=/usr \
--host=$LFS_TGT
```

#### 6.11 Gzip-1.12
```
./configure --prefix=/usr --host=$LFS_TGT
```

#### 6.12 Make-4.4
```
sed -e '/ifdef SIGPIPE/,+2 d' \
-e '/undef FATAL_SIG/i FATAL_SIG (SIGPIPE);' \
-i src/main.c

./configure --prefix=/usr \
--without-guile \
--host=$LFS_TGT \
--build=$(build-aux/config.guess)
```
#### 6.13 patch-2.7.6

```
./configure --prefix=/usr \
--host=$LFS_TGT \
--build=$(build-aux/config.guess)
```

#### 6.14 Sed-4.9

#### 6.15 tar-1.34
```
./configure --prefix=/usr \
--host=$LFS_TGT \
--build=$(build-aux/config.guess)
```

#### 6.16 Xz-5.4.1

```
./configure --prefix=/usr \
--host=$LFS_TGT \
--build=$(build-aux/config.guess) \
--disable-static \
--docdir=/usr/share/doc/xz-5.4.1

```

#### 6.17 binutils-2.40
2nd round pass,需要重新解压!

```
sed '6009s/$add_dir//' -i ltmain.sh
../configure \
--prefix=/usr \
--build=$(../config.guess) \
--host=$LFS_TGT \
--disable-nls \
--enable-shared \
--enable-gprofng=no \
--disable-werror \
--enable-64-bit-bfd
```

#### 6.18 gcc-12.2 
2nd pass,

```
sed '/thread_header =/s/@.*@/gthr-posix.h/' \
-i libgcc/Makefile.in libstdc++-v3/include/Makefile.in

../configure \
--build=$(../config.guess) \
--host=$LFS_TGT \
--target=$LFS_TGT \
LDFLAGS_FOR_TARGET=-L$PWD/$LFS_TGT/libgcc \
--prefix=/usr \
--with-build-sysroot=$LFS \
--enable-default-pie \
--enable-default-ssp \
--disable-nls \
--disable-multilib \
--disable-libatomic \
--disable-libgomp \
--disable-libquadmath \
--disable-libssp \
--disable-libvtv \
--enable-languages=c,c++ 



```

### chapters 7-10, /mnt/lfs partition,

在chroot中编译临时性的工具,

#### 7.4 准备virtual kernel file systems
content resides in memory, no disk space used,

```
mkdir -pv {dev,proc,sys,run}
mount -v --bind /dev $LFS/dev
sudo mount -v --bind /dev/pts $LFS/dev/pts
sudo mount -vt proc proc $LFS/proc
sudo mount -vt sysfs sysfs $LFS/sys
sudo mount -vt tmpfs tmpfs $LFS/run
sudo mount -t tmpfs -o nosuid,nodev tmps $LFS/dev/shm

sudo chroot "$LFS" /usr/bin/env -i \
    HOME=/root    \
    TERM="$TERM"  \
    PS1='(lfs chroot) \u:\w\$ '  \
    PATH=/usr/bin:/usr/sbin \
    /bin/bash  --login

```

I have no name! 需要在chroot环境里面运行、安装,

```
mkdir -pv /{boot,home,mnt,opt,srv}
ls 
mkdir -pv /etc/{opt,sysconfig}
mkdir -pv /lib/firmware
mkdir -pv /media/{floppy,cdrom}
mkdir -pv /usr/{,local/}{include,src}
mkdir -pv /usr/local/{bin,lib,sbin}
mkdir -pv /usr/{,local/}share/{color,dict,doc,info,locale,man}
mkdir -pv /usr/{,local/}share/{misc,terminfo,zoneinfo}
mkdir -pv /usr/{,local/}share/man/man{1..8}
mkdir -pv /var/{cache,local,log,mail,opt,spool}
mkdir -pv /var/lib/{color,misc,locate}

ln -sfv /run /var/run
ln -sfv /run/lock /var/lock
install -dv -m 0750 /root
install -dv -m 1777 /tmp /var/tmp


```

#### 7.6 生成essential files and symlinks,
```
ln -sv /proc/self/mounts /etc/mtab

cat > /etc/passwd << "EOF"
root:x:0:0:root:/root:/bin/bash
bin:x:1:1:bin:/dev/null:/usr/bin/false
daemon:x:6:6:Daemon User:/dev/null:/usr/bin/false
messagebus:x:18:18:D-Bus Message Daemon User:/run/dbus:/usr/bin/false
uuidd:x:80:80:UUID Generation Daemon User:/dev/null:/usr/bin/false
nobody:x:65534:65534:Unprivileged User:/dev/null:/usr/bin/false
EOF

cat > /etc/group << "EOF"
root:x:0:
bin:x:1:daemon
sys:x:2:
kmem:x:3:
tape:x:4:
tty:x:5:
daemon:x:6:
floppy:x:7:
disk:x:8:
lp:x:9:
dialout:x:10:
audio:x:11:
video:x:12:
utmp:x:13:
usb:x:14:
cdrom:x:15:
adm:x:16:
messagebus:x:18:
input:x:24:
mail:x:34:
kvm:x:61:
uuidd:x:80:
wheel:x:97:
users:x:999:
nogroup:x:65534:
EOF

GID 0, root,
GID 1, bin,
GID 5, tty group, 
5, /etc/fstab for devpts filesystem, ,
65534 used for NFS,
nobody, nogroup, to avoid an unnamed ID,

# 添加一个临时用户tester,
echo "tester:x:101:101::/home/tester:/bin/bash" >> /etc/passwd
echo "tester:x:101:" >> /etc/group
install -o tester -d /home/tester

exec /usr/bin/bash --login

login, agetty, init程序, 使用一些日志log文件来记录信息,
touch /var/log/{btmp,lastlog,faillog,wtmp}
chgrp -v utmp /var/log/lastlog
chmod -v 664 /var/log/lastlog
chmod -v 600 /var/log/btmp




```



