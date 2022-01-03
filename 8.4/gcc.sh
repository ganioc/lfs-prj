#!/bin/bash

for file in gcc/config/{linux,i386/linux{,64}}.h
do
    # add a suffix of .orig to filename
    cp -uv $file{,.orig}
    sed -e 's@/lib\(64\)\?\(32\)\?/ld@/tools&@g' \
	-e 's@/usr@/tools@g' $file.orig > $file
    echo '
#undef STANDARD_STARTFILE_PREFIX_1
#undef STANDARD_STARTFILE_PREFIX_2
#define STANDARD_STARTFILE_PREFIX_1 "/tools/lib/"
#define STANDARD_STARTFILE_PREFIX_2 ""' >> $file
    touch $file.orig
done

case $(uname -m) in
    x86_64)
	sed -e '/m64=/s/lib64/lib/' \
	    -i.orig gcc/config/i386/t-linux64
    ;;
esac


