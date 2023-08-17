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
export LFS=/media/ruff/compile
sudo mount -v --bind /dev $LFS/dev
sudo mount -v --bind /dev/pts $LFS/dev/pts
sudo mount -vt proc proc $LFS/proc
sudo mount -vt sysfs sysfs $LFS/sys
sudo mount -vt tmpfs tmpfs $LFS/run
sudo mount -vt tmpfs -o nosuid,nodev tmps $LFS/dev/shm

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

#### 7.7 Gettext 0.21.1
internationalization , localization,
这样可以使, programs, compiled with NLS, native language support, 输出信息, user's native language.

```
./configure --disable-shared
make
cp -v  gettext-tools/src/{msgfmt,msgmerge,xgettext} /usr/bin
```
#### 7.8 Bison-3.8.2
parser tenerator,

```
./configure --prefix=/usr \
    --docdir=/usr/share/doc/bison-3.8.2
```
#### 7.9 Perl-5.36.0
Practical Extraction and Report Language,

```
./Configure -des \
-Dprefix=/usr \
-Dvendorprefix=/usr \
-Dprivlib=/usr/lib/perl5/5.36/core_perl \
-Darchlib=/usr/lib/perl5/5.36/core_perl \
-Dsitelib=/usr/lib/perl5/5.36/site_perl \
-Dsitearch=/usr/lib/perl5/5.36/site_perl \
-Dvendorlib=/usr/lib/perl5/5.36/vendor_perl \
-Dvendorarch=/usr/lib/perl5/5.36/vendor_perl

make
make install
```

#### 7.10 Python-3.11.2,
python 3 package, python development environment, 

```
./configure --prefix=/usr \
    --enable-shared \
    --without-ensurepip
```

#### 7.11 Texinfo-7.0.2
programs for reading, wriging, converting info pages,

#### 7.12 Util-linux-2.38.1
miscellaneous utility programs, FHS建议使用/var/lib/hwclock目录，代替/etc目录, for adjtime文件,

```
./configure ADJTIME_PATH=/var/lib/hwclock/adjtime \
--libdir=/usr/lib \
--docdir=/usr/share/doc/util-linux-2.38.1 \
--disable-chfn-chsh \
--disable-login \
--disable-nologin \
--disable-su \
--disable-setpriv \
--disable-runuser \
--disable-pylibmount \
--disable-static \
--without-python \
runstatedir=/run

```

#### 7.13 cleaning up and saving the temporary system,
备份

```shell
$ sudo mountpoint -q $LFS/dev/shm && umount $LFS/dev/shm
sudo umount $LFS/dev/pts
umount $LFS/{sys,proc,run,dev}

tar -cJpf $HOME/lfs-temp-tools-11.3.tar.xz .

# 恢复
cd $LFS
rm -rf ./*
tar -xpf $HOME/lfs-temp-tools-11.3.tar.xz
```

### Building the LFS System,
安装基础的系统软件, 

包管理, Package Management,

需要设置环境变量, PATH, LD_LIBRARY_PATH, MANPATH, INFOPATH, CPPFLAGS, 包含库的路径, 

symlink style package management, 每个文件都symlinked into /usr hierarchy, 自动的symlinks creation, /usr/pkg目录下面, 

```
Stow,
Epkg,
Graft,
Depot,
./configure --prefix=/usr/pkg/libfoo/1.1,
make,
make DESTDIR=/usr/pkg/libfoo/1.1 install,

```

Creating Package Archives,

faked into a separate tree as previously described in the symlink style package management section. 

```
RPM, 
pkg-utils,
apt,
Portage,

```

配置文件,
```
/etc/hosts
/etc/fstab
/etc/passwd
/etc/group
/etc/shadow,
/etc/ld.so.conf,
/etc/sysconfig/rc.site,
/etc/sysconfig/network,
/etc/sysconfig/ifconfig.eth0,

```

#### 8.3 Man-pages-6.03,

2400 man pages, 描述C programming language functions, important device files, and significant configuration files,

```
make prefix=/usr install
```

#### 8.4 iana-Etc-20230202, 
提供了network services, protocols的数据, tcp/ip 服务的名称的映射,

#### 8.5 Glibc-2.37,
main C library, basic routines for allocating memory, searching directories, opening and closing files, 读写文件，字符串操作, pattern matching, arithemtic, 算术运算,

```shell
patch -Np1 -i ../glibc-2.37-fhs-1.patch
sed '/width -=/s/workend - string/number_length/' \
-i stdio-common/vfprintf-process-arg.c

echo "rootsbindir=/usr/sbin" > configparms

../configure --prefix=/usr \
    --disable-werror \
    --enable-kernel=3.2 \
    --enable-stack-protector=strong \
    --with-headers=/usr/include \
    libc_cv_slibdir=/usr/lib

touch /etc/ld.so.conf
sed '/test-installation/s@$(PERL)@echo not running@' -i ../Makefile

make check,
make install,
sed '/RTLDLIST=/s@/usr@@g' -i /usr/bin/ldd
cp -v ../nscd/nscd.conf /etc/nscd.conf
mkdir -pv /var/cache/nscd

# locales
mkdir -pv /usr/lib/locale
localedef -i POSIX -f UTF-8 C.UTF-8 2> /dev/null || true
localedef -i cs_CZ -f UTF-8 cs_CZ.UTF-8
localedef -i de_DE -f ISO-8859-1 de_DE
localedef -i de_DE@euro -f ISO-8859-15 de_DE@euro
localedef -i de_DE -f UTF-8 de_DE.UTF-8
localedef -i el_GR -f ISO-8859-7 el_GR
localedef -i en_GB -f ISO-8859-1 en_GB
localedef -i en_GB -f UTF-8 en_GB.UTF-8
localedef -i en_HK -f ISO-8859-1 en_HK
localedef -i en_PH -f ISO-8859-1 en_PH
localedef -i en_US -f ISO-8859-1 en_US
localedef -i en_US -f UTF-8 en_US.UTF-8
localedef -i es_ES -f ISO-8859-15 es_ES@euro
localedef -i es_MX -f ISO-8859-1 es_MX
localedef -i fa_IR -f UTF-8 fa_IR
localedef -i fr_FR -f ISO-8859-1 fr_FR
localedef -i fr_FR@euro -f ISO-8859-15 fr_FR@euro
localedef -i fr_FR -f UTF-8 fr_FR.UTF-8
localedef -i is_IS -f ISO-8859-1 is_IS
localedef -i is_IS -f UTF-8 is_IS.UTF-8
localedef -i it_IT -f ISO-8859-1 it_IT
localedef -i it_IT -f ISO-8859-15 it_IT@euro
localedef -i it_IT -f UTF-8 it_IT.UTF-8
localedef -i ja_JP -f EUC-JP ja_JP
localedef -i ja_JP -f SHIFT_JIS ja_JP.SJIS 2> /dev/null || true
localedef -i ja_JP -f UTF-8 ja_JP.UTF-8
localedef -i nl_NL@euro -f ISO-8859-15 nl_NL@euro
localedef -i ru_RU -f KOI8-R ru_RU.KOI8-R
localedef -i ru_RU -f UTF-8 ru_RU.UTF-8
localedef -i se_NO -f UTF-8 se_NO.UTF-8
localedef -i ta_IN -f UTF-8 ta_IN.UTF-8
localedef -i tr_TR -f UTF-8 tr_TR.UTF-8
localedef -i zh_CN -f GB18030 zh_CN.GB18030
localedef -i zh_HK -f BIG5-HKSCS zh_HK.BIG5-HKSCS
localedef -i zh_TW -f UTF-8 zh_TW.UTF-8


make localedata/install-locales
/etc/nsswitch.conf,
cat > /etc/nsswitch.conf << "EOF"
# Begin /etc/nsswitch.conf
passwd: files
group: files
shadow: files
hosts: files dns
networks: files
protocols: files
services: files
ethers: files
rpc: files
# End /etc/nsswitch.conf
EOF

# time zone data
tar -xf ../../tzdata2022g.tar.gz
ZONEINFO=/usr/share/zoneinfo
mkdir -pv $ZONEINFO/{posix,right}
for tz in etcetera southamerica northamerica europe africa antarctica asia australasia backward; do
zic -L /dev/null -d $ZONEINFO ${tz}
zic -L /dev/null -d $ZONEINFO/posix ${tz}
zic -L leapseconds -d $ZONEINFO/right ${tz}
done

cp -v zone.tab zone1970.tab iso3166.tab $ZONEINFO
zic -d $ZONEINFO -p America/New_York
unset ZONEINFO

tzselect ,
You can make this change permanent for yourself by appending the line
	TZ='Asia/Shanghai'; export TZ
to the file '.profile' in your home directory; then log out and log in again


# dynamic loader,
/lib/ld-linux.so.2,  search /usr/lib,
其它的地址
/usr/local/lib
/opt/lib,
cat > /etc/ld.so.conf << "EOF"
# Begin /etc/ld.so.conf
/usr/local/lib
/opt/lib
EOF

cat >> /etc/ld.so.conf << "EOF"
# Add an include directory
include /etc/ld.so.conf.d/*.conf
EOF
mkdir -pv /etc/ld.so.conf.d

mtrace
nscd,
pcprofiledump
pldd
sln
sotruss # traces shared library procedure calls of a specified command
sprof,
tzselect
xtrace, # traces the execution of a program by printing currently executed fucntion
    # trace communicaiotn between X11 client and server,
zdump, # timezone dumper
zic,   # time zone compiler


```
5000项测试, 


