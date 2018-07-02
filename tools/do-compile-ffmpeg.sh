#! /usr/bin/env bash

echo "========================"
echo "[*] check env $1"
echo "========================"

set -e


FF_ARCH=$1
FF_VERSION=$2
FF_BUILD_OPT=$3
echo "FF_ARCH=$FF_ARCH"
echo "FF_VERSION=$FF_VERSION"
echo "FF_BUILD_OPT=$FF_BUILD_OPT"

#check arch is empty
if [ -z "$FF_ARCH" ]; then
    echo "Yout must specific an architecture 'armv5 , armv7a , arm64 , x86 , x86_64'."
    exit 1
fi

FF_BUILD_ROOT=`pwd`
FF_ANDROID_API=
FF_ANDROID_PLATFORM=

FF_BUILD_NAME=
FF_SOURCE=
FF_CROSS_PREFIX=
#x264
FF_DEP_X264_INC=
FF_DEP_X264_LIB=
#openssl
FF_DEP_OPENSSL_INC=
FF_DEP_OPENSSL_LIB=
#libsoxr
FF_DEP_LIBSOXR_INC=
FF_DEP_LIBSOXR_LIB=
#extra
FF_CFG_FLAGS=
FF_EXTRA_CFLAGS=
FF_EXTRA_LDFLAGS=
FF_DEP_LIBS=

FF_MODULE_DIRS="compat libavcodec libavfilter libavformat libavutil libswresample libswscale"
#FF_MODULE_DIRS="compat libavcodec libavdevice libavfilter libavformat libavresample libavutil libpostproc libswresample libswscale"
FF_ASEMBLE_SUB_DIRS=

echo ""
echo "========================"
echo "[*] make NDK standalone toolchain"
echo "========================"

. ./tools/do-detect-env.sh
FF_MAKE_TOOLCHAIN_FLAGS=$BUILD_MAKE_TOOLCHAIN_FLAGS
FF_MAKE_FLAGS=$BUILD_MAKE_FLAG
FF_GCC_VER=$BUILD_GCC_VER
FF_GCC_64_VER=$BUILD_GCC_64_VER

#build arch env define
FF_BUILD_NAME=ffmpeg-$FF_ARCH
FF_BUILD_NAME_OPENSSL=openssl-$FF_ARCH
FF_BUILD_NAME_X264=x264-$FF_ARCH
FF_BUILD_NAME_LIBSOXR=libsoxr-$FF_ARCH

if [ -z $FF_VERSION ]; then
    FF_SOURCE=$FF_BUILD_ROOT/ffmpeg
else
    FF_SOURCE=$FF_BUILD_ROOT/ffmpeg-$FF_VERSION
fi

case $BUILD_NDK_REL in
    10*|11*|12*|13*|14*)
        FF_ANDROID_API=9
    ;;
    *)
        FF_ANDROID_API=14
    ;;
esac

if [ "$FF_ARCH" = "armv7a" ]; then
    FF_CROSS_PREFIX=arm-linux-androideabi
    FF_TOOLCHAIN_NAME=${FF_CROSS_PREFIX}-${FF_GCC_VER}

    FF_CFG_FLAGS="$FF_CFG_FLAGS --arch=arm --cpu=cortex-a8 --enable-neon --enable-thumb"
    FF_EXTRA_CFLAGS="$FF_EXTRA_CFLAGS -march=armv7-a -mcpu=cortex-a8 -mfpu=vfpv3-d16 -mfloat-abi=softfp -mthumb"
    FF_EXTRA_LDFLAGS="$FF_EXTRA_LDFLAGS -Wl,--fix-cortex-a8"

    FF_ASEMBLE_SUB_DIRS="arm"

elif [ "$FF_ARCH" = "armv5" ]; then
    FF_CROSS_PREFIX=arm-linux-androideabi
    FF_TOOLCHAIN_NAME=${FF_CROSS_PREFIX}-${FF_GCC_VER}

    FF_CFG_FLAGS="$FF_CFG_FLAGS --arch=arm"
    FF_EXTRA_CFLAGS="$FF_EXTRA_CFLAGS -march=armv5te -mtune=arm9tdmi -msoft-float"
    FF_EXTRA_LDFLAGS="$FF_EXTRA_LDFLAGS"

    FF_ASEMBLE_SUB_DIRS="arm"

