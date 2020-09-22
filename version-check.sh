#!/bin/bash

# Judge if it's a Linux or Macos
unameOut="$(uname -s)"
case "${unameOut}" in
    Linux*)     machine=Linux;;
    Darwin*)    machine=Mac;;
    CYGWIN*)    machine=Cygwin;;
    MINGW*)     machine=MinGw;;
    *)          machine="UNKNOWN:${unameOut}"
esac

echo -e "HOST is: " ${machine}

#Simple script to list version numbers of critical development tools

echo -e "\n1. Checking bash"
export LC_ALL=C

bash --version | head -n1 | cut -d" " -f 2-4

if [ ${machine} = "Linux" ];
then
    echo "It is Linux"
    MYSH=$(readlink -f /bin/sh)
    echo "/bin/sh -> $MYSH"
    echo $MYSH | grep -q bash || echo "ERROR: /bin/sh does not point to bash"
    unset MYSH
else 
    echo "It is Macos"
    MYSH=$(/bin/sh --version)
    echo "/bin/sh --version"
    echo $MYSH | grep -q bash || echo "ERROR: /bin/sh is not bash"
    unset MYSH
fi

echo -e "Done"

## Binutils
echo -e "\n2. Checking Binutils"
if [ ${machine} = "Linux" ];
then
    echo -n "Binutils: "; ld --version | head -n1 | cut -d" " -f3-
else
    echo -n "Binutils:"; ld -v | head -n2
fi
echo -e "Done"

## Bison
echo -e "\n3. Checking Bison"
bison --version | head -n1
if [ ${machine} = "Linux" ];                                                          
then
    if [ -h /usr/bin/yacc ]; then
	echo "/usr/bin/yacc -> `readlink -f /usr/bin/yacc`";
    fi
else
    echo yacc is `/usr/bin/yacc --version | head -n1`
fi
echo -e "Done"

## bzip2
echo -e "\n4. Checking bzip2" 
bzip2 --version 2>&1 < /dev/null | head -n1 | cut -d" " -f1,6-
echo "Done"

## Coreutils-6.9
echo -e "\n5. Checking Coreutils 6.9"
if [ ${machine} = "Linux" ];                                                        
then
    echo -n "Coretuils: chown"; chown --version | head -n1|cut -d")" -f2
    diff --version | head -n1
    find --version | head -n1
    gawk --version | head -n1 
    if [ -h /usr/bin/awk ]; then
	echo "/usr/bin/awk -> `readlink -f /usr/bin/awk`";
    else
	echo "awk not found"
    fi

else
    # use gnu coreutils
    echo -n "Coretuils: gchown"; gchown --version | head -n1 | cut -d " " -f4
    diff --version | head -n1 || echo "Error: diff not found"
    echo $(which find) || echo "Error: find not found"
    gawk --version | head -n1
    if [ -h /usr/bin/awk ]; then
	echo "/usr/bin/awk -> `readlink -n /usr/bin/awk`";
    elif [ -x /usr/bin/awk ]; then
	echo awk is `/usr/bin/awk --version | head -n1`
    else
	echo "awk not found"
    fi
fi
echo "Done"

# gcc 6.2
echo -e "\n6. Checking GCC 6.2"
if [ ${machine} = "Linux" ];                                                        
then
    gcc --version | head -n1

else
    gcc --version | head -n1
fi
echo "Done"

# g++
echo -e "\n7. Checking g++ 6.2"
if [ ${machine} = "Linux" ];
then
    g++ --version | head -n1
else
    g++ --version | head -n1
fi
echo "Done"

# check glibc version,  ldd
echo -e "\n8. Checking ldd"
if [ ${machine} = "Linux" ];
then
    ldd --version | head -n1 | cut -d" " -f2-

else

    echo "No ldd on Macos, libc shoudl re-examined as a cross-compile lib"
fi
echo "Done"

# check grep version
echo -e "\n9. Checking grep"
grep --version | head -n1
echo "Done"

# check gzip
echo -e "\n10. Checking gzip"
gzip --version | head -n1
echo "Done"

# check os version
echo -e "\n11. Checking os"
if [ ${machine} = "Linux" ];
then
    cat /proc/version
else
    sw_vers
fi
echo "Done"

# check m4


