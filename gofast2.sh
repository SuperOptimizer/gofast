#!/usr/bin/env bash
set -euo pipefail

# Configuration
TARGET_TRIPLE="x86_64-linux-llvm"
JOBS=$(nproc)

# Directories
HOME_DIR="$HOME"
WORK_DIR="${HOME_DIR}/build"
SRC_DIR="${HOME_DIR}/src"
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
    -DCMAKE_INSTALL_PREFIX="${HOME_DIR}/llvm-toolchain" \
    -DLLVM_LIBC_FULL_BUILD=ON \
    -DCMAKE_BUILD_TYPE=MinSizeRel \
    -DBUILD_SHARED_LIBS=OFF \
    -DCLANG_DEFAULT_CXX_STDLIB=libc++ \
    -DCLANG_DEFAULT_LINKER=lld \
    -DCLANG_DEFAULT_OBJCOPY=llvm-objcopy \
    -DCLANG_DEFAULT_RTLIB=compiler-rt \
    -DCLANG_DEFAULT_UNWINDLIB=libunwind \
    -DCLANG_PLUGIN_SUPPORT=OFF \
    -DCLANG_TARGET_TRIPLE="x86_64-linux-llvm" \
    -DCMAKE_AR=llvm-ar \
    -DCMAKE_ASM_COMPILER=clang \
    -DCMAKE_BUILD_TYPE=MinSizeRel \
    -DCMAKE_CXX_COMPILER=clang++ \
    -DCMAKE_CXX_VISIBILITY_PRESET=hidden \
    -DCMAKE_C_COMPILER=clang \
    -DCMAKE_C_VISIBILITY_PRESET=hidden \
    -DCMAKE_C_FLAGS="-static -march=native -Os -g0 " \
    -DCMAKE_CXX_FLAGS="-static -march=native -Os -g0 " \
    -DCMAKE_EXE_LINKER_FLAGS="-static" \
    -DCMAKE_HOST_TRIPLE="x86_64-linux-llvm" \
    -DCMAKE_INTERPROCEDURAL_OPTIMIZATION=ON \
    -DCMAKE_LINKER=lld \
    -DCMAKE_PLATFORM_NO_VERSIONED_SONAME=ON \
    -DCMAKE_RANLIB=llvm-ranlib \
    -DCMAKE_VISIBILITY_INLINES_HIDDEN=ON \
    -DCOMPILER_RT_BUILD_CRT=ON \
    -DCOMPILER_RT_BUILD_LIBFUZZER=OFF \
    -DCOMPILER_RT_BUILD_MEMPROF=OFF \
    -DCOMPILER_RT_BUILD_SANITIZERS=ON \
    -DCOMPILER_RT_BUILD_XRAY=OFF \
    -DCOMPILER_RT_ENABLE_EXCEPTIONS=OFF \
    -DCOMPILER_RT_ENABLE_PIC=OFF \
    -DCOMPILER_RT_ENABLE_SHARED=OFF \
    -DCOMPILER_RT_ENABLE_STATIC=ON \
    -DCOMPILER_RT_TARGET_TRIPLE="x86_64-linux-llvm" \
    -DCOMPILER_RT_USE_BUILTINS_LIBRARY=OFF \
    -DCOMPILER_RT_USE_COMPILER_RT=ON \
    -DLIBCXXABI_ENABLE_EXCEPTIONS=OFF \
    -DLIBCXXABI_ENABLE_PIC=OFF \
    -DLIBCXXABI_ENABLE_SHARED=OFF \
    -DLIBCXXABI_ENABLE_STATIC=ON \
    -DLIBCXXABI_ENABLE_STATIC_UNWINDER=ON \
    -DLIBCXXABI_HAS_GCC_S_LIB=OFF \
    -DLIBCXXABI_INSTALL_LIBRARY=ON \
    -DLIBCXXABI_TARGET_TRIPLE="x86_64-linux-llvm" \
    -DLIBCXXABI_USE_COMPILER_RT=ON \
    -DLIBCXXABI_USE_LLVM_UNWINDER=ON \
    -DLIBCXXABI_ENABLE_THREADS=OFF\
    -DLIBCXX_ABI_VERSION=2 \
    -DLIBCXX_ENABLE_EXCEPTIONS=OFF \
    -DLIBCXX_ENABLE_FILESYSTEM=OFF \
    -DLIBCXX_ENABLE_LOCALIZATION=OFF \
    -DLIBCXX_ENABLE_MONOTONIC_CLOCK=OFF \
    -DLIBCXX_ENABLE_PIC=OFF \
    -DLIBCXX_ENABLE_RANDOM_DEVICE=OFF \
    -DLIBCXX_ENABLE_SHARED=OFF \
    -DLIBCXX_ENABLE_STATIC=ON \
    -DLIBCXX_ENABLE_STATIC_ABI_LIBRARY=ON \
    -DLIBCXX_ENABLE_THREADS=OFF \
    -DLIBCXX_ENABLE_WIDE_CHARACTERS=OFF \
    -DLIBCXX_HARDENING_MODE="none" \
    -DLIBCXX_HAS_ATOMIC_LIB=OFF \
    -DLIBCXX_HAS_GCC_S_LIB=OFF \
    -DLIBCXX_INSTALL_LIBRARY=ON \
    -DLIBCXX_STATIC_SHARED=ON \
    -DLIBCXX_TARGET_TRIPLE="x86_64-linux-llvm" \
    -DLIBCXX_USE_COMPILER_RT=ON \
    -DLIBC_ENABLE_EXCEPTIONS=OFF \
    -DLIBC_ENABLE_SHARED=OFF \
    -DLIBC_ENABLE_STATIC=ON \
    -DLIBC_ENABLE_USE_BY_CLANG=ON \
    -DLIBC_TARGET_TRIPLE="x86_64-linux-llvm" \
    -DLIBC_USE_COMPILER_RT=ON \
    -DLIBUNWIND_ENABLE_EXCEPTIONS=OFF \
    -DLIBUNWIND_ENABLE_PIC=OFF \
    -DLIBUNWIND_ENABLE_SHARED=OFF \
    -DLIBUNWIND_ENABLE_STATIC=ON \
    -DLIBUNWIND_FORCE_UNWIND_TABLES=OFF \
    -DLIBUNWIND_HAS_GCC_S_LIB=OFF \
    -DLIBUNWIND_INSTALL_LIBRARY=ON \
    -DLIBUNWIND_TARGET_TRIPLE="x86_64-linux-llvm" \
    -DLIBUNWIND_USE_COMPILER_RT=ON \
    -DLLDB_TARGET_TRIPLE="x86_64-linux-llvm" \
    -DLLD_TARGET_TRIPLE="x86_64-linux-llvm" \
    -DLLVM_BUILD_TOOLS=ON \
    -DLLVM_DEFAULT_TARGET_TRIPLE="x86_64-linux-llvm" \
    -DLLVM_ENABLE_FFI=OFF \
    -DLLVM_ENABLE_LIBEDIT=OFF \
    -DLLVM_ENABLE_LIBXML2=OFF \
    -DLLVM_ENABLE_LTO=OFF \
    -DLLVM_ENABLE_PER_TARGET_RUNTIME_DIR=OFF \
    -DLLVM_ENABLE_PIC=OFF \
    -DLLVM_ENABLE_PROJECTS="clang;lld" \
    -DLLVM_ENABLE_RUNTIMES="compiler-rt;libcxx;libcxxabi;libunwind;libc" \
    -DLLVM_ENABLE_TERMINFO=OFF \
    -DLLVM_ENABLE_UNWIND_TABLES=OFF \
    -DLLVM_ENABLE_ZLIB=OFF \
    -DLLVM_HOST_TRIPLE="x86_64-linux-llvm" \
    -DLLVM_INCLUDE_BENCHMARKS=OFF \
    -DLLVM_INCLUDE_EXAMPLES=OFF \
    -DLLVM_LIBC_INCLUDE_SCUDO=ON \
    -DCOMPILER_RT_BUILD_SCUDO_STANDALONE_WITH_LLVM_LIBC=ON \
    -DCOMPILER_RT_BUILD_GWP_ASAN=OFF \
    -DCOMPILER_RT_SCUDO_STANDALONE_BUILD_SHARED=OFF \
    -DLLVM_INCLUDE_TESTS=OFF \
    -DLLVM_LIBC_FULL_BUILD=ON \
    -DLLVM_LIBC_INCLUDE_SCUDO=OFF \
    -DLLVM_OPTIMIZED_TABLEGEN=ON \
    -DLLVM_PARALLEL_COMPILE_JOBS=32 \
    -DLLVM_PARALLEL_LINK_JOBS=8 \
    -DLLVM_STATIC_LINK_CXX_STDLIB=ON \
    -DLLVM_TARGETS_TO_BUILD=Native \
    -DLLVM_TARGET_TRIPLE="x86_64-linux-llvm" \
    -DPACKAGE_VENDOR=xxx \
    -DLLVM_PARALLEL_COMPILE_JOBS=${JOBS} \
    -DLLVM_PARALLEL_LINK_JOBS=8 \
    -DRUNTIMES_x86_64-linux-llvm_CMAKE_C_FLAGS="-static -march=native -Os -g0 " \
    -DRUNTIMES_x86_64-linux-llvm_CMAKE_CXX_FLAGS="-static -march=native -Os -g0 " \
    -DRUNTIMES_x86_64-linux-llvm_CMAKE_EXE_LINKER_FLAGS="-static" \
    -DRUNTIMES_x86_64-linux-llvm_COMPILER_RT_BUILD_SCUDO_STANDALONE_WITH_LLVM_LIBC=ON \
    -DRUNTIMES_x86_64-linux-llvm_COMPILER_RT_BUILD_GWP_ASAN=OFF \
    -DRUNTIMES_x86_64-linux-llvm_COMPILER_RT_SCUDO_STANDALONE_BUILD_SHARED=OFF \
    -DRUNTIMES_x86_64-linux-llvm_COMPILER_RT_BUILD_CRT=ON \
    -DRUNTIMES_x86_64-linux-llvm_COMPILER_RT_BUILD_LIBFUZZER=OFF \
    -DRUNTIMES_x86_64-linux-llvm_COMPILER_RT_BUILD_MEMPROF=OFF \
    -DRUNTIMES_x86_64-linux-llvm_COMPILER_RT_BUILD_SANITIZERS=ON \
    -DRUNTIMES_x86_64-linux-llvm_COMPILER_RT_BUILD_XRAY=OFF \
    -DRUNTIMES_x86_64-linux-llvm_COMPILER_RT_ENABLE_EXCEPTIONS=OFF \
    -DRUNTIMES_x86_64-linux-llvm_COMPILER_RT_ENABLE_PIC=OFF \
    -DRUNTIMES_x86_64-linux-llvm_COMPILER_RT_ENABLE_SHARED=OFF \
    -DRUNTIMES_x86_64-linux-llvm_COMPILER_RT_ENABLE_STATIC=ON \
    -DRUNTIMES_x86_64-linux-llvm_COMPILER_RT_TARGET_TRIPLE="x86_64-linux-llvm" \
    -DRUNTIMES_x86_64-linux-llvm_COMPILER_RT_USE_BUILTINS_LIBRARY=OFF \
    -DRUNTIMES_x86_64-linux-llvm_COMPILER_RT_USE_COMPILER_RT=ON \
    -DRUNTIMES_x86_64-linux-llvm_LIBCXXABI_ENABLE_EXCEPTIONS=OFF \
    -DRUNTIMES_x86_64-linux-llvm_LIBCXXABI_ENABLE_PIC=OFF \
    -DRUNTIMES_x86_64-linux-llvm_RUNTIMES_x86_64-linux-llvm_LIBCXXABI_ENABLE_SHARED=OFF \
    -DRUNTIMES_x86_64-linux-llvm_LIBCXXABI_ENABLE_STATIC=ON \
    -DRUNTIMES_x86_64-linux-llvm_LIBCXXABI_ENABLE_STATIC_UNWINDER=ON \
    -DRUNTIMES_x86_64-linux-llvm_LIBCXXABI_HAS_GCC_S_LIB=OFF \
    -DRUNTIMES_x86_64-linux-llvm_LIBCXXABI_INSTALL_LIBRARY=ON \
    -DRUNTIMES_x86_64-linux-llvm_LIBCXXABI_TARGET_TRIPLE="x86_64-linux-llvm" \
    -DRUNTIMES_x86_64-linux-llvm_LIBCXXABI_USE_COMPILER_RT=ON \
    -DRUNTIMES_x86_64-linux-llvm_LIBCXXABI_USE_LLVM_UNWINDER=ON \
    -DRUNTIMES_x86_64-linux-llvm_LIBCXXABI_ENABLE_THREADS=OFF \
    -DRUNTIMES_x86_64-linux-llvm_LIBCXX_ABI_VERSION=2 \
    -DRUNTIMES_x86_64-linux-llvm_LIBCXX_ENABLE_EXCEPTIONS=OFF \
    -DRUNTIMES_x86_64-linux-llvm_LIBCXX_ENABLE_FILESYSTEM=OFF \
    -DRUNTIMES_x86_64-linux-llvm_LIBCXX_ENABLE_LOCALIZATION=OFF \
    -DRUNTIMES_x86_64-linux-llvm_LIBCXX_ENABLE_MONOTONIC_CLOCK=OFF \
    -DRUNTIMES_x86_64-linux-llvm_LIBCXX_ENABLE_PIC=OFF \
    -DRUNTIMES_x86_64-linux-llvm_LIBCXX_ENABLE_RANDOM_DEVICE=OFF \
    -DRUNTIMES_x86_64-linux-llvm_LIBCXX_ENABLE_SHARED=OFF \
    -DRUNTIMES_x86_64-linux-llvm_LIBCXX_ENABLE_STATIC=ON \
    -DRUNTIMES_x86_64-linux-llvm_LIBCXX_ENABLE_STATIC_ABI_LIBRARY=ON \
    -DRUNTIMES_x86_64-linux-llvm_LIBCXX_ENABLE_THREADS=OFF \
    -DRUNTIMES_x86_64-linux-llvm_LIBCXX_ENABLE_WIDE_CHARACTERS=OFF \
    -DRUNTIMES_x86_64-linux-llvm_LIBCXX_HARDENING_MODE="none" \
    -DRUNTIMES_x86_64-linux-llvm_LIBCXX_HAS_ATOMIC_LIB=OFF \
    -DRUNTIMES_x86_64-linux-llvm_LIBCXX_HAS_GCC_S_LIB=OFF \
    -DRUNTIMES_x86_64-linux-llvm_LIBCXX_INSTALL_LIBRARY=ON \
    -DRUNTIMES_x86_64-linux-llvm_LIBCXX_STATIC_SHARED=ON \
    -DRUNTIMES_x86_64-linux-llvm_LIBCXX_TARGET_TRIPLE="x86_64-linux-llvm" \
    -DRUNTIMES_x86_64-linux-llvm_LIBCXX_USE_COMPILER_RT=ON \
    -DRUNTIMES_x86_64-linux-llvm_LIBC_ENABLE_EXCEPTIONS=OFF \
    -DRUNTIMES_x86_64-linux-llvm_LIBC_ENABLE_SHARED=OFF \
    -DRUNTIMES_x86_64-linux-llvm_LIBC_ENABLE_STATIC=ON \
    -DRUNTIMES_x86_64-linux-llvm_LIBC_ENABLE_USE_BY_CLANG=ON \
    -DRUNTIMES_x86_64-linux-llvm_LIBC_TARGET_TRIPLE="x86_64-linux-llvm" \
    -DRUNTIMES_x86_64-linux-llvm_LIBC_USE_COMPILER_RT=ON \
    -DRUNTIMES_x86_64-linux-llvm_LIBUNWIND_ENABLE_EXCEPTIONS=OFF \
    -DRUNTIMES_x86_64-linux-llvm_LIBUNWIND_ENABLE_PIC=OFF \
    -DRUNTIMES_x86_64-linux-llvm_LIBUNWIND_ENABLE_SHARED=OFF \
    -DRUNTIMES_x86_64-linux-llvm_LIBUNWIND_ENABLE_STATIC=ON \
    -DRUNTIMES_x86_64-linux-llvm_LIBUNWIND_FORCE_UNWIND_TABLES=OFF \
    -DRUNTIMES_x86_64-linux-llvm_LIBUNWIND_HAS_GCC_S_LIB=OFF \
    -DRUNTIMES_x86_64-linux-llvm_LIBUNWIND_INSTALL_LIBRARY=ON \
    -DRUNTIMES_x86_64-linux-llvm_LIBUNWIND_TARGET_TRIPLE="x86_64-linux-llvm" \
    -DRUNTIMES_x86_64-linux-llvm_LIBUNWIND_USE_COMPILER_RT=ON


ninja
ninja install

echo "Build completed successfully"
echo "Toolchain installed to: ${HOME_DIR}/llvm-toolchain"