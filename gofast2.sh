#!/usr/bin/env bash
set -euo pipefail

# Configuration
TARGET_TRIPLE="x86_64-linux-llvm"
JOBS=$(nproc)

# Directories
HOME_DIR="$HOME"
WORK_DIR="${HOME_DIR}/build"
SRC_DIR="${WORK_DIR}/src"
SYSROOT_DIR="${WORK_DIR}/sysroot"
STAGE1_DIR="${WORK_DIR}/stage1"
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

# Create directories
mkdir -p "${SRC_DIR}" "${SYSROOT_DIR}" "${STAGE1_DIR}"
mkdir -p "${SYSROOT_DIR}/usr/include" "${SYSROOT_DIR}/usr/lib" "${SYSROOT_DIR}/lib"

# Clone repositories
cd "${SRC_DIR}"
if [ ! -d "llvm-project" ]; then
    git clone --depth 1 -c http.sslVerify=false https://github.com/llvm/llvm-project.git
fi

if [ ! -d "linux" ]; then
    git clone --depth 1 -c http.sslVerify=false https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git
fi

# Stage 1: Build clang with host compiler
mkdir -p "${WORK_DIR}/stage1-build"
cd "${WORK_DIR}/stage1-build"
cmake -G Ninja "${SRC_DIR}/llvm-project/llvm" \
    -C "${SCRIPT_DIR}/stage1.cmake" \
    -DCMAKE_INSTALL_PREFIX="${STAGE1_DIR}" \
    -DCMAKE_BUILD_TYPE=MinSizeRel \
    -DLLVM_PARALLEL_COMPILE_JOBS=${JOBS}
ninja
ninja install-distribution-stripped

if [ ! -f "${STAGE1_DIR}/bin/libc-hdrgen" ]; then
    cp "${WORK_DIR}/stage1-build/bin/libc-hdrgen" "${STAGE1_DIR}/bin/"
fi

# Install kernel headers
cd "${SRC_DIR}/linux"
make headers_install INSTALL_HDR_PATH="${SYSROOT_DIR}"

# Build runtime libraries
mkdir -p "${WORK_DIR}/runtime-build"
cd "${WORK_DIR}/runtime-build"
cmake -G Ninja "${SRC_DIR}/llvm-project/runtimes" \
    -C "${SCRIPT_DIR}/stage2.cmake" \
    -DCMAKE_SYSROOT="${SYSROOT_DIR}" \
    -DCMAKE_INSTALL_PREFIX="${SYSROOT_DIR}/usr" \
    -DCMAKE_C_COMPILER="${STAGE1_DIR}/bin/clang" \
    -DCMAKE_CXX_COMPILER="${STAGE1_DIR}/bin/clang++" \
    -DCMAKE_ASM_COMPILER="${STAGE1_DIR}/bin/clang" \
    -DCMAKE_AR="${STAGE1_DIR}/bin/llvm-ar" \
    -DCMAKE_RANLIB="${STAGE1_DIR}/bin/llvm-ranlib" \
    -DLLVM_TABLEGEN="${STAGE1_DIR}/bin/llvm-tblgen" \
    -DCLANG_TABLEGEN="${STAGE1_DIR}/bin/clang-tblgen" \
    -DLIBC_HDRGEN_EXE="${STAGE1_DIR}/bin/libc-hdrgen" \
    -DLLVM_ENABLE_RUNTIMES="libcxx;libc;libunwind;compiler-rt" \
    -DLIBCXX_TARGET_TRIPLE="${TARGET_TRIPLE}" \
    -DLIBCXXABI_TARGET_TRIPLE="${TARGET_TRIPLE}" \
    -DLIBUNWIND_TARGET_TRIPLE="${TARGET_TRIPLE}" \
    -DCOMPILER_RT_TARGET_TRIPLE="${TARGET_TRIPLE}" \
    -DCMAKE_CXX_FLAGS="-nostdinc++ -static"

