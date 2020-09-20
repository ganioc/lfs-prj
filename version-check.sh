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
echo -e "\n 2. Checking Binutils"
if [ ${machine} = "Linux" ];
then
    echo -n "Binutils: "; ld --version | head -n1 | cut -d" " -f3-
else
    echo -n "Binutils:"; ld -v | head -n2
fi
echo -e "Done"







