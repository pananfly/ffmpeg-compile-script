#! /usr/bin/env bash

#export ANDROID_NDK=/Users/pananfly/Documents/android-ndk-r10e

set -e

#system name
UNAME_S=$(uname -s)
UNAME_M=$(uname -m)
echo "build on $UNAME_S"
echo "build on $UNAME_M"

if [ -z "$ANDROID_NDK" ]; then
    echo "You must define ANDROID_NDK before starting."
    exit 1
fi

export BUILD_GCC_VER=4.9
export BUILD_GCC_64_VER=4.9
export BUILD_MAKE_TOOLCHAIN_FLAGS=
export BUILD_MAKE_FLAG=
export BUILD_NDK_REL=$(grep -o '^r[0-9]*.*$' $ANDROID_NDK/RELEASE.TXT 2>/dev/null | sed 's/[[:space:]]*//g' | cut -b2-)
echo "BUILD_NDK_REL:"$BUILD_NDK_REL

case $BUILD_NDK_REL in
    10e*)
    if test -d ${ANDROID_NDK}/toolchains/arm-linux-androideabi-4.8
    then
        echo "NDKr$BUILD_NDK_REL dettected"
        case "$UNAME_S" in
            Darwin)
            export BUILD_MAKE_TOOLCHAIN_FLAGS="$BUILD_MAKE_TOOLCHAIN_FLAGS --system=darwin-$UNAME_M"
            ;;
            Linux)
            export BUILD_MAKE_TOOLCHAIN_FLAGS="$BUILD_MAKE_TOOLCHAIN_FLAGS --system=linux-$UNAME_M"
            ;;
            CYGWIN_NT-*)
            export BUILD_MAKE_TOOLCHAIN_FLAGS="$BUILD_MAKE_TOOLCHAIN_FLAGS --system=windows-$UNAME_M4"
            ;;
        esac
    else
        echo "Yout need the NDKr10e or later 1"
        exit 1
    fi
    ;;

    *)
    export BUILD_NDK_REL=$(grep -o '^Pkg\.Revision.*=[0-9]*.*$' $ANDROID_NDK/source.properties 2>/dev/null | sed 's/[[:space:]]*//g' | cut -d "=" -f 2)
    case $BUILD_NDK_REL in
        11*|12*|13*|14*|15*|16*)
            if test -d ${ANDROID_NDK}/toolchains/arm-linux-androideabi-${BUILD_GCC_VER}
            then
            echo "NDKr$BUILD_NDK_REL dettected"
            else
            echo "Yout need the NDKr10e or later 2"
            exit 1
            fi
        ;;
        *)
            echo "Yout need the NDKr10e or later 3"
            exit 1
        ;;
    esac
;;
esac


case "$UNAME_S" in
    Darwin)
    export BUILD_MAKE_FLAG=-j`sysctl -n machdep.cpu.thread_count`
    ;;
    Linux)
    export BUILD_MAKE_FLAG=-j`nproc`
    ;;
    CYGWIN_NT-*)
    BUILD_WIN_DIR="$(cygpath -am /tmp)"
    export TEMPDIR=$BUILD_WIN_DIR/
    echo "Cygwin temp prefix=$BUILD_WIN_DIR/"
    ;;
esac