elif [ "$FF_ARCH" = "x86" ]; then
    FF_CROSS_PREFIX=i686-linux-android
    FF_TOOLCHAIN_NAME=x86-${FF_GCC_VER}

    FF_CFG_FLAGS="$FF_CFG_FLAGS --arch=x86 --cpu=i686 --enable-yasm"
    FF_EXTRA_CFLAGS="$FF_EXTRA_CFLAGS -march=atom -msse3 -ffast-math -mfpmath=sse"
    FF_EXTRA_LDFLAGS="$FF_EXTRA_LDFLAGS"

    FF_ASEMBLE_SUB_DIRS="x86"

elif [ "$FF_ARCH" = "x86_64" ]; then
    FF_ANDROID_API=21

    FF_CROSS_PREFIX=x86_64-linux-android
    FF_TOOLCHAIN_NAME=x86_64-${FF_GCC_64_VER}

    FF_CFG_FLAGS="$FF_CFG_FLAGS --arch=x86_64 --enable-yasm"
    FF_EXTRA_CFLAGS="$FF_EXTRA_CFLAGS"
    FF_EXTRA_LDFLAGS="$FF_EXTRA_LDFLAGS"

    FF_ASEMBLE_SUB_DIRS="x86"

elif [ "$FF_ARCH" = "arm64" ]; then
    FF_ANDROID_API=21

    FF_CROSS_PREFIX=aarch64-linux-android
    FF_TOOLCHAIN_NAME=${FF_CROSS_PREFIX}-${FF_GCC_64_VER}

    FF_CFG_FLAGS="$FF_CFG_FLAGS --arch=aarch64 --enable-yasm"
    FF_EXTRA_CFLAGS="$FF_EXTRA_CFLAGS"
    FF_EXTRA_LDFLAGS="$FF_EXTRA_LDFLAGS"

    FF_ASEMBLE_SUB_DIRS="aarch64 neon"

else
    echo "Unknow architecture $FF_ARCH"
    exit 1

fi

FF_ANDROID_PLATFORM=android-$FF_ANDROID_API

if [ ! -d $FF_SOURCE ]; then
    echo ""
    echo "!! ERROR"
    echo "!! Can not find FFmpeg directory for $FF_SOURCE"
    echo "Please download ffmpeg to build dir $FF_BUILD_ROOT and rerun 'compile-ffmpeg.sh'"
exit 1
fi

FF_TOOLCHAIN_PATH=$FF_BUILD_ROOT/build/$FF_BUILD_NAME/toolchain
FF_MAKE_TOOLCHAIN_FLAGS="$FF_MAKE_TOOLCHAIN_FLAGS --install-dir=$FF_TOOLCHAIN_PATH"
FF_SYSROOT=$FF_TOOLCHAIN_PATH/sysroot
FF_PREFIX=$FF_BUILD_ROOT/build/$FF_BUILD_NAME/output
#x264
FF_DEP_X264_INC=$FF_BUILD_ROOT/build/$FF_BUILD_NAME_X264/output/include
FF_DEP_X264_LIB=$FF_BUILD_ROOT/build/$FF_BUILD_NAME_X264/output/lib
#openssl
FF_DEP_OPENSSL_INC=$FF_BUILD_ROOT/build/$FF_BUILD_NAME_OPENSSL/output/include
FF_DEP_OPENSSL_LIB=$FF_BUILD_ROOT/build/$FF_BUILD_NAME_OPENSSL/output/lib
#libsoxr
FF_DEP_LIBSOXR_INC=$FF_BUILD_ROOT/build/$FF_BUILD_NAME_LIBSOXR/output/include
FF_DEP_LIBSOXR_LIB=$FF_BUILD_ROOT/build/$FF_BUILD_NAME_LIBSOXR/output/lib

case "$UNAME_S" in
    CYGWIN_NT-*)
    FF_SYSROOT="$(cygpath -am $FF_SYSROOT)"
    FF_PREFIX="$(cygpath -am $FF_PREFIX)"
    ;;
esac

mkdir -p $FF_PREFIX

FF_TOOLCHAIN_TOUCH="$FF_TOOLCHAIN_PATH/touch"

