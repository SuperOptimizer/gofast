#!/usr/bin/env bash
set -euo pipefail
# Configuration
JOBS=$(nproc)
# Directories
HOME_DIR="$HOME"
WORK_DIR="${HOME_DIR}/build"
SRC_DIR="${HOME_DIR}/src"
SYSROOT_DIR="${HOME_DIR}/sysroot"
TOOLCHAIN_DIR="${HOME_DIR}/toolchain"
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

# Create necessary directories
mkdir -p "${SRC_DIR}" "${WORK_DIR}" "${SYSROOT_DIR}"

# Clone repositories
cd "${SRC_DIR}"
if [ ! -d "llvm-project" ]; then
    git clone --depth 1 -c http.sslVerify=false https://github.com/SuperOptimizer/llvm-project.git
fi


# Continue with the runtime build
mkdir -p "${WORK_DIR}/runtime-build"
cd "${WORK_DIR}/runtime-build"
cmake -G Ninja "${SRC_DIR}/llvm-project/llvm" \
  -DLLVM_ENABLE_RUNTIMES="libc;compiler-rt;libcxx;libcxxabi;libunwind" \
  -DLLVM_ENABLE_PROJECTS="clang;lld" \
  -DLLVM_CCACHE_BUILD=ON \
  -DLLVM_ENABLE_LLD=ON \
  -DCMAKE_C_COMPILER_LAUNCHER=ccache \
  -DCMAKE_CXX_COMPILER_LAUNCHER=ccache \
  -DCMAKE_C_COMPILER=clang-21 \
  -DCMAKE_CXX_COMPILER=clang++-21 \
  -DCMAKE_BUILD_TYPE=MinSizeRel \
  -DLIBUNWIND_ENABLE_SHARED=OFF \
  -DLIBUNWIND_ENABLE_STATIC=ON \
  -DCMAKE_INSTALL_PREFIX="${SYSROOT_DIR}" \
  -DCMAKE_C_FLAGS="-w -g0 -Oz -ffunction-sections -fdata-sections  " \
  -DCMAKE_CXX_FLAGS="-w -g0 -Oz -ffunction-sections -fdata-sections  " \
  -DCMAKE_EXE_LINKER_FLAGS="-w -g0 -Oz -Wl,--gc-sections -fuse-ld=lld   "
ninja
ninja install

mkdir -p "${WORK_DIR}/toolchain-build"
cd "${WORK_DIR}/toolchain-build"
cmake -G Ninja "${SRC_DIR}/llvm-project/llvm" \
  -DCMAKE_SYSROOT="${SYSROOT_DIR}" \
  -DLLVM_ENABLE_RUNTIMES="libc;compiler-rt;libcxx;libcxxabi;libunwind" \
  -DLLVM_ENABLE_PROJECTS="clang;lld" \
  -DLLVM_CCACHE_BUILD=ON \
  -DLLVM_ENABLE_LLVM_LIBC=ON \
  -DLLVM_ENABLE_LLD=ON \
  -DCMAKE_C_COMPILER_LAUNCHER=ccache \
  -DCMAKE_CXX_COMPILER_LAUNCHER=ccache \
  -DLLVM_ENABLE_LLD=ON \
  -DCMAKE_C_COMPILER="${SYSROOT_DIR}/bin/clang" \
  -DCMAKE_CXX_COMPILER="${SYSROOT_DIR}/bin/clang++" \
  -DCMAKE_BUILD_TYPE=MinSizeRel \
  -DCMAKE_INSTALL_PREFIX="${SYSROOT_DIR}" \
  -DCMAKE_C_FLAGS="-w -g0 -Oz -ffunction-sections -fdata-sections -unwind=libunwind --rtlib=compiler-rt  " \
  -DCMAKE_CXX_FLAGS="-w -g0 -Oz -ffunction-sections -fdata-sections -unwind=libunwind --rtlib=compiler-rt -stdlib=libc++  " \
  -DCMAKE_EXE_LINKER_FLAGS="-w -g0 -Oz -Wl,--gc-sections -lllvmlibc -unwind=libunwind --rtlib=compiler-rt -stdlib=libc++ -fuse-ld=lld  "
ninja
ninja install