#### 8.6 zlib-1.2.13

#### 8.7 bzip2
bzip2, 比gzip性能要好,

```
sed -i 's@\(ln -s -f \)$(PREFIX)/bin/@\1@' Makefile

make -f Makefile-libbz2_so
make clean
make PREFIX=/usr install
cp -av libbz2.so.* /usr/lib
ln -sv libbz2.so.1.0.8 /usr/lib/libbz2.so
cp -v bzip2-shared /usr/bin/bzip2
for i in /usr/bin/{bzcat,bunzip2}; do
ln -sfv bzip2 $i
done

rm -fv /usr/lib/libbz2.a

```

#### 8.8 xz-5.4.1
lzma, xz 压缩格式, 

```
./configure --prefix=/usr
 \
--disable-static \
--docdir=/usr/share/doc/xz-5.4.1
```

#### 8.9 zstd-1.5.4
real time compression 算法, 

#### 8.10 file-5.44
determine the type of a given file or files

#### 8.11 readline-8.2
offers command line editing and history capabilities

```
sed -i '/MV.*old/d' Makefile.in
sed -i '/{OLDSUFF}/c:' support/shlib-install
patch -Np1 -i ../readline-8.2-upstream_fix-1.patch

./configure --prefix=/usr \
    --disable-static \
    --with-curses \
    --docdir=/usr/share/doc/readline-8.2

termcap library, curses library, 
make SHLIB_LIBS="-lncursesw"
make SHLIB_LIBS="-lncursesw" install
install -v -m644 doc/*.{ps,pdf,html,dvi} /usr/share/doc/readline-8.2

libhistory,
libreadline, 
```

#### 8.12 m4-1.4.19
macro processor,

#### 8.13 bc-6.2.4
arbitrary precision numeric processing language,

#### flex-2.6.4
```
./configure --prefix=/usr \
    --docdir=/usr/share/doc/flex-2.6.4 \
    --disable-static
ln -sv flex /usr/bin/lex
```

#### tcl-8.6.13
a robust general purpose scriptiong languages, tickle pronounced; running test suites for binutils, gcc and other packages,  Expect, and DejaGNU, 

```
SRCDIR=$(pwd)
cd unix
./configure --prefix=/usr \
    --mandir=/usr/share/man

make
sed -e "s|$SRCDIR/unix|/usr/lib|" \
-e "s|$SRCDIR|/usr/include|" \
-i tclConfig.sh

sed -e "s|$SRCDIR/unix/pkgs/tdbc1.1.5|/usr/lib/tdbc1.1.5|" \
-e "s|$SRCDIR/pkgs/tdbc1.1.5/generic|/usr/include|" \
-e "s|$SRCDIR/pkgs/tdbc1.1.5/library|/usr/lib/tcl8.6|" \
-e "s|$SRCDIR/pkgs/tdbc1.1.5|/usr/include|" \
-i pkgs/tdbc1.1.5/tdbcConfig.sh

sed -e "s|$SRCDIR/unix/pkgs/itcl4.2.3|/usr/lib/itcl4.2.3|" \
-e "s|$SRCDIR/pkgs/itcl4.2.3/generic|/usr/include|" \
-e "s|$SRCDIR/pkgs/itcl4.2.3|/usr/include|" \
-i pkgs/itcl4.2.3/itclConfig.sh

unset SRCDIR

chmod -v u+w /usr/lib/libtcl8.6.so
make install-private-headers
ln -sfv tclsh8.6 /usr/bin/tclsh
mv /usr/share/man/man3/{Thread,Tcl_Thread}.3



```

#### 8.16 expect-5.45.4
for automating, via scripted dialogues, interactive applications such as telnet, ftp, passwd, fsck, rlogin, tip, k可以用来测试这些应用, DejaGnu framework is written in Expect.

```
./configure --prefix=/usr \
    --with-tcl=/usr/lib \
    --enable-shared \
    --mandir=/usr/share/man \
    --with-tclinclude=/usr/include
make install
ln -svf expect5.45.4/libexpect5.45.4.so /usr/lib
```

#### 8.17 DejaGNU-1.6.3
For running test suites on GNU tools.

```
../configure --prefix=/usr
makeinfo --html --no-split -o doc/dejagnu.html ../doc/dejagnu.texi
makeinfo --plaintext -o doc/dejagnu.txt ../doc/dejagnu.texi
make install
install -v -dm755 /usr/share/doc/dejagnu-1.6.3
install -v -m644 doc/dejagnu.{html,txt} /usr/share/doc/dejagnu-1.6.3

dejagnu, DejaGNU auxiliary command launcher, 
runtest, wrapper script,
```

#### 8.18 binutils-2.40

```
expect -c "spawn ls"
../configure --prefix=/usr \
--sysconfdir=/etc \
--enable-gold \
--enable-ld=default \
--enable-plugins \
--enable-shared \
--disable-werror \
--enable-64-bit-bfd \
--with-system-zlib

make tooldir=/usr
make -k check
grep '^FAIL:' $(find -name '*.log')
make tooldir=/usr install

rm -fv /usr/lib/lib{bfd,ctf,ctf-nobfd,sframe,opcodes}.a
rm -fv /usr/share/man/man1/{gprofng,gp-*}.1
```

#### 8.19 GMP-6.2.1
math libraries, arbitrary precision arithmetic,

```
./configure --prefix=/usr \
--enable-cxx \
--disable-static \
--docdir=/usr/share/doc/gmp-6.2.1

make check 2>&1 | tee gmp-check-log
awk '/# PASS:/{total+=$3} ; END{print total}' gmp-check-log


```

#### 8.20 MPFR-4.2.0
multiple precision math,

```
sed -e 's/+01,234,567/+1,234,567 /' \
-e 's/13.10Pd/13Pd/' \
-i tests/tsprintf.c

./configure --prefix=/usr \
--disable-static \
--enable-thread-safe \
--docdir=/usr/share/doc/mpfr-4.2.0


```

#### 8.21 mpc-1.3.1
arithmetic of complex numbers with arbitrarily high precision and correct rounding of the result,

```
./configure --prefix=/usr \
--disable-static \
--docdir=/usr/share/doc/mpc-1.3.1


```

#### 8.22 attr-2.5.1
administer the extended attributes of filesystem objects

```
./configure --prefix=/usr \
--disable-static \
--sysconfdir=/etc \
--docdir=/usr/share/doc/attr-2.5.1

```

#### 8.23 acl-2.3.1
to administer Access Control lists, fined grained discretionary access rights for files and directoreis

```
./configure --prefix=/usr \
--disable-static \
--docdir=/usr/share/doc/acl-2.3.1


```

#### 8.24 libcap-2.67
user sapce interace to POSIX 1003.1e, 

```
sed -i '/install -m.*STA/d' libcap/Makefile
make prefix=/usr lib=lib
make prefix=/usr lib=lib install

```
#### 8.25 shadow-4.13
handling password in a secure way,

```shell
sed -i 's/groups$(EXEEXT) //' src/Makefile.in
find man -name Makefile.in -exec sed -i 's/groups\.1 / /' {} \;
find man -name Makefile.in -exec sed -i 's/getspnam\.3 / /' {} \;
find man -name Makefile.in -exec sed -i 's/passwd\.5 / /' {} \;

sed -e 's:#ENCRYPT_METHOD DES:ENCRYPT_METHOD SHA512:' \
-e 's@#\(SHA_CRYPT_..._ROUNDS 5000\)@\100@' \
-e 's:/var/spool/mail:/var/mail:' \
-e '/PATH=/{s@/sbin:@@;s@/bin:@@}' \
-i etc/login.defs

touch /usr/bin/passwd
./configure --sysconfdir=/etc \
--disable-static \
--with-group-name-max-length=32


make exec_prefix=/usr install
make -C man install-man

# enable shadowed passwords,
pwconv
grpconv
sed -i '/MAIL/s/yes/no/' /etc/default/useradd
passwd root, # Raspberry@2021



```