if [ ! -f "$FF_TOOLCHAIN_TOUCH" ]; then
    $ANDROID_NDK/build/tools/make-standalone-toolchain.sh \
        $FF_MAKE_TOOLCHAIN_FLAGS \
        --platform=$FF_ANDROID_PLATFORM \
        --toolchain=$FF_TOOLCHAIN_NAME
    touch $FF_TOOLCHAIN_TOUCH;
fi

echo ""
echo "==========================="
echo "[*] check ffmpeg env"
echo "==========================="
export PATH=$FF_TOOLCHAIN_PATH/bin:$PATH
export CC="${FF_CROSS_PREFIX}-gcc"
export LD="${FF_CROSS_PREFIX}-ld"
export AR="${FF_CROSS_PREFIX}-ar"
export STRIP="${FF_CROSS_PREFIX}-strip"

FF_CFLAGS="-O3 -Wall -pipe \
    -ffast-math \
    -fstrict-aliasing \
    -Werror=strict-aliasing \
    -Wno-psabi -Wa,--noexecstack \
    -DANDROID -DNDEBUG"

export COMMON_FF_CFG_FLAGS=
. $FF_BUILD_ROOT/config/module.sh

if [ -f "${FF_DEP_OPENSSL_LIB}/libssl.a" ]; then
    FF_CFG_FLAGS="$FF_CFG_FLAGS --enable-openssl"
    FF_CFLAGS="$FF_CFLAGS -I${FF_DEP_OPENSSL_INC}"
    FF_DEP_LIBS="$FF_DEP_LIBS -L${FF_DEP_OPENSSL_LIB} -lssl -lcrypto"
    echo ""
    echo "====================="
    echo "Detected Openssl library"
    echo "====================="
fi

if [ -f "${FF_DEP_LIBSOXR_LIB}/libsoxr.a" ]; then
    FF_CFG_FLAGS="$FF_CFG_FLAGS --enable-libsoxr"
    FF_CFLAGS="$FF_CFLAGS -I${FF_DEP_LIBSOXR_INC}"
    FF_DEP_LIBS="$FF_DEP_LIBS -L${FF_DEP_LIBSOXR_LIB} -lsoxr"
    echo ""
    echo "====================="
    echo "Detected libsoxr library"
    echo "====================="
fi

if [ -f "${FF_DEP_X264_LIB}/libx264.a" ]; then
    FF_CFG_FLAGS="$FF_CFG_FLAGS --enable-libx264 --enable-encoder=libx264 --enable-gpl"
    FF_CFLAGS="$FF_CFLAGS -I${FF_DEP_X264_INC}"
    FF_DEP_LIBS="$FF_DEP_LIBS -L${FF_DEP_X264_LIB} -lx264"
export PKG_CONFIG_PATH="${FF_DEP_X264_LIB}/pkgconfig":$FF_PREFIX/lib/pkgconfig
    echo ""
    echo "====================="
    echo "Detected x264 library"
    echo "====================="
else
    FF_CFG_FLAGS="$FF_CFG_FLAGS --disable-gpl"
fi

FF_CFG_FLAGS="$FF_CFG_FLAGS $COMMON_FF_CFG_FLAGS"
#Standard options
FF_CFG_FLAGS="$FF_CFG_FLAGS --prefix=$FF_PREFIX"
#Advanced options
FF_CFG_FLAGS="$FF_CFG_FLAGS --cross-prefix=${FF_CROSS_PREFIX}-"
FF_CFG_FLAGS="$FF_CFG_FLAGS --enable-cross-compile"
FF_CFG_FLAGS="$FF_CFG_FLAGS --target-os=linux"
FF_CFG_FLAGS="$FF_CFG_FLAGS --enable-pic"

if [ "FF_ARCH" = "x86" ]; then
    FF_CFG_FLAGS="$FF_CFG_FLAGS --disable-asm"
else
    FF_CFG_FLAGS="$FF_CFG_FLAGS --enable-asm"
    FF_CFG_FLAGS="$FF_CFG_FLAGS --enable-inline-asm"
fi

