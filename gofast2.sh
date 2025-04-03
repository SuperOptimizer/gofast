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

# Build tablegen tools first
mkdir -p "${WORK_DIR}/tablegen-build"
cd "${WORK_DIR}/tablegen-build"
cmake -G Ninja "${SRC_DIR}/llvm-project/llvm" \
    -DLLVM_BUILD_TOOLS=ON \
    -DCMAKE_BUILD_TYPE=Release \
    -DLLVM_TARGETS_TO_BUILD="X86" \
    -DLLVM_ENABLE_PROJECTS="clang"
ninja llvm-tblgen clang-tblgen

LLVM_TBLGEN="${WORK_DIR}/tablegen-build/bin/llvm-tblgen"
CLANG_TBLGEN="${WORK_DIR}/tablegen-build/bin/clang-tblgen"

# Build libc-hdrgen separately
mkdir -p "${WORK_DIR}/hdrgen-build"
cd "${WORK_DIR}/hdrgen-build"
cmake -G Ninja "${SRC_DIR}/llvm-project/libc" \
    -DCMAKE_BUILD_TYPE=Release \
    -DLLVM_TABLEGEN="${LLVM_TBLGEN}" \
    -DLIBC_HDRGEN_EXE_PATH="${WORK_DIR}/hdrgen-build/bin"
ninja libc-hdrgen

LIBC_HDRGEN="${WORK_DIR}/hdrgen-build/bin/libc-hdrgen"

# Install kernel headers
cd "${SRC_DIR}/linux"
make headers_install INSTALL_HDR_PATH="${SYSROOT_DIR}"

# Bootstrap cross build
mkdir -p "${WORK_DIR}/libc-build"
cd "${WORK_DIR}/libc-build"
cmake -G Ninja "${SRC_DIR}/llvm-project/llvm" \
    -C "${SCRIPT_DIR}/stage2.cmake" \
    -DCMAKE_SYSROOT="${SYSROOT_DIR}" \
    -DCMAKE_INSTALL_PREFIX="${HOME_DIR}/llvm-toolchain" \
    -DLLVM_TABLEGEN="${LLVM_TBLGEN}" \
    -DCLANG_TABLEGEN="${CLANG_TBLGEN}" \
    -DLIBC_HDRGEN_EXE="${LIBC_HDRGEN}" \
    -DLLVM_ENABLE_PROJECTS="clang;lld" \
    -DLLVM_ENABLE_RUNTIMES="libc;libcxx;libunwind;compiler-rt" \
    -DLLVM_LIBC_FULL_BUILD=ON \
    -DLLVM_RUNTIME_TARGETS="${TARGET_TRIPLE}" \
    -DLIBC_TARGET_TRIPLE="${TARGET_TRIPLE}" \
    -DLIBCXX_TARGET_TRIPLE="${TARGET_TRIPLE}" \
    -DLIBCXXABI_TARGET_TRIPLE="${TARGET_TRIPLE}" \
    -DLIBUNWIND_TARGET_TRIPLE="${TARGET_TRIPLE}" \
    -DCOMPILER_RT_TARGET_TRIPLE="${TARGET_TRIPLE}" \
    -DLLVM_PARALLEL_COMPILE_JOBS=${JOBS}

ninja clang
ninja libc libcxx libunwind compiler-rt
ninja install-distribution-stripped

echo "Build completed successfully"
echo "Toolchain installed to: ${HOME_DIR}/llvm-toolchain"