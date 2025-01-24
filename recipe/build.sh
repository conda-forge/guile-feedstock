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
    make clean

    LDFLAGS="${CROSS_LDFLAGS}"
    CFLAGS="${CROSS_CFLAGS}"
    CPPFLAGS="${CROSS_CPPFLAGS}"
    CC=${CROSS_CC}
    LD=${CROSS_LD}
fi

export CPPFLAGS="${CPPFLAGS} -DHAVE_GC_IS_HEAP_PTR -DHAVE_GC_MOVE_DISAPPEARING_LINK"
./configure --prefix="${PREFIX}"
make --trace -j ${CPU_COUNT}
if [[ "${CONDA_BUILD_CROSS_COMPILATION:-}" != "1" || "${CROSSCOMPILING_EMULATOR:-}" != "" ]]; then
    # Skip some tests that don't work in CI
    sed -i '/tests\/00-socket.test/d' test-suite/Makefile
    sed -i '/tests\/filesys.test/d' test-suite/Makefile
    sed -i '/tests\/foreign.test/d' test-suite/Makefile
    sed -i '/tests\/ports.test/d' test-suite/Makefile
    sed -i '/tests\/posix.test/d' test-suite/Makefile
    sed -i '/tests\/suspendable-ports.test/d' test-suite/Makefile

    sed -i '/test-scm-to-latin1-string$(EXEEXT) test-scm-values$(EXEEXT)/d' test-suite/standalone/Makefile
    sed -i '/test-stack-overflow test-out-of-memory test-close-on-exec/d' test-suite/standalone/Makefile
    sed -i 's/test-foreign-object-c$(EXEEXT)//g' test-suite/standalone/Makefile
    sed -i 's/test-conversion$(EXEEXT)//g' test-suite/standalone/Makefile
    sed -i 's/test-smob-mark-race$(EXEEXT) \\/test-smob-mark-race$(EXEEXT)/g' test-suite/standalone/Makefile

    make --trace -j ${CPU_COUNT} check
fi
make install
