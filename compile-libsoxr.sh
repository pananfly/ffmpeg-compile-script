#! /usr/bin/env bash

#set current path
UNI_BUILD_ROOT=`pwd`
#get param 1
FF_TARGET=$1

#error occur shutdown
set -e
#close show running history
set +x

FF_ACT_ARCH_DEFAULT="armv7a"
FF_ACT_ARCH_32="armv5 armv7a x86"
FF_ACT_ARCH_64="armv5 armv7a arm64 x86 x86_64"
FF_ACT_ARCHS_ALL=$FF_ACT_ARCH_64

echo_archs() {
echo "===================="
echo "[*] check archs"
echo "===================="
echo "FF_ALL_ARCHS = $FF_ACT_ARCHS_ALL"
echo "FF_ACT_ARCHS = $*"
echo ""
}

echo_usage() {
echo "Usage:"
echo "  $0 armv5|armv7a|arm64|x86|x86_64"
echo "  $0 all32"
echo "  $0 all|all64"
echo "  $0 clean"
echo "  $0 check"
echo "  $0 -h|-help"
exit 1
}

echo_nextstep_help() {
echo ""
echo "--------------------"
echo "[*] Finished"
echo "--------------------"
}

case $FF_TARGET in
    armv5|armv7a|arm64|x86|x86_64)
    echo_archs $FF_TARGET
    sh tools/do-compile-libsoxr.sh $FF_TARGET
    echo_nextstep_help
    ;;
    all32)
    echo_archs $FF_ACT_ARCH_32
    for ARCH in $FF_ACT_ARCH_32
    do
        sh tools/do-compile-libsoxr.sh $ARCH
    done
    echo_nextstep_help
    ;;
    all|all64)
    echo_archs $FF_ACT_ARCHS_ALL
for ARCH in $FF_ACT_ARCHS_ALL
    do
        sh tools/do-compile-libsoxr.sh $ARCH
    done
    echo_nextstep_help
    ;;
    clean)
    echo_archs $FF_ACT_ARCHS_ALL
    #cd - :return to last work dir
    rm -rf ./build/libsoxr-*
    ;;
    check)
    echo_archs $FF_ACT_ARCHS_ALL
    ;;
    *|-help|-h)
    echo_usage
    ;;
esac