#### 8.26 GCC-12.2.0
支持7种编程语言,

```shell
sed -e '/m64=/s/lib64/lib/' -i.orig gcc/config/i386/t-linux64

../configure --prefix=/usr \
LD=ld \
--enable-languages=c,c++ \
--enable-default-pie \
--enable-default-ssp \
--disable-multilib \
--disable-bootstrap \
--with-system-zlib

PIE, position-independent executable,
ASLR, Address Space Layout Randomization,
SSP, Stack Smashing Protection,

make 
ulimit -s 32768 # increase stack size, 
# 使用tester来进行测试
chown -Rv tester .
su tester -c "PATH=$PATH make -k check"
../contrib/test_summary

chown -v -R root:root /usr/lib/gcc/$(gcc -dumpmachine)/12.2.0/include{,-fixed}
ln -svr /usr/bin/cpp /usr/lib
ln -sfv ../../libexec/gcc/$(gcc -dumpmachine)/12.2.0/liblto_plugin.so /usr/lib/bfd-plugins/

echo 'int main(){}' > dummy.c
cc dummy.c -v -Wl,--verbose &> dummy.log
readelf -l a.out | grep ': /lib'

grep -E -o '/usr/lib.*/S?crt[1in].*succeeded' dummy.log
grep -B4 '^ /usr/include' dummy.log
grep 'SEARCH.*/usr/lib' dummy.log |sed 's|; |\n|g'
grep "/lib.*/libc.so.6 " dummy.log
grep found dummy.log

mkdir -pv /usr/share/gdb/auto-load/usr/lib
mv -v /usr/lib/*gdb.py /usr/share/gdb/auto-load/usr/lib
```

LTO, Link Time Optimization,

#### 8.27 pkg-config-0.29.2

```shell
./configure --prefix=/usr \
--with-internal-glib \
--disable-host-tool \
--docdir=/usr/share/doc/pkg-config-0.29.2
```

#### 8.28 Ncurses-6.4

```
./configure --prefix=/usr \
--mandir=/usr/share/man \
--with-shared \
--without-debug \
--without-normal \
--with-cxx-shared \
--enable-pc-files \
--enable-widec \
--with-pkg-config-libdir=/usr/lib/pkgconfig

make DESTDIR=$PWD/dest install
install -vm755 dest/usr/lib/libncursesw.so.6.4 /usr/lib
rm -v dest/usr/lib/libncursesw.so.6.4
cp -av dest/* /

for lib in ncurses form panel menu ; do
    rm -vf /usr/lib/lib${lib}.so
    echo "INPUT(-l${lib}w)" > /usr/lib/lib${lib}.so
    ln -sfv ${lib}w.pc /usr/lib/pkgconfig/${lib}.pc
done


rm -vf /usr/lib/libcursesw.so
echo "INPUT(-lncursesw)" > /usr/lib/libcursesw.so
ln -sfv libncurses.so /usr/lib/libcurses.so

mkdir -pv /usr/share/doc/ncurses-6.4
cp -v -R doc/* /usr/share/doc/ncurses-6.4
```

#### 8.29 Sed-4.9

```
./configure --prefix=/usr

chown -Rv tester .
su tester -c "PATH=$PATH make check"

make install
install -d -m755 /usr/share/doc/sed-4.9
install -m644 doc/sed.html /usr/share/doc/sed-4.9

```

#### 8.30 psmisc-23.6
for displaying information about running processes,

```
fuser, report Process ID, PID, that use the given files or file systems
killall,
peekfd,
prtstat,
pslog,
pstree,
pstree.x11,

```

#### 8.31 Gettext=0.21.1
for internationalization and localizaiton,
allow programs to be compiled with NLS, native language Support, enabling them to output messages in the user's native language.

```shell
./configure --prefix=/usr \
--disable-static \
--docdir=/usr/share/doc/gettext-0.21.1

make
make check
make install
chmod -v 0755 /usr/lib/preloadable_libintl.so


```

#### 8.32 Bison-3.8.2
a parser generator, bison yacc liby

```shell
./configure --prefix=/usr --docdir=/usr/share/doc/bison-3.8.2

```

#### 8.33 grep-3.8

```shell
sed -i "s/echo/#echo/" src/egrep.sh

```
egrep, fgrep, grep,


#### bash-5.2.15
Bourne-Again Shell,


```shell
./configure --prefix=/usr \
--without-bash-malloc \
--with-installed-readline \
--docdir=/usr/share/doc/bash-5.2.15

make
chown -Rv tester .
su -s /usr/bin/expect tester << EOF
set timeout -1
spawn make tests
expect eof
lassign [wait] _ _ _ value
exit $value
EOF

make install
exec /usr/bin/bash --login


```
bash, bashbug,sh,


#### 8.35 libtool-2.4.7
GNU generic library support script,

```shell
make install
rm -fv /usr/lib/libltdl.a
```
libtool, libtoolize , libltdl,

#### gdbm-1.23
GNU Database Manager, using extensible hasing and works like the standard Unix dbm.
Storing key/data pairs, searching and retrieving the data by its key and deleting a key along with its data.

```shell
./configure --prefix=/usr \
--disable-static \
--enable-libgdbm-compat


```

gdbm_dump, gdbm_load, gdbmtool,

#### 8.37 gperf-3.1
generate a perfect hash function from a key set,

```shell
./configure --prefix=/usr --docdir=/usr/share/doc/gperf-3.1
```

#### 8.38 expat-2.5.0
a stream oriented C library for parsing XML,

```shell
./configure --prefix=/usr \
--disable-static \
--docdir=/usr/share/doc/expat-2.5.0
install -v -m644 doc/*.{html,css} /usr/share/doc/expat-2.5.0


```

xmlwf, libexpat, 

#### 8.39 inetutils-2.4
programs for basic networking,包含了ifconfig, dnsdomainname, ftp, hostname, ping, ping6, talk, telnet, tftp, traceroute,

```shell
./configure --prefix=/usr \
--bindir=/usr/bin \
--localstatedir=/var \
--disable-logger \
--disable-whois \
--disable-rcp \
--disable-rexec \
--disable-rlogin \
--disable-rsh \
--disable-servers


mv -v /usr/{,s}bin/ifconfig
```

logger program, pass messages to System Log Daemon,


#### 8.40 less-608
a text file viewer,

```shell
./configure --prefix=/usr --sysconfdir=/etc

```
less, lessecho, lesskey,

#### 8.41 perl-5.36.0

```shell
export BUILD_ZLIB=False
export BUILD_BZIP2=0

sh Configure -des \
-Dprefix=/usr \
-Dvendorprefix=/usr \
-Dprivlib=/usr/lib/perl5/5.36/core_perl \
-Darchlib=/usr/lib/perl5/5.36/core_perl \
-Dsitelib=/usr/lib/perl5/5.36/site_perl \
-Dsitearch=/usr/lib/perl5/5.36/site_perl \
-Dvendorlib=/usr/lib/perl5/5.36/vendor_perl \
-Dvendorarch=/usr/lib/perl5/5.36/vendor_perl \
-Dman1dir=/usr/share/man/man1 \
-Dman3dir=/usr/share/man/man3 \
-Dpager="/usr/bin/less -isR" \
-Duseshrplib \
-Dusethreads


```

#### 8.42 xml::parser-2.46
a perl interface to XML parser, expat,

XML::*.tar.gz


```shell
perl Makefile.PL

```
Expat, the Perl Expat interface,


#### 8.43 Intltool-0.51.0
internationalization tool used for extracting translatable strings from source files,

```shell
sed -i 's:\\\${:\\\$\\{:' intltool-update.in

make install
install -v -Dm644 doc/I18N-HOWTO /usr/share/doc/intltool-0.51.0/I18N-HOWTO
```
intltoolize,
intltool-extract,
intltool-merge,
intltool-perpare,
intltool-update,

#### 8.44 autoconf-2.71
produce shell scripts , automatically configure source code,


```shell
sed -e 's/SECONDS|/&SHLVL|/' \
-e '/BASH_ARGV=/a\
 /^SHLVL=/ d' \
-i.orig tests/local.at

./configure --prefix=/usr
make
make check
make install


```
autoconf, autoheader, autom4te, autoreconf, autoscan, 

autoupdate, ifnames,

#### automake-1.16.5
for generating Makefiles for use with Autoconf,

```shell
./configure --prefix=/usr --docdir=/usr/share/doc/automake-1.16.5
make
make -j4 check

```
aclocal, generate aclocal.m4 files based on contents of configure.in files,

automake, generate Makefile.in files from Makefile.am files, 

#### 8.46 OpenSSL-3.0.8
management tools, libraries relating to cryptograph. OpenSSH, email applications, web browsers, for accessing HTTPS sites.

