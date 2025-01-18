#!/usr/bin/env bash

set -o xtrace -o nounset -o pipefail -o errexit

make_args=""

if [[ "${CONDA_BUILD_CROSS_COMPILATION:-}" == "1" ]]; then
    CROSS_LDFLAGS=${LDFLAGS}
    CROSS_CC="${CC}"
    CROSS_LD="${LD}"

    LDFLAGS=${LDFLAGS//${PREFIX}/${BUILD_PREFIX}}
    CC=${CC//${CONDA_TOOLCHAIN_HOST}/${CONDA_TOOLCHAIN_BUILD}}
    LD="${LD//${CONDA_TOOLCHAIN_HOST}/${CONDA_TOOLCHAIN_BUILD}}"

    ./autogen.sh
    ./configure --prefix="${BUILD_PREFIX}"
    make -j ${CPU_COUNT}
    make install

    LDFLAGS="${CROSS_LDFLAGS}"
    CC=${CROSS_CC}
    LD=${CROSS_LD}

    make_args="GUILE_FOR_BUILD=${BUILD_PREFIX}/bin/guile"
fi

./autogen.sh
./configure --prefix="${PREFIX}"
make -j ${CPU_COUNT}
# make -j ${CPU_COUNT} check
make install
