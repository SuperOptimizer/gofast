#!/usr/bin/env bash
set -euo pipefail

# Configuration
HOST_TRIPLE="x86_64-linux-musl"
TARGET_TRIPLE="x86_64-linux-llvm"
JOBS=$(nproc)

# Directories
HOME_DIR="$HOME"
WORK_DIR="${HOME_DIR}/build"
SRC_DIR="${WORK_DIR}/src"
SYSROOT_DIR="${WORK_DIR}/sysroot"
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

# Create directories
mkdir -p "${SRC_DIR}" "${SYSROOT_DIR}"
mkdir -p "${SYSROOT_DIR}/usr/include" "${SYSROOT_DIR}/usr/lib" "${SYSROOT_DIR}/lib"

# Clone repositories
cd "${SRC_DIR}"
if [ ! -d "llvm-project" ]; then
    git clone --depth 1 -c http.sslVerify=false https://github.com/SuperOptimizer/llvm-project.git
fi

if [ ! -d "linux" ]; then
    git clone --depth 1 -c http.sslVerify=false https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git
fi


# Install kernel headers
cd "${SRC_DIR}/linux"
make headers_install INSTALL_HDR_PATH="${SYSROOT_DIR}" SED="sed -r" || \
    make headers_install INSTALL_HDR_PATH="${SYSROOT_DIR}"

# Bootstrap cross build
mkdir -p "${WORK_DIR}/bootstrap-build"
cd "${WORK_DIR}/bootstrap-build"
cmake -G Ninja "${SRC_DIR}/llvm-project/llvm" \
    -C "${SCRIPT_DIR}/toolchain.cmake" \
    -DCMAKE_INSTALL_PREFIX="${HOME_DIR}/llvm-toolchain" \
    -DLLVM_ENABLE_PROJECTS="clang;lld" \
    -DLLVM_ENABLE_RUNTIMES="libc;libcxx;libunwind;compiler-rt;libcxxabi" \
    -DLLVM_LIBC_FULL_BUILD=ON \
    -DLLVM_RUNTIME_TARGETS="${TARGET_TRIPLE}" \
    -DCMAKE_BUILD_TYPE=MinSizeRel \
    -DLIBCXX_HAS_MUSL_LIBC=ON \
    -DLLVM_PARALLEL_COMPILE_JOBS=${JOBS}

# Build components
ninja libc libcxx libunwind compiler-rt
ninja install-distribution-stripped

echo "Build completed successfully"
echo "Toolchain installed to: ${HOME_DIR}/llvm-toolchain"