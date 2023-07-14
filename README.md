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


