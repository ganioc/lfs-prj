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
    --enable-langauges=c,c++
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

```

无法生成可执行文件，实际上编译已经成功了。


### chapters 7-10, /mnt/lfs partition,