# Install headers first
ninja install-libc-headers

# Install libraries
ninja install-libc-stripped install-cxx-stripped install-unwind-stripped

# Build Scudo allocator
cd "${SRC_DIR}/llvm-project/compiler-rt/lib"
"${STAGE1_DIR}/bin/clang++" \
    --sysroot="${SYSROOT_DIR}" -fno-exceptions -fno-rtti \
    -std=c++17 -nostdinc++ -static -Os -c \
    -I scudo/standalone/include \
    scudo/standalone/*.cpp

"${STAGE1_DIR}/bin/llvm-ar" rs "${SYSROOT_DIR}/usr/lib/libc.a" *.o

# Build standalone compiler-rt
mkdir -p "${WORK_DIR}/compiler-rt-build"
cd "${WORK_DIR}/compiler-rt-build"
cmake -G Ninja "${SRC_DIR}/llvm-project/compiler-rt" \
    -C "${SCRIPT_DIR}/stage2.cmake" \
    -DCMAKE_SYSROOT="${SYSROOT_DIR}" \
    -DCMAKE_INSTALL_PREFIX="${SYSROOT_DIR}/usr" \
    -DCMAKE_C_COMPILER="${STAGE1_DIR}/bin/clang" \
    -DCMAKE_CXX_COMPILER="${STAGE1_DIR}/bin/clang++" \
    -DCMAKE_ASM_COMPILER="${STAGE1_DIR}/bin/clang" \
    -DCMAKE_AR="${STAGE1_DIR}/bin/llvm-ar" \
    -DCMAKE_RANLIB="${STAGE1_DIR}/bin/llvm-ranlib" \
    -DCOMPILER_RT_STANDALONE_BUILD=ON \
    -DCOMPILER_RT_DEFAULT_TARGET_ONLY=ON \
    -DCMAKE_C_COMPILER_TARGET="${TARGET_TRIPLE}" \
    -DCMAKE_CXX_COMPILER_TARGET="${TARGET_TRIPLE}" \
    -DCMAKE_C_COMPILER_WORKS=1 \
    -DCMAKE_CXX_COMPILER_WORKS=1
ninja install-compiler-rt-stripped

# Build final toolchain
mkdir -p "${WORK_DIR}/final-build"
cd "${WORK_DIR}/final-build"
cmake -G Ninja "${SRC_DIR}/llvm-project/llvm" \
    -C "${SCRIPT_DIR}/stage2.cmake" \
    -DCMAKE_SYSROOT="${SYSROOT_DIR}" \
    -DCMAKE_INSTALL_PREFIX="${HOME_DIR}/llvm-toolchain" \
    -DCMAKE_C_COMPILER="${STAGE1_DIR}/bin/clang" \
    -DCMAKE_CXX_COMPILER="${STAGE1_DIR}/bin/clang++" \
    -DCMAKE_ASM_COMPILER="${STAGE1_DIR}/bin/clang" \
    -DCMAKE_AR="${STAGE1_DIR}/bin/llvm-ar" \
    -DCMAKE_RANLIB="${STAGE1_DIR}/bin/llvm-ranlib" \
    -DLLVM_DEFAULT_TARGET_TRIPLE="${TARGET_TRIPLE}" \
    -DLLVM_TARGET_TRIPLE="${TARGET_TRIPLE}" \
    -DLLVM_TABLEGEN="${STAGE1_DIR}/bin/llvm-tblgen" \
    -DCLANG_TABLEGEN="${STAGE1_DIR}/bin/clang-tblgen" \
    -DCMAKE_CXX_FLAGS="-nostdinc++ -static -I${SYSROOT_DIR}/usr/include/c++/v1 -resource-dir=${SYSROOT_DIR}" \
    -DLLVM_PARALLEL_COMPILE_JOBS=${JOBS}
ninja
ninja install-distribution-stripped

echo "Build completed successfully"
echo "Toolchain installed to: ${HOME_DIR}/llvm-toolchain"