```shell
./config --prefix=/usr \
--openssldir=/etc/ssl \
--libdir=lib \
shared \
zlib-dynamic

make
make test

sed -i '/INSTALL_LIBS/s/libcrypto.a libssl.a//' Makefile
make MANSUFFIX=ssl install

mv -v /usr/share/doc/openssl /usr/share/doc/openssl-3.0.8
cp -vfr doc/* /usr/share/doc/openssl-3.0.8


```
c_rehash, a Perl script , scans all files in a directory and adds symbolic links to their hash values. Obsolete, should be replaced by openssl rehash command.


openssl, a command line tool for using the various cryptography functions of the OpenSSL's crypto library from the shell. 

libcrypto.so, a wide range of cryptographic algorithms used in various Internet standards. SSL, TLS, S/MIME. used to implement OpenSSH, OpenPGP, and other cryptographic standards.


libssl.so, Transport Layer Security (TLS v1) protocol. It provides a rich API, documentation on which can be found by running man 7 ssl.

安装的目录: /etc/ssl, /usr/include/openssl, /usr/lib/engines, /usr/share/doc/openssl-3.0.8,

#### 8.47 Kmod-30
For loading kernel modules.


```shell
./configure --prefix=/usr \
--sysconfdir=/etc \
--with-openssl \
--with-xz \
--with-zstd \
--with-zlib
make
make install
for target in depmod insmod modinfo modprobe rmmod; do
ln -sfv ../bin/kmod /usr/sbin/$target
done
ln -sfv kmod /usr/bin/lsmod


```

depmod, 生成一个dependency file based on symbols it finds in the existing set of modules, 这个文件被modprobe用来自动加载所需的modules,

insmod, Installs a loadable module in the running kernel,

kmod,  Loads and unloads kernel modules,

lsmod,  Lists currently loaded modules,

modinfo,  Examine an object file associated with a kernel module and displays any information that it can glean

modprobe, Uses a dependency file, created by depmod, to automatically load relevant modules,

rmmod,  Unloads modules from the running kernel,

libkmod,  Used by other programs to load and unload kernel modules,


#### 8.48 Libelf from Elfutils-0.188,
handling ELF (Executable and Linkable Format) files,

```shell
./configure --prefix=/usr \
--disable-debuginfod \
--enable-libdebuginfod=dummy

make
make check

make -C libelf install
install -vm644 config/libelf.pc /usr/lib/pkgconfig
rm /usr/lib/libelf.a



```


#### 8.49 Libffi-3.4.4
提供portable, high level programming interface to various calling conventions, 允许programmer, call any function, specified by a call interface description at run time.

FFI, Foreign Function Interface,  允许用一种语言编写的程序来调用用另一种语言编写的程序。提供了一个桥梁, between an interpreter like Perl, Python, shared library subroutines written in C, or C++。

```shell
./configure --prefix=/usr \
--disable-static \
--with-gcc-arch=native

make
make check,
make install,



```

#### Python-3.11.2
包含了一个Python development environment, Useful for object-oriented programming. 

```shell
./configure --prefix=/usr \
--enable-shared \
--with-system-expat \
--with-system-ffi \
--enable-optimizations

make
make install

# To suppress the warnings, 
cat > /etc/pip.conf << EOF
[global]
root-user-action = ignore
disable-pip-version-check = true
EOF


# To install the documentation,
install -v -dm755 /usr/share/doc/python-3.11.2/html
tar --strip-components=1 \
--no-same-owner \
--no-same-permissions \
-C /usr/share/doc/python-3.11.2/html \
-xvf ../python-3.11.2-docs-html.tar.bz2

```

root user use pip3 command, to install Python 3 program and modules. conflict with recommendation.

2to3, idle3, pip3, pydoc3, python3, python3-config,

libpython3.11.so, libpython3.so

/usr/include/python3.11, /usr/lib/python3, /usr/share/doc/python-3.11.2,

#### Wheel-0.38.4
a Python library which is the reference implementation of the Python wheel packaging standard,

```shell
PYTHONPATH=src pip3 wheel -w dist --no-build-isolation --no-deps $PWD
pip3 install --no-index --find-links=dist wheel

```

wheel, a utility to unpack, pack, or convert wheel archives,

#### 8.52 Ninja-1.11.1
a small build system with a focus on speed

```shell
export NINJAJOBS=4
sed -i '/int Guess/a \
int j = 0;\
char* jobs = getenv( "NINJAJOBS" );\
if ( jobs != NULL ) j = atoi( jobs );\
if ( j > 0 ) return j;\
' src/ninja.cc

python3 configure.py --bootstrap

./ninja ninja_test
./ninja_test --gtest_filter=-SubprocessTest.SetWithLots

install -vm755 ninja /usr/bin/
install -vDm644 misc/bash-completion /usr/share/bash-completion/completions/ninja
install -vDm644 misc/zsh-completion /usr/share/zsh/site-functions/_ninja

```

#### 8.53 Meson-1.0.0
Open source build system, 

```shell 
pip3 wheel -w dist --no-build-isolation --no-deps $PWD
pip3 install --no-index --find-links dist meson
install -vDm644 data/shell-completions/bash/meson /usr/share/bash-completion/completions/meson
install -vDm644 data/shell-completions/zsh/_meson /usr/share/zsh/site-functions/_meson

```

#### 8.54 Coreutils-9.1
包含basic utility programs needed by every operating system,

```shell
patch -Np1 -i ../coreutils-9.1-i18n-1.patch

autoreconf -fiv
FORCE_UNSAFE_CONFIGURE=1 ./configure \
--prefix=/usr \
--enable-no-install-program=kill,uptime

make

make NON_ROOT_USERNAME=tester check-root
echo "dummy:x:102:tester" >> /etc/group
chown -Rv tester .
su tester -c "PATH=$PATH make RUN_EXPENSIVE_TESTS=yes check"

sed -i '/dummy/d' /etc/group
make install
mv -v /usr/bin/chroot /usr/sbin
mv -v /usr/share/man/man1/chroot.1 /usr/share/man/man8/chroot.8
sed -i 's/"1"/"8"/' /usr/share/man/man8/chroot.8

```

