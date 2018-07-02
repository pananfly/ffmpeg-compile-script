#! /usr/bin/env bash

echo "========================"
echo "[*] check env $1"
echo "========================"

set -e

UNAME_S=$(uname -s)

FF_ARCH=$1
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
FF_CMAKE_API=
#extra
FF_CFG_FLAGS=
FF_CMAKE_EXTRA_FLAGS=

#build arch env define
FF_BUILD_NAME=libsoxr-$FF_ARCH
FF_SOURCE=$FF_BUILD_ROOT/soxr

. ./tools/do-detect-env.sh

FF_MAKE_TOOLCHAIN_FLAGS=$BUILD_MAKE_TOOLCHAIN_FLAGS
FF_MAKE_FLAGS=$BUILD_MAKE_FLAG
FF_GCC_VER=$BUILD_GCC_VER
FF_GCC_64_VER=$BUILD_GCC_64_VER

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
    FF_CMAKE_API="armeabi-v7a with NEON"
    FF_CMAKE_EXTRA_FLAGS="$FF_CMAKE_EXTRA_FLAGS -DHAVE_WORDS_BIGENDIAN_EXITCODE=1 -DWITH_SIMD=0"

elif [ "$FF_ARCH" = "armv5" ]; then
    FF_CROSS_PREFIX=arm-linux-androideabi
    FF_TOOLCHAIN_NAME=${FF_CROSS_PREFIX}-${FF_GCC_VER}
    FF_CMAKE_API="armeabi"
    FF_CMAKE_EXTRA_FLAGS="$FF_CMAKE_EXTRA_FLAGS -DHAVE_WORDS_BIGENDIAN_EXITCODE=1 -DWITH_SIMD=0"

elif [ "$FF_ARCH" = "x86" ]; then
    FF_CROSS_PREFIX=i686-linux-android
    FF_TOOLCHAIN_NAME=x86-${FF_GCC_VER}
    FF_CMAKE_API="x86"
    FF_CMAKE_EXTRA_FLAGS="$FF_CMAKE_EXTRA_FLAGS -DHAVE_WORDS_BIGENDIAN_EXITCODE=1"

elif [ "$FF_ARCH" = "x86_64" ]; then
    FF_ANDROID_API=21
    FF_CROSS_PREFIX=x86_64-linux-android
    FF_TOOLCHAIN_NAME=x86_64-${FF_GCC_64_VER}

    FF_CMAKE_API="x86_64"
    FF_CMAKE_EXTRA_FLAGS="$FF_CMAKE_EXTRA_FLAGS -DHAVE_WORDS_BIGENDIAN_EXITCODE=1"

elif [ "$FF_ARCH" = "arm64" ]; then
    FF_ANDROID_API=21
    FF_CROSS_PREFIX=aarch64-linux-android
    FF_TOOLCHAIN_NAME=${FF_CROSS_PREFIX}-${FF_GCC_64_VER}
    export NE10_ANDROID_TARGET_ARCH=aarch64
    FF_CMAKE_API="arm64-v8a"
    FF_CMAKE_EXTRA_FLAGS="$FF_CMAKE_EXTRA_FLAGS -DHAVE_WORDS_BIGENDIAN_EXITCODE=1"

else
    echo "Unknow architecture $FF_ARCH"
    exit 1

fi

FF_HOST=$FF_CROSS_PREFIX
FF_ANDROID_PLATFORM=android-$FF_ANDROID_API

if [ ! -d $FF_SOURCE ]; then
    echo ""
    echo "!! ERROR"
    echo "!! Can not find libsoxr directory for $FF_SOURCE"
    echo "Please download libsoxr to build dir $FF_BUILD_ROOT and rerun 'compile-libsoxr.sh'"
exit 1
fi

FF_PREFIX=$FF_BUILD_ROOT/build/$FF_BUILD_NAME/output
FF_CMKE_BUILD_DIR=$FF_BUILD_ROOT/build/$FF_BUILD_NAME/build

