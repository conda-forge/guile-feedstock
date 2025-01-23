#!/usr/bin/env bash

set -o xtrace -o nounset -o pipefail -o errexit

if [[ "${CONDA_BUILD_CROSS_COMPILATION:-}" == "1" ]]; then
    CROSS_LDFLAGS=${LDFLAGS}
    CROSS_CFLAGS=${CFLAGS}
    CROSS_CPPFLAGS=${CPPFLAGS}
    CROSS_CC="${CC}"
    CROSS_LD="${LD}"

    LDFLAGS=${LDFLAGS//${PREFIX}/${BUILD_PREFIX}}
    CFLAGS=${CFLAGS//${PREFIX}/${BUILD_PREFIX}}
    CPPFLAGS=${CPPFLAGS//${PREFIX}/${BUILD_PREFIX}}
    CC=${CC//${CONDA_TOOLCHAIN_HOST}/${CONDA_TOOLCHAIN_BUILD}}
    LD="${LD//${CONDA_TOOLCHAIN_HOST}/${CONDA_TOOLCHAIN_BUILD}}"

    ./configure --host=${BUILD} --prefix="${BUILD_PREFIX}" --with-bdw-gc=${BUILD_PREFIX}/lib/pkgconfig/bdw-gc.pc
    make --trace -j ${CPU_COUNT}
    make install

    LDFLAGS="${CROSS_LDFLAGS}"
    CFLAGS="${CROSS_CFLAGS}"
    CPPFLAGS="${CROSS_CPPFLAGS}"
    CC=${CROSS_CC}
    LD=${CROSS_LD}
fi

export CPPFLAGS="${CPPFLAGS} -DHAVE_GC_IS_HEAP_PTR -DHAVE_GC_MOVE_DISAPPEARING_LINK"
./configure --prefix="${PREFIX}"
make --trace -j ${CPU_COUNT}
# make --trace -j ${CPU_COUNT} check
make install