case "$FF_BUILD_OPT" in
    debug)
        FF_CFG_FLAGS="$FF_CFG_FLAGS --enable-debug"
        FF_CFG_FLAGS="$FF_CFG_FLAGS --disable-small"
        FF_CFG_FLAGS="$FF_CFG_FLAGS --disable-optimizations"
    ;;
    *)
        FF_CFG_FLAGS="$FF_CFG_FLAGS --enable-debug"
        FF_CFG_FLAGS="$FF_CFG_FLAGS --enable-small"
        FF_CFG_FLAGS="$FF_CFG_FLAGS --enable-optimizations"
    ;;
esac

echo ""
echo "======================"
echo "[*] configure ffmpeg"
echo "======================"
cd $FF_SOURCE
which $CC

./configure $FF_CFG_FLAGS \
    --extra-cflags="$FF_CFLAGS $FF_EXTRA_CFLAGS" \
    --extra-ldflags="$FF_DEP_LIBS $FF_EXTRA_LDFLAGS" || exit 1

echo ""
echo "======================"
echo "[*] compile ffmpeg"
echo "======================"
cp config.* $FF_PREFIX
make clean
make $FF_MAKE_FLAGS > /dev/null
make install
mkdir -p $FF_PREFIX/include/libffmpeg
cp -f config.h $FF_PREFIX/include/libffmpeg/config.h

echo ""
echo "======================"
echo "[*] link ffmpeg"
echo "======================"
echo $FF_EXTRA_LDFLAGS

FF_C_OBJ_FILES=
FF_ASM_OBJ_FILES=
for MODULE_DIR in $FF_MODULE_DIRS
do
    C_OBJ_FILES="$MODULE_DIR/*.o"
    if ls $C_OBJ_FILES 1> /dev/null 2>&1; then
    echo "link $MODULE_DIR/*.o"
    FF_C_OBJ_FILES="$FF_C_OBJ_FILES $C_OBJ_FILES"
    fi
    for ASM_SUB_DIR in $FF_ASEMBLE_SUB_DIRS
    do
        ASM_OBJ_FILES="$MODULE_DIR/$ASM_SUB_DIR/*.o"
        if ls $ASM_OBJ_FILES 1> /dev/null 2>&1; then
            echo "link $MODULE_DIR/$ASM_SUB_DIR/*.o"
            FF_ASM_OBJ_FILES="$FF_ASM_OBJ_FILES $ASM_OBJ_FILES"
        fi
    done
done

$CC -lm -lz -shared --sysroot=$FF_SYSROOT -Wl,--no-undefined -Wl,-z,noexecstack $FF_EXTRA_LDFLAGS \
    -Wl,-soname,libffmpeg.so \
    $FF_C_OBJ_FILES \
    $FF_ASM_OBJ_FILES \
    $FF_DEP_LIBS \
    -o $FF_PREFIX/libffmpeg.so

mysedi()
{
    f=$1
    exp=$2
    n=`basename $f`
    cp $f /tmp/$n
    sed $exp /tmp/$n > $f
    rm /tmp/$n
}

echo ""
echo "======================"
echo "[*] create files for shared ffmpeg"
echo "======================"

rm -rf $FF_PREFIX/shared
mkdir -p $FF_PREFIX/shared/lib/pkgconfig
ln -s $FF_PREFIX/include $FF_PREFIX/shared/include
ln -s $FF_PREFIX/libffmpeg.sh $FF_PREFIX/shared/lib/libffmpeg.so
cp $FF_PREFIX/lib/pkgconfig/*.pc $FF_PREFIX/shared/lib/pkgconfig

for f in $FF_PREFIX/lib/pkgconfig/*.pc; do
    if [ ! -f $f ]; then
    continue
    fi
    cp $f $FF_PREFIX/shared/lib/pkgconfig
    f=$FF_PREFIX/shared/lib/pkgconfig/`basename $f`
    mysedi $f 's/\/output/\/output\/shared/g'
    mysedi $f 's/-lavcodec/-lffmpeg/g'
#mysedi $f 's/-lavdevice/-lffmpeg/g'
    mysedi $f 's/-lavfilter/-lffmpeg/g'
    mysedi $f 's/-lavformat/-lffmpeg/g'
#mysedi $f 's/-lavresample/-lffmpeg/g'
    mysedi $f 's/-lavutil/-lffmpeg/g'
#mysedi $f 's/-lpostproc/-lffmpeg/g'
    mysedi $f 's/-lswresample/-lffmpeg/g'
    mysedi $f 's/-lswscale/-lffmpeg/g'
done