FF_TOOLCHAIN_PATH=$FF_BUILD_ROOT/build/$FF_BUILD_NAME/toolchain
FF_MAKE_TOOLCHAIN_FLAGS="$FF_MAKE_TOOLCHAIN_FLAGS --install-dir=$FF_TOOLCHAIN_PATH"

mkdir -p $FF_PREFIX
mkdir -p $FF_CMKE_BUILD_DIR

case $UNAME_S in
Darwin)
    if [ ! -d "${FF_BUILD_ROOT}/android-cmake" ]; then
        git clone https://github.com/taka-no-me/android-cmake.git
    fi
    FF_CFG_FLAGS="$FF_CFG_FLAGS -DCMAKE_TOOLCHAIN_FILE=${FF_BUILD_ROOT}/android-cmake/android.toolchain.cmake"
    FF_CFG_FLAGS="$FF_CFG_FLAGS -DANDROID_ABI=$FF_CMAKE_API"
    FF_CFG_FLAGS="$FF_CFG_FLAGS -DANDROID_NDK=$ANDROID_NDK"
;;
*)
    FF_TOOLCHAIN_TOUCH="$FF_TOOLCHAIN_PATH/touch"

    if [ ! -f "$FF_TOOLCHAIN_TOUCH" ]; then
    $ANDROID_NDK/build/tools/make-standalone-toolchain.sh \
        $FF_MAKE_TOOLCHAIN_FLAGS \
        --platform=$FF_ANDROID_PLATFORM \
        --toolchain=$FF_TOOLCHAIN_NAME
    touch $FF_TOOLCHAIN_TOUCH;
    fi
    FF_CFG_FLAGS="$FF_CFG_FLAGS -DCMAKE_C_COMPILER=${FF_TOOLCHAIN_PATH}/bin/${FF_CROSS_PREFIX}-gcc-${FF_GCC_VER}"
;;
esac

export COMMON_FF_CFG_FLAGS=

FF_CFG_FLAGS="$FF_CFG_FLAGS $COMMON_FF_CFG_FLAGS"
#FF_CFG_FLAGS="$FF_CFG_FLAGS -DANDROID_NDK=$ANDROID_NDK"
FF_CFG_FLAGS="$FF_CFG_FLAGS -DBUILD_EXAMPLES=0"
FF_CFG_FLAGS="$FF_CFG_FLAGS -DBUILD_LSR_TESTS=0"
FF_CFG_FLAGS="$FF_CFG_FLAGS -DBUILD_SHARED_LIBS=0"
FF_CFG_FLAGS="$FF_CFG_FLAGS -DBUILD_TESTS=0"
FF_CFG_FLAGS="$FF_CFG_FLAGS -DCMAKE_BUILD_TYPE=Release"
FF_CFG_FLAGS="$FF_CFG_FLAGS -DWITH_LSR_BINDINGS=0"
FF_CFG_FLAGS="$FF_CFG_FLAGS -DWITH_OPENMP=0"
FF_CFG_FLAGS="$FF_CFG_FLAGS -DWITH_PFFFT=0"
#FF_CFG_FLAGS="$FF_CFG_FLAGS -DCMAKE_C_COMPILER=${FF_TOOLCHAIN_PATH}/bin/${FF_CROSS_PREFIX}-gcc-${FF_GCC_VER}"
#FF_CFG_FLAGS="$FF_CFG_FLAGS -DANDROID_ABI=$FF_CMAKE_API"
FF_CFG_FLAGS="$FF_CFG_FLAGS -DCMAKE_INSTALL_PREFIX=$FF_PREFIX"
FF_CFG_FLAGS="$FF_CFG_FLAGS -DCMAKE_SYSTEM_NAME=Linux"


echo ""
echo "======================"
echo "[*] configure libsoxr"
echo "======================"

cd $FF_CMKE_BUILD_DIR
cmake $FF_CFG_FLAGS $FF_CMAKE_EXTRA_FLAGS $FF_SOURCE

echo ""
echo "======================"
echo "[*] compile libsoxr"
echo "======================"
make clean
make
make install
