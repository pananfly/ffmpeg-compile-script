#! /usr/bin/env bash

echo "========================"
echo "[*] check env $1"
echo "========================"

set -e


FF_ARCH=$1
FF_VERSION=
echo "FF_ARCH=$FF_ARCH"

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
#extra
FF_CFG_FLAGS=
FF_PLATFORM_CFG_FLAGS=

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
FF_BUILD_NAME=openssl-$FF_ARCH
FF_SOURCE=$FF_BUILD_ROOT/openssl

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
    FF_PLATFORM_CFG_FLAGS="android-armv7"

elif [ "$FF_ARCH" = "armv5" ]; then
    FF_CROSS_PREFIX=arm-linux-androideabi
    FF_TOOLCHAIN_NAME=${FF_CROSS_PREFIX}-${FF_GCC_VER}
    FF_PLATFORM_CFG_FLAGS="android"

elif [ "$FF_ARCH" = "x86" ]; then
    FF_CROSS_PREFIX=i686-linux-android
    FF_TOOLCHAIN_NAME=x86-${FF_GCC_VER}
    FF_PLATFORM_CFG_FLAGS="android-x86"

    FF_CFG_FLAGS="$FF_CFG_FLAGS no-asm"

elif [ "$FF_ARCH" = "x86_64" ]; then
    FF_ANDROID_API=21

    FF_CROSS_PREFIX=x86_64-linux-android
    FF_TOOLCHAIN_NAME=x86_64-${FF_GCC_64_VER}
    FF_PLATFORM_CFG_FLAGS="linux-x86_64"

elif [ "$FF_ARCH" = "arm64" ]; then
    FF_ANDROID_API=21

    FF_CROSS_PREFIX=aarch64-linux-android
    FF_TOOLCHAIN_NAME=${FF_CROSS_PREFIX}-${FF_GCC_64_VER}
    FF_PLATFORM_CFG_FLAGS="linux-aarch64"

else
    echo "Unknow architecture $FF_ARCH"
    exit 1

fi

FF_ANDROID_PLATFORM=android-$FF_ANDROID_API

if [ ! -d $FF_SOURCE ]; then
    echo ""
    echo "!! ERROR"
    echo "!! Can not find openssl directory for $FF_SOURCE"
    echo "Please download openssl to build dir $FF_BUILD_ROOT and rerun 'compile-openssl.sh'"
exit 1
fi

FF_TOOLCHAIN_PATH=$FF_BUILD_ROOT/build/$FF_BUILD_NAME/toolchain
FF_MAKE_TOOLCHAIN_FLAGS="$FF_MAKE_TOOLCHAIN_FLAGS --install-dir=$FF_TOOLCHAIN_PATH"
FF_SYSROOT=$FF_TOOLCHAIN_PATH/sysroot
FF_PREFIX=$FF_BUILD_ROOT/build/$FF_BUILD_NAME/output

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
echo "[*] check openssl env"
echo "==========================="
export PATH=$FF_TOOLCHAIN_PATH/bin:$PATH

export COMMON_FF_CFG_FLAGS=

FF_CFG_FLAGS="$FF_CFG_FLAGS $COMMON_FF_CFG_FLAGSS"
FF_CFG_FLAGS="$FF_CFG_FLAGS $FF_PLATFORM_CFG_FLAGS"
#Standard options
FF_CFG_FLAGS="$FF_CFG_FLAGS --openssldir=$FF_PREFIX"
FF_CFG_FLAGS="$FF_CFG_FLAGS --prefix=$FF_PREFIX"
FF_CFG_FLAGS="$FF_CFG_FLAGS --sysroot=$FF_SYSROOT"
#Advanced options
FF_CFG_FLAGS="$FF_CFG_FLAGS --cross-compile-prefix=${FF_CROSS_PREFIX}-"
FF_CFG_FLAGS="$FF_CFG_FLAGS zlib-dynamic"
FF_CFG_FLAGS="$FF_CFG_FLAGS no-shared"
#fix undefined reference to 'stdin' etc link:https://github.com/openssl/openssl/issues/3826
FF_CFG_FLAGS="$FF_CFG_FLAGS -D__ANDROID_API__=$FF_ANDROID_API"


echo ""
echo "======================"
echo "[*] configure opemssl"
echo "======================"

cd $FF_SOURCE
./Configure $FF_CFG_FLAGS || exit 1
make clean

echo ""
echo "======================"
echo "[*] compile openssl"
echo "======================"
make depend
make $FF_MAKE_FLAGS
make install_sw