[, test command,
base32, base64, 数据的编解码, 
b2sum,BLAKE2(512-bit) checksums,
basename,
basenc, encodecs or decodes data using various algorithms
cat, 
chcon, changes security context for files and directories,
chgrp, changes the group ownership of files and directories,
chmod, 
chown,
chroot, run a comman dwith the specified directory as the / directory,
cksum, prints the Cyclic Reduncancy Check(CRC) checksum and the byte counts of each specified file, 
comm, Compares two sorted files, outputting in three columns the lines that are uniuqe and the lines that are common
cp, Copies files,
csplit,
cut,
date,
dd,
df,
dir,
dircolors,
dirname,
du, report the amount of disk space used by the current directory,
echo,
env,
expand,
expr,
factor,
false,
fmt,
fold,
groups,
head,
hostid,
id,
install,
join,
link,
ln,
logname,
ls,
md5sum,
mkdir
mkfifo,
mknod,
mktemp,
mv,
nice,
nl,
nohup,
nproc, number of processing units available to a process,
numfmt,
od, dump files in octal and other formats,
paste, merges the given files,
pathchk,
pinky,
pr,
printenv,
printf,
ptx, produces a permuted index 
pwd,
readlink,
realpath,
rm
rmdir,
runcon,
seq,
sha1sum,
sha224sum,
sha256sum,
sha384sum,
sha512sum,
shred,
shuf,
sleep,
sort,
split,
stat,
stdbuf,
stty,
sum,
sync,
tac, Concatenates the given files in reverse,
tail,
tee,
test,
timeout,
touch,
tr, translate, squeeze, deletes the given characters from standard input,
true,
truncate,
tsort,
tty,
uname,
unexpand,
uniq,
unlink,
users,
vdir, ls -l
wc,
who.
whoami,
yes,
libstdbuf, used by stdbuf, 

#### 8.55 Check-0.15.2
a unit testing framework for C,

```shell
./configure --prefix=/usr --disable-static
make
make check
make docdir=/usr/share/doc/check-0.15.2 install

```
checkmk, Awk script for generating C unit tests, for Check unit testing framework,

libcheck.so,

#### 8.56 Diffutils-3.9
show the differences between files or directories,

```shell
./configure --prefix=/usr
make
make check
make install

```
cmp,
diff,
diff3, compare 3 files line by line,
sdiff, merges 2 files and interactively outputs the results,


#### 8.57 Gawk-5.2.1
programs for manipulating text files,

```shell
sed -i 's/extras//' Makefile.in
./configure --prefix=/usr

make LN='ln -f' install
mkdir -pv
 /usr/share/doc/gawk-5.2.1
cp -v doc/{awkforai.txt,*.{eps,pdf,jpg}} /usr/share/doc/gawk-5.2.1

```
awk,
gawk,
gawk-5.2.1

#### 8.58 Findutils-4.9.0
programs to find files, 还会提供xargs program, to run a specified command on each file selected by a search,

```shell
case $(uname -m) in
i?86)
 TIME_T_32_BIT_OK=yes ./configure --prefix=/usr --localstatedir=/var/lib/locate ;;
x86_64) ./configure --prefix=/usr --localstatedir=/var/lib/locate ;;
esac

make

chown -Rv tester .
su tester -c "PATH=$PATH make check"

make install

```
find,
locate,
updatedb, 更新这个locate database, scans the entire file system, including other file systems that are currently mounted, unless told not to, puts every file name it finds into the database,
xargs, used to apply a given command to a list of files,

#### 8.59 Groff-1.22.4
programs for processing and formatting text and images, paper size, A4, letter, to the /etc/papersize 文件。

```shell
PAGE=A4 ./configure --prefix=/usr

make
make install

```

addftinfo, read a troff font file, add some additional font-metric information, used by the groff system,

afmtodit, create a font file, for use with groff and grops,

chem, Groff preprocessor, producint chemical structure diagrams,

eqn, compiles descriptions of equations embedded within troff input files into commands that are understood by troff,

eqn2graph,

gdiffmk, marks differences between groff/nroff/troff files,

glilypond, transform sheet music written in the lilypond language into groff language

gperl, preprocessor for groff

gpinyin, preprocessor for PinYin 

grap2graph, a grap program file into a cropped bitmap image,

grn, preprocessor for gremlin files,

grodvi, Tex dvi format

groff, front end to groff document formatting system, 


#### 8.60 Grub-2.06
UEFI support, boot lfs with UEFI, GRUB with UEFIsupport， 

```shell
unset {C,CPP,CXX,LD}FLAGS
patch -Np1 -i ../grub-2.06-upstream_fixes-1.patch
./configure --prefix=/usr \
--sysconfdir=/etc \
--disable-efiemu \
--disable-werror

make 
make install
mv -v /etc/bash_completion.d/grub /usr/share/bash-completion/completions


```
a lot of programs,

#### 8.61 gzip-1.12

```shell
./configure --prefix=/usr
make check
make install

```
gunzip, gzexe, gzip, uncompress, zcat, zcmp, zdiff, zegrep, zfgrep, zforce, zgrep, zless, zmore, znew,

#### iproute2-6.1.0
basic and advanced IPV4-based networking, 


```shell
sed -i /ARPD/d Makefile
rm -fv man/man8/arpd.8
make SBINDIR=/usr/sbin install
mkdir -pv /usr/share/doc/iproute2-6.1.0
cp -v COPYING README* /usr/share/doc/iproute2-6.1.0

ip link <device>, allows user to look at the state of devices,
ip addr, 
ip neighbor, 
ip rule ,
ip route,
ip tunnel,
ip maddr, multicast addresses,
ip mroute
ip monitor,

lnstat,
nstat,
routel
rtacct
rtmon
rtpr
rtstat
ss
tc

```

bridge, ctstat, genl, ifstat,  ip, 

#### 8.63 kbd-2.5.1
key-table files, console fonts, keyboard utilities,

```shell
patch -Np1 -i ../kbd-2.5.1-backspace-1.patch
sed -i '/RESIZECONS_PROGS=/s/yes/no/' configure
sed -i 's/resizecons.8 //' docs/man/man8/Makefile.in
./configure --prefix=/usr --disable-vlock
make
make check
make install
mkdir -pv /usr/share/doc/kbd-2.5.1
cp -R -v docs/doc/* /usr/share/doc/kbd-2.5.1
```

chvt,  deallocvt, dumpkeys, fgconsole, getkeycodes, kbdinfo, kbd_mode, kbdrate, loadkeys, loadunimap, mapscrn,  openvt, psfaddtable, psfgettable, psfstriptable, psfxtable, setfont, setkeycodes, setleds, setmetamode, setvtrgb, showconsolefont, showkey, unicode_start, unicode_stop

#### 8.64 libpipeline-1.5.7
for manipulating pipelines of subprocesses in a flexible and convenient way,

```shell
./configure --prefix=/usr
make
make check
make install

```

#### 8.65 make-4.4
```shell
sed -e '/ifdef SIGPIPE/,+2 d' \
-e '/undef FATAL_SIG/i FATAL_SIG (SIGPIPE);' \
-i src/main.c

./configure --prefix=/usr
```

#### 8.66 patch-2.7.6
applying a "patch" file created by the diff program,

```shell
./configure --prefix=/usr
```

#### 8.67 Tar-1.34
archive manipulation, tarballs, 

```shell
FORCE_UNSAFE_CONFIGURE=1 ./configure --prefix=/usr
make
make check
make install
make -C doc install-html docdir=/usr/share/doc/tar-1.34

```

#### texinfo-7.0.2
for reading, writing, converting info pages,

```shell
./configure --prefix=/usr


make install , 
make TEXMF=/usr/share/texmf install-tex

pushd /usr/share/info
    rm -v dir
    for f in *
        do install-info $f dir 2>/dev/null
    done
popd

```

info,  read info pages similar to man pages, go much deeper than just explaining all the available command line options, man bison, info bison,

install-info,

makeinfo,

pdftexi2dvi,

pod2texi,

texi2any,

texi2dvi,

texi2dvi,

texi2pdf,

texindex,

#### 8.69 vim-9.0.1273
text editor, similar to Emacs, Joe, Nano, 

```shell
echo '#define SYS_VIMRC_FILE "/etc/vimrc"' >> src/feature.h
./configure --prefix=/usr
chown -Rv tester .
su tester -c "LANG=en_US.UTF-8 make -j1 test" &> vim-test.log
make install

ln -sv vim /usr/bin/vi
for L in /usr/share/man/{,*/}man1/vim.1; do
    ln -sv vim.1 $(dirname $L)/vi.1
done

ln -sv ../vim/vim90/doc /usr/share/doc/vim-9.0.1273

# default configuration
cat > /etc/vimrc << "EOF"
" Begin /etc/vimrc
" Ensure defaults are set before customizing settings, not after
source $VIMRUNTIME/defaults.vim
let skip_defaults_vim=1
set nocompatible
set backspace=2
set mouse=
syntax on
if (&term == "xterm") || (&term == "putty")
set background=dark
endif
" End /etc/vimrc
EOF

vim -c ':options'

# spell-checking files, only for English language,
.spl, .sug files for your language,
/etc/vimrc,
set spelllang=en,ru
set spell



```

ex, start vim in ex mode,

rview, 

rvim, 

vi,

view,

vim,

vimdiff,

vimtutor,

xxd, creates a hex dump of the given file, 

#### 8.70 eudev-3.2.11
programs for dynamic creation of device nodes,

```shell
sed -i '/udevdir/a udev_dir=${udevdir}' src/udev/udev.pc.in
./configure --prefix=/usr \
--bindir=/usr/sbin \
--sysconfdir=/etc \
--enable-manpages \
--disable-static

make
mkdir -pv /usr/lib/udev/rules.d
mkdir -pv /etc/udev/rules.d
tar -xvf ../udev-lfs-20171102.tar.xz
make -f udev-lfs-20171102/Makefile.lfs install

# configuring eudev,
/etc/udev/hwdb.d
/usr/lib/udev/hwdb.d,
# compiled into a binary database /etc/udev/hwdb.bin,
udevadm hwdb --update

```

udevadm, udev administration tool, controls the udevd daemon, provide info from the Udev database, monitors uevents, waits for uevents to finish, tests Udev configuration, triggers uevents for a given device,

udevd, a daemon listens for uevents on the netlink socket, creates devices and runs the configured external programs in response to the uevents,

libudev,

/etc/udev,

#### man-db-2.11.2
Man-DB package contains programs for finding and viewing man pages,

```shell
./configure --prefix=/usr \
--docdir=/usr/share/doc/man-db-2.11.2 \
--sysconfdir=/etc \
--disable-setuid \
--enable-cache-owner=bin \
--with-browser=/usr/bin/lynx \
--with-vgrind=/usr/bin/vgrind \
--with-grap=/usr/bin/grap \
--with-systemdtmpfilesdir= \
--with-systemdsystemunitdir=


```

lynx, text-based web browser, 

vgrind, convert program sources to Groff input,

grap, for typesetting graphs in Groff documents,

/usr/share/man/<11>, 

accessdb, dumps the whatis database contents in human-readable form

apropos, 搜寻whatis database, display the short descriptions of system commands that contain a given string

catman, creates or updates the pre-formatted manual pages,

lexgrog, one-line summay information about a given manual page,

man,

man-recode, converts manual pages to another encoding,

mandb, creates or updates the whatis database

manpath, 

whatis

libman, libmandb, 


#### 8.72 procps-ng-4.0.2
procps-ng packages, for monitoring processes,

```shell
./configure --prefix=/usr \
--docdir=/usr/share/doc/procps-ng-4.0.2 \
--disable-static \
--disable-kill

```
kill will be installed from the Util-linux package??

free

pgrep, pidof, pkill,

pmap, report the memory map of the given process,

ps,

pwdx, current working directory of a process,

slabtop, detailed kernel slab cache info in real time,

sysctl, modifies kernel parameters at run time,

tload, print a graph of the current system load average,

uptime, 

vmstat, virtual memory statistics, info about processes, memory , paging, block I/O, traps, CPU activity,

w,

watch,

libproc-2,

#### 8.73 util-linux-2.38.1
utilities for handling file systems, consoles, partitions, messages,

```shell
./configure ADJTIME_PATH=/var/lib/hwclock/adjtime \
--bindir=/usr/bin \
--libdir=/usr/lib \
--sbindir=/usr/sbin \
--disable-chfn-chsh \
--disable-login \
--disable-nologin \
--disable-su \
--disable-setpriv \
--disable-runuser \
--disable-pylibmount \
--disable-static \
--without-python \
--without-systemd \
--without-systemdsystemunitdir \
--docdir=/usr/share/doc/util-linux-2.38.1

make

chown -Rv tester .
su tester -c "make -k check"
make install


```

addpart, 

agetty, open a tty port, prompts for a login name, invoke the login program,

blkdiscard, blkid, blkzone, 

blockdev, to call block device ioctls from the command line,

cal, 

cfdisk, manipulate the partition table of the given device,

chcpu, modifies the state of CPUs,

chmem, configure memory,

choom, display and adjust OOM-killer scores, determine which process to kill first when Linux is Out Of Memory,

chrt, manipulates real-time attributes of a process,

col, filter out reverse line feeds,

colcrt, filters nroff output for terminals lack some capabilities 

colrm, 

column, formats a given file into multi columns,

ctrlaltdel,  set the function of key combination,

delpart,

dmesg, dump the kernel boot messages,

eject, ejects removable media,

fallocate, preallocates space to a file,

fdisk, manipulates the partition table of the given device

fincore, counts pages of file contents in core,

findfs,

findmnt,

flock,

fsck,

fsck.cramfs,

fsck.minix

fsfreeze,  fstrim, 

getopt, 

hardlink, 

hexdump, 

hwclock,

i386, symbolic link to setarch, linux32, linux64, 

ionice, set the io scheduling class and priority for a program,

ipcmk, create various IPC resources,

ipcrm, removes the given Inter-Process Communication (IPC) resource

ipcs

irqtop, 

isosize, 

kill, 

last, users last logged in and out, searching through /var/log/wtmp file,

lastb, failed login attempts, /var/log/btmp,

ldattach, attach a line dscipline to a serial line,

logger, enters the given message into the system log,

look, 

losetup,, 

lsblk, lscpu, lsfd, lsof, opened files,

lsipc, 
lsirq,
lslocks,

lslogins, info about users, groups, system accounts,

lsmem, 

lsns, 

mcookie, generate magic cookies, 128 bit random hexadecimal numbers,

mesg,

mkfs, mkfs.bfs, mkfs.cramfs, mkfs.minix, mkswap, 

more

mount, mountpoint,

namei,  nsenter,

partx,

pivot_root, make the given file system the new root file system of the current process,

prlimit, print a process's resource limits,

readprofile, 

rename, renice

resizepart,

rev

rkfill, enabling and disabling wireless devices,

rtcwake, enter a system sleep state until the specified wakeup time,

script, 

scriptlive, re-runs session typescripts using timing information,

scriptreplay,

setarch

setsid, run the given program in a new session,

setterm,

sfdisk, disk partition table manipulator,

sulogin,

swaplabel,

swapoff, swapon, 

switch_root, 

taskset, set a process's CPU affinity,

uclampset, 

ul, 

umount,

uname26,

unshare,

utmpdump, 

uuidd, a daemon used by UUID library to generate time-based UUIDs,

uuidgen, uuidparse

wall,

wdctl, 

whereis,

wipefs, wipe a filesystem signature from a device

zramctl, setup and control zram, compressed ram disk devices,

libblkid, libfdisk, libmount, libsmartcols, libuuid,

#### 8.74 e2fsprogs1.47.0
handling ext2 file system, 也支持ext3, ext4 journaling file systems, 似乎还包含了debugfs的一些接口。

```shell
mkdir -v build
cd build

../configure --prefix=/usr \
--sysconfdir=/etc \
--enable-elf-shlibs \
--disable-libblkid \
--disable-libuuid \
--disable-uuidd \
--disable-fsck

make
make check
make install
rm -fv /usr/lib/{libcom_err,libe2p,libext2fs,libss}.a

gunzip -v /usr/share/info/libext2fs.info.gz
install-info --dir-file=/usr/share/info/dir /usr/share/info/libext2fs.info

makeinfo -o doc/com_err.info ../lib/et/com_err.texinfo
install -v -m644 doc/com_err.info /usr/share/info
install-info --dir-file=/usr/share/info/dir /usr/share/info/com_err.info

sed 's/metadata_csum_seed,//' -i /etc/mke2fs.conf


```

badblocks, 

chattr, 修改文件属性,

compile_et, with the com_err library,

debugfs, dumpe2fs, 

e2freefrag, e2fsck, e2image, e2label, e2mmpstatus, e2scrub, e2scrub_all, e2undo, e4crypt, e4defrag, filefrag, fsck.ext2, fsck.ext3, fsck.ext4, logsave, lsattr, mk_cmds, mke2fs, mkfs.ext2, mkfs.ext3, mkfs.ext4, mklost+found, 

resize2fs, to enlarge or shrink ext{2 3 4} file system,

tune2fs, adjust tunable file system parameters 

libcom_err, common error display routine

libe2p, by dumpe2fs, chattr, lsattr,

libext2fs, enable user-level programs to manipulate ext{234} file systems

libss, used by debugfs,

#### sysklogd-1.5.1
logging system messages, as those emitted by the kernel when unusual things happen,

```shell
sed -i '/Error loading kernel symbols/{n;n;d}' ksym_mod.c
sed -i 's/union wait/int/' syslogd.c
make
make BINDIR=/sbin install

cat > /etc/syslog.conf << "EOF"
# Begin /etc/syslog.conf
auth,authpriv.* -/var/log/auth.log
*.*;auth,authpriv.none -/var/log/sys.log
daemon.* -/var/log/daemon.log
kern.* -/var/log/kern.log
mail.* -/var/log/mail.log
user.* -/var/log/user.log
*.emerg *
# End /etc/syslog.conf
EOF

```

syslogd, system programs offer for logging, 

klogd, kernel messages, 

#### 8.76 sysvinit-3.06
Sysvinit package, for controlling the startup, running , shutdown of the system,

```shell
patch -Np1 -i ../sysvinit-3.06-consolidated-1.patch
make
make install
```

bootlogd, logs boot messages to a log file

fstab-decode, 

halt, 

init, 1st process to be started, when the kernel has initialized the hardware,

killall5, send a signal to all processes, 

poweroff, kernel to halt the system and switch off the computer

reboot

runlevel, report the previous and current run-level, /run/utmp,

shutdown, bring down the system in a secure way, signaling all processes and notifying all logged-in users

telint, tells init which run-level to change to

#### 8.77 About Debugging symbols,
most compiled with -g, 

```shell
strip --strip-unneeded 


```

valgrind,

gdb,

ELF loader, ld-linux-x86-64.so.2, ld-linux.so.2, 

### chap 9 System Configuration,
系统配置, process必须加载virtual, real file system, 初始化设备，检查文件系统的完整性，安装启动swap partitions or files, 设置系统时钟，bring up networking, start daemons, accomplish any custom tasks specified by the user. 保证tasks performed in the correct order, executed as quickly as possible.

#### System V
boot process, init, login, rc, 控制一系列的脚本,

```shell
/etc/inittab

# run levels
0, halt
1, Single user mode
2, User definable
3, Full multiuser mode
4, User definable
5, Full multiuser mode with display manager
6, reboot
```

缓慢, 不支持control groups, per-user fair share scheduling,

manual , static sequencing decisions,

#### LFS-Bootscripts-20230101
a set of scripts to start/stop the LFS system at bootup/shutdown,

```shell
make install,

/etc/rc.d
/etc/init.d # symbolic link
/etc/sysconfig
/lib/services,
/lib/lsb  # symbolic links

```
checkfs, cleanfs

console, functions, halt,

ifdown, ifup, 

localnet

modules, load kernel modules listed in /etc/sysconfig/modules, 

mountfs, mountvirtfs, such as: /proc, 

network, 

rc, master run-level script, 

reboot, 

sendsignals, make sure every process terminated before system reboots or halts,

setclock, 

ipv4-static, 

swap, enable, disable swap files and partitions,

sysclt,
sysklogd,

template, to create custom bootscripts for other daemons,

udev, prepare the /dev directory, starts the udev daemon

udev_retry, retries failed udev uevents, copies generated rule files form /run/udev to /etc/udev/rules.d

#### 9.3 Device and Module handling
device nodes, created under /dev, 不管真实的硬件设备是否存在, 

MAKEDEV script, 包含了一系列call to mknod, with relevant major, minor device numbers for every possible device that might exist, 

使用udev,只会生成被kernel检测到的设备, devtmpfs文件系统里, 

devfs, handles device detection, creation, naming, removed from the kernel in June 2006,

sysfs, provide info about system's hardware configuration to userspace processes,user space replacement

#### udev方案,
drivers, 编译进了内核，注册了它们的objects in sysfs, devtmpfs internally, detected by the kernel, 对于作为模块的驱动，注册发生在module load加载的时刻。/sys, file system 文件系统加载后, 驱动注册的数据可以被userspace process, udevd访问、处理, 

设备节点生成，设备文件，devtmpfs, mounted on /dev, 暴露给用户空间，with fixed name, permissions, and owner,

kernel发送uevent给udevd, /etc/udev/rules.d, /usr/lib/udev/rules.d, /run/udev/rules.d目录, udevd还会生成一些device node的链接文件, change its permissions, owner, group, 更改internal udevd database entry, 3个目录里的规则会一起合并，如果udevd没有找到设备的任何一条规则，则leave the permissions and ownership at whatever devtmpfs used initially,

模块加载, 设备驱动, 会有aliases, 通过modinfo查看, bus-specific identifiers of devices, /sbin/modprobe, modalias file in sysfs, loading all modules whose aliases match the string after wildcard expansion.

kernel自动加载network protocols module, filesystem NLS support on demand

处理热插拔设备, Hotpluggable/Dynamic Devices, USB, handled by udevd,

加载驱动module, 生成device的问题:

udev只会加载module, 拥有bus-specific alias, bus driver properly exports necessary aliases to sysfs, Linux-6.1.11, udev可以加载INPUT, IDE, PCI, USB, SCSI, SERIO, FIREWIRE devices,

/sys/bus, modalias file, 

```shell
/etc/modprobe.d/<**>.conf,
softdep snd-pcm post: snd-pcm-oss

/etc/modprobe.d/blacklist.conf file, 

/usr/lib/udev/devices, with appropirate major minor numbers, the static device node will be copied to /dev by udev,
```

udev handles uevents and loads modules in parallel, in an unpredictable order. Create your own rules that make symlinks with stable names based on some stable attributes of the device, 

Userspace implementation of devfs, 用户空间的设备文件系统,

sysfs 文件系统,

#### 管理设备
##### 网络设备, 
Udev, 根据Firmware/BIOS data or physical characteristics like bus, slot, MAC address. Intel network card will become eth0, while Realtek card become eth1. 

在新的命名方案里面, typical network device name , enp5s0, wlp3s0, 也可以使用传统的命名方案，或者定制的方案,

##### 命名方法,
disabling persistent naming on the kernel command line, restored by pass net.ifnames=0 on kernel command line. 对只使用一个ethernet device的设备比较合适。The command line is in the GRUB configuration file.

也可以通过udev rules来改变, 
```shell
bash /usr/lib/udev/init-net-rules.sh
/etc/udev/rules.d/
/usr/lib/udev/rules.d/

eno1,

wlp5s0,

# 查看
ip link 

```

by-path mode,  default for USB, FireWire devices, path_id,  /sys/block/hdd, 

by-id mode, default for IDE, SCSI devices, ata_id, scsi_id,  ID_SERIAL, ID_MODEL, ID_REVISION, ID_PATH,

Write rules to create symlinks to different usb devices. 


##### Network Interface Configuration 文件,

```shell
cd /etc/sysconfig/
cat > ifconfig.eth0 << "EOF"
ONBOOT=yes   # bring up the netwok interface card during system boot process
IFACE=eth0   # the interface name, 
SERVICE=ipv4-static  # method used for obtaining the IP address,
IP=192.168.0.97
GATEWAY=192.168.0.1
PREFIX=24
BROADCAST=192.168.0.255
EOF

```

##### /etc/resolv.conf File
获取DNS name resolution to resolve Internet Domain Names to IP address, 

```shell
/etc/resolv.conf 
cat > /etc/resolv.conf << "EOF"
# Begin /etc/resolv.conf
domain <Your Domain Name>
nameserver <IP address of your primary nameserver>
nameserver <IP address of your secondary nameserver>
# End /etc/resolv.conf
EOF

```

hostname, /etc/hostname

/etc/hosts文件, 

```shell
IP_address myhost.example.org aliases
Private Network Address Range Normal Prefix
10.0.0.1 - 10.255.255.254 8
172.x.0.1 - 172.x.255.254 16
192.168.y.1 - 192.168.y.254 24

cat > /etc/hosts << "EOF"
# Begin /etc/hosts
127.0.0.1 localhost.localdomain localhost
127.0.1.1 <FQDN> <HOSTNAME>
<192.168.1.1> <FQDN> <HOSTNAME> [alias1] [alias2 ...]
::1
 localhost ip6-localhost ip6-loopback
ff02::1
 ip6-allnodes
ff02::2
 ip6-allrouters
# End /etc/hosts
EOF
```
For certain programs to operate correctly.


### System V Bootscript Usage and Configuration
SysVinit, based on a series of run levels,这里没有使用systemd,

```shell
0: halt
1: single user mode
2: same as 3, reserved for customization
3: multi user mode with networking
4: otherwise same as 3
5: same as 4, with GUI login, like GNOME's gdm, LXDE's lxdm, 
6: reboot

# init program will read the initialization file /etc/inittab,
cat > /etc/inittab << "EOF"
# Begin /etc/inittab
id:3:initdefault:
si::sysinit:/etc/rc.d/init.d/rc S
l0:0:wait:/etc/rc.d/init.d/rc 0
l1:S1:wait:/etc/rc.d/init.d/rc 1
l2:2:wait:/etc/rc.d/init.d/rc 2
l3:3:wait:/etc/rc.d/init.d/rc 3
l4:4:wait:/etc/rc.d/init.d/rc 4
l5:5:wait:/etc/rc.d/init.d/rc 5
l6:6:wait:/etc/rc.d/init.d/rc 6
ca:12345:ctrlaltdel:/sbin/shutdown -t1 -a -r now
su:S06:once:/sbin/sulogin
s1:1:respawn:/sbin/sulogin
1:2345:respawn:/sbin/agetty --noclear tty1 9600
2:2345:respawn:/sbin/agetty tty2 9600
3:2345:respawn:/sbin/agetty tty3 9600
4:2345:respawn:/sbin/agetty tty4 9600
5:2345:respawn:/sbin/agetty tty5 9600
6:2345:respawn:/sbin/agetty tty6 9600
# End /etc/inittab
EOF


/lib/lsb/init-functions,
/etc/sysconfig/rc.site

/run/var/bootlog ,
/var/log/boot.log

所有的脚本在 /etc/rc.d/init.d/目录下面,

/etc/rc.d/init.d/udev initscript 启动udevd, triggers coldplug devices, wait for the rules to complete,
/sbin/hotplug, unsets the uevent handler from the default hotplug,
# udevd will listen on a netlink socket for uevents that kernel raises,

```

S, start a service, 

K, stop a service, 


#### System Clock,
setclock script, 从硬件时钟读取time, BIOS or CMOS clock, UTC, /etc/localtime file, hwclock, 

```shell
$ sudo hwclock --localtime --show
2023-08-17 07:14:35.312799+08:00

cat > /etc/sysconfig/clock << "EOF"
# Begin /etc/sysconfig/clock
UTC=1
# Set this to any options you might need to give to hwclock,
# such as machine hardware clock type for Alphas.
CLOCKPARAMS=
# End /etc/sysconfig/clock
EOF


```


#### Linux Console配置
console bootscript, setup the keyboard map, console font, console kernel log level,

```shell
/etc/sysconfig/rc.site, 

# 读取
/etc/sysconfig/console 

/usr/share/keymaps/,
/usr/share/consolefonts/


cat > /etc/sysconfig/console << "EOF"
# Begin /etc/sysconfig/console
KEYMAP="pl2"
FONT="lat2a-16 -m 8859-2"
# End /etc/sysconfig/console
EOF

cat > /etc/sysconfig/console << "EOF"
# Begin /etc/sysconfig/console
UNICODE="1"
KEYMAP="us"
FONT="lat1-16 -m 8859-1"
# End /etc/sysconfig/console
EOF

```

#### Creating Files at Boot,
放在 /etc/sysconfig/createfiles脚本里面,

/etc/sysconfig/rc.site文件,

```shell
# rc.site
# Optional parameters for boot scripts.
# Distro Information
# These values, if specified here, override the defaults
#DISTRO="Linux From Scratch" # The distro name
#DISTRO_CONTACT="lfs-dev@lists.linuxfromscratch.org" # Bug report address
#DISTRO_MINI="LFS" # Short name used in filenames for distro config
# Define custom colors used in messages printed to the screen
# Please consult `man console_codes` for more information
# under the "ECMA-48 Set Graphics Rendition" section
#
# Warning: when switching from a 8bit to a 9bit font,
# the linux console will reinterpret the bold (1;) to
# the top 256 glyphs of the 9bit font. This does
# not affect framebuffer consoles
# These values, if specified here, override the defaults
#BRACKET="\\033[1;34m" # Blue
#FAILURE="\\033[1;31m" # Red
#INFO="\\033[1;36m"
 # Cyan
#NORMAL="\\033[0;39m" # Grey
#SUCCESS="\\033[1;32m" # Green
#WARNING="\\033[1;33m" # Yellow
# Use a colored prefix
# These values, if specified here, override the defaults
#BMPREFIX="      "
#SUCCESS_PREFIX="${SUCCESS} * ${NORMAL} "
#FAILURE_PREFIX="${FAILURE}*****${NORMAL} "
#WARNING_PREFIX="${WARNING} *** ${NORMAL} "
# Manually set the right edge of message output (characters)
# Useful when resetting console font during boot to override

# automatic screen width detection
#COLUMNS=120
# Interactive startup
#IPROMPT="yes" # Whether to display the interactive boot prompt
#itime="3"
 # The amount of time (in seconds) to display the prompt
# The total length of the distro welcome string, without escape codes
#wlen=$(echo "Welcome to ${DISTRO}" | wc -c )
#welcome_message="Welcome to ${INFO}${DISTRO}${NORMAL}"
# The total length of the interactive string, without escape codes
#ilen=$(echo "Press 'I' to enter interactive startup" | wc -c )
#i_message="Press '${FAILURE}I${NORMAL}' to enter interactive startup"
# Set scripts to skip the file system check on reboot
#FASTBOOT=yes
# Skip reading from the console
#HEADLESS=yes
# Write out fsck progress if yes
#VERBOSE_FSCK=no
# Speed up boot without waiting for settle in udev
#OMIT_UDEV_SETTLE=y
# Speed up boot without waiting for settle in udev_retry
#OMIT_UDEV_RETRY_SETTLE=yes
# Skip cleaning /tmp if yes
#SKIPTMPCLEAN=no
# For setclock
#UTC=1
#CLOCKPARAMS=
# For consolelog (Note that the default, 7=debug, is noisy)
#LOGLEVEL=7
# For network
#HOSTNAME=mylfs
# Delay between TERM and KILL signals at shutdown
#KILLDELAY=3
# Optional sysklogd parameters
#SYSKLOGD_PARMS="-m 0"
# Console parameters
#UNICODE=1
#KEYMAP="de-latin1"
#KEYMAP_CORRECTIONS="euro2"
#FONT="lat0-16 -m 8859-15"
#LEGACY_CHARSET=
```

Boot and shutdown scripts,

#### Bash Shell Startup Files
/bin/login, reading /etc/passwd file, 

non-login shell, non-interactive shell usually present when a shell script is running, 

```shell
/etc/profile
~/.bash_profile,

locale,
locale -a # 显示Glibc支持的所有的locale, 

cat > /etc/profile << "EOF"
# Begin /etc/profile
export LANG=en_US.iso88591
# End /etc/profile
EOF


```

"C" (default), "en_US.utf8", 


/etc/inputrc 文件, # readline library的配置文件, translating keyboard inputs into specific actions, Readline is used by bash and most other shells as well as many other applications,

~/.inputrc文件, 

```shell
cat > /etc/inputrc << "EOF"
# Begin /etc/inputrc
# Modified by Chris Lynn <roryo@roryo.dynup.net>
# Allow the command prompt to wrap to the next line
set horizontal-scroll-mode Off
# Enable 8-bit input
set meta-flag On
set input-meta On
# Turns off 8th bit stripping
set convert-meta Off
# Keep the 8th bit for display
set output-meta On
# none, visible or audible
set bell-style none
# All of the following map the escape sequence of the value
# contained in the 1st argument to the readline specific functions
"\eOd": backward-word
"\eOc": forward-word
# for linux console
"\e[1~": beginning-of-line
"\e[4~": end-of-line
"\e[5~": beginning-of-history
"\e[6~": end-of-history
"\e[3~": delete-char
"\e[2~": quoted-insert
# for xterm
"\eOH": beginning-of-line
"\eOF": end-of-line
# for Konsole
"\e[H": beginning-of-line
"\e[F": end-of-line
# End /etc/inputrc
EOF

```

/etc/shells文件,
包含了一系列的login shells on the system, 

```shell
cat > /etc/shells << "EOF"
# Begin /etc/shells
/bin/sh
/bin/bash
# End /etc/shells
EOF
```


### chap 10, Making the LFS system bootable,
#### /etc/fstab文件,
加载的文件, kernel, GRUBbootloader, 可以选择用来启动, startup,

```shell
/dev/xxx /
/dev/yy  swap
proc   /proc
sysfs  /sys
devpts /dev/pts
tmpfs  /run
devtmpfs  /dev
tmpfs     /dev/shm


```

#### Linux-6.1.11
Building the kernel

```shell
make mrproper
make menuconfig,

# contents of Linux
config-6.1.11, # all the configuration selections for the kernel
vmlinuz-6.1.11-lfs-11.3, # kernel, detects and initializes all components of the computer's hardware, makes these components avaialble as a tree of files to the software, turns a single CPU into a multitasking machine capbale of urnning scores of programs seemingly at the same time

System.map-6.1.11,  # a list of addresses and symbols, map the entry points and addresses of all the functions and data structures in the kernel.


```

BLFS?  Beyond Linux From Scratch,


#### GRUB to setup the Boot Process
UEFI or GRUB, 

```shell
cd /tmp
grub-mkrescue --output=grub-img.iso
xorriso -as cdrecord -v dev=/dev/cdrw blank=as_needed grub-img.iso

# GRUB naming,
sda1, (hd0,1)
sdb3 (hd1,3)


# GRUB Configuration File
/boot/grub/grub.cfg,
cat > /boot/grub/grub.cfg << "EOF"
# Begin /boot/grub/grub.cfg
set default=0
set timeout=5
insmod ext2
set root=(hd0,2)
menuentry "GNU/Linux, Linux 6.1.11-lfs-11.3" {
linux
 /boot/vmlinuz-6.1.11-lfs-11.3 root=/dev/sda2 ro
}
EOF


```
Grub将数据卸载hard disk的第一个物理磁道, physical track, not part of any file system. 程序接下来会访问boot partition里的Grub modules, 模块, /boot/grub, 一个200MB的boot分区, just for boot information,

使用disk 的UUID, 

grub-mkconfig, 自动写一个configuration file,

/etc/grub.d/

### Chap 11 The End, 最终章,
```shell
/etc/lfs-release, file, 
cat > /etc/lsb-release << "EOF"
DISTRIB_ID="Linux From Scratch"
DISTRIB_RELEASE="11.3"
DISTRIB_CODENAME="<your name here>"
DISTRIB_DESCRIPTION="Linux From Scratch"
EOF

# Rebooting the System,
Install firmware needed if the kernel driver requires
# other configuration files
/etc/bashrc
/etc/dircolors
/etc/fstab
/etc/hosts
/etc/inputrc
/etc/profile
/etc/resolv.conf
/etc/vimrc
/root/.bash_profile
/root/.bashrc
/etc/sysconfig/ifconfig.eth0


logout
sudo umount -v $LFS/dev/pts
sudo mountpoint -q $LFS/dev/shm && umount $LFS/dev/shm
sudo umount -v $LFS/dev
sudo umount -v $LFS/run
sudo umount -v $LFS/proc
sudo umount -v $LFS/sys



```

system creation process,

#### What next?
Maintenance, 

LFSHints，

Mailing lists,

Linux Document Project, TLDP, 

Workstation graphical user environment, LXDE, XFCE, KDE, Gnome,  needs, Firefox browser, Thunderbird email client, libreOffice Office suite,


Server,






