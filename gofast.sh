#!/usr/bin/env bash
set -euo pipefail

WORK_DIR="/home/forrest/"
JOBS=32

SRC_DIR="${WORK_DIR}/srcdir"
BUILD_DIR="${WORK_DIR}/build"
BUILD2_DIR="${WORK_DIR}/build2"
SYSROOT_DIR="${WORK_DIR}/sysroot"
LLVM_SRC="${SRC_DIR}/llvm-project"

# Host and target triples
TARGET_TRIPLE="x86_64-linux-llvm"

#rm -rf "${BUILD_DIR}" "${SYSROOT_DIR}"
mkdir -p "${SRC_DIR}" "${BUILD_DIR}" "${BUILD2_DIR}"
mkdir -p "${SYSROOT_DIR}/usr/include" "${SYSROOT_DIR}/usr/lib" "${SYSROOT_DIR}/lib"

cd "${SRC_DIR}"
[ ! -d "llvm-project" ] && git clone https://github.com/llvm/llvm-project.git --depth 1

# Stage 1 Build: Use the host's gcc/clang to build LLVM with x86_64-linux-gnu as host
# and produce x86_64-linux-llvm for the target
cd "${BUILD_DIR}"

cmake -G Ninja "${LLVM_SRC}/llvm" \
  -DCMAKE_C_COMPILER="/usr/bin/clang" \
  -DCMAKE_CXX_COMPILER="/usr/bin/clang++" \
  -DLLVM_DEFAULT_TARGET_TRIPLE="${TARGET_TRIPLE}" \
  -DCMAKE_C_FLAGS=" -static -march=native -stdlib=libc++ -fuse-ld=lld  -fno-semantic-interposition -fomit-frame-pointer -fno-common " \
  -DCMAKE_CXX_FLAGS=" -static -march=native  -stdlib=libc++ -fuse-ld=lld  -fno-semantic-interposition -fomit-frame-pointer -fno-common " \
  -DCMAKE_LINKFLAGS=" -static -fuse-ld=lld -stdlib=libc++ -fuse-ld=lld " \
  -DCMAKE_EXE_LINKER_FLAGS=" -static -fuse-ld=lld -stdlib=libc++ -fuse-ld=lld  " \
  -DCMAKE_SHARED_LINKER_FLAGS=" -static -fuse-ld=lld -stdlib=libc++ -fuse-ld=lld " \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="${SYSROOT_DIR}/usr" \
  -DLLVM_ENABLE_RUNTIMES="libc;libunwind;libcxxabi;libcxx;compiler-rt" \
  -DLLVM_TARGETS_TO_BUILD="X86" \
  -DLLVM_INCLUDE_TESTS=OFF \
  -DLLVM_INSTALL_UTILS=ON \
  -DCMAKE_CXX_STANDARD=20 \
  -DLLVM_INCLUDE_EXAMPLES=OFF \
  -DLIBCXX_ENABLE_EXPERIMENTAL_LIBRARY=ON \
  -DLIBCXX_HERMETIC_STATIC_LIBRARY=ON \
  -DLLVM_ENABLE_PROJECTS="clang;lld" \
  -DLIBCXX_CXX_ABI="libcxxabi" \
  -DLIBCXX_ENABLE_STATIC_ABI_LIBRARY=ON \
  -DLIBCXXABI_USE_LLVM_UNWINDER=ON \
  -DLLVM_RUNTIME_TARGETS="${TARGET_TRIPLE}" \
  -DLIBCXX_INCLUDE_TESTS=OFF \
  -DLLVM_ENABLE_ASSERTIONS=OFF \
  -DLIBCXX_USE_COMPILER_RT=ON \
  -DLIBC_FULL_BUILD=ON \
  -DLIBCXX_CXX_ABI=libcxxabi \
  -DLIBCXX_ENABLE_STATIC=ON \
  -DLIBCXX_ENABLE_SHARED=OFF \
  -DLIBCXXABI_USE_LLVM_UNWINDER=ON \
  -DLIBCXXABI_USE_COMPILER_RT=ON \
  -DLIBUNWIND_USE_COMPILER_RT=ON \
  -DLLVM_BUILD_STATIC=ON \
  -DLLVM_BUILD_SHARED=OFF \
  -DLIBCXX_INCLUDE_TESTS=OFF \
  -DLLVM_ENABLE_ASSERTIONS=OFF \
  -DLIBCXX_USE_COMPILER_RT=ON \
  -DLIBC_FULL_BUILD=ON \
  -DLIBCXXABI_ENABLE_SHARED=OFF \
  -DLIBCXXABI_ENABLE_STATIC=ON \
  -DLIBCXX_CXX_ABI=libcxxabi \
  -DLIBCXX_ENABLE_STATIC=ON \
  -DLIBCXX_ENABLE_SHARED=OFF \
  -DLIBCXXABI_USE_LLVM_UNWINDER=ON \
  -DLIBCXXABI_USE_COMPILER_RT=ON \
  -DLIBUNWIND_USE_COMPILER_RT=ON \
  -DLIBCXX_TARGET_TRIPLE="${TARGET_TRIPLE}" \
   -DLIBCXXABI_TARGET_TRIPLE="${TARGET_TRIPLE}" \
   -DLIBUNWIND_TARGET_TRIPLE="${TARGET_TRIPLE}" \
   -DCOMPILER_RT_TARGET_TRIPLE="${TARGET_TRIPLE}" \
   -DLLVM_TARGET_TRIPLE="${TARGET_TRIPLE}" \
  -DLLVM_BUILD_STATIC=ON \
  -DLLVM_BUILD_SHARED=OFF \
  -DCLANG_DEFAULT_LINKER="lld" \
  -DLLVM_ENABLE_PIC=OFF \
  -DCOMPILER_RT_ENABLE_PIC=OFF \
  -DLIBCXX_ENABLE_PIC=OFF \
  -DLIBCXXABI_ENABLE_PIC=OFF \
  -DLIBUNWIND_ENABLE_PIC=OFF \
  -DLLVM_STATIC_LINK_CXX_STDLIB=ON \
  -DLLVM_LINK_LLVM_DYLIB=OFF \
  -DLLVM_ENABLE_TERMINFO=OFF \
  -DLLVM_USE_NEWPM=ON \
  -DLLVM_HERMETIC_STATIC_LIBRARY=ON \
  -DLLVM_ENABLE_RTTI=OFF \
  -DLLVM_ENABLE_EH=OFF \
  -DLLVM_ENABLE_UNWIND_TABLES=OFF \
  -DLLVM_ENABLE_EH=OFF \
  -DLLVM_ENABLE_RTTI=OFF \
  -DLLVM_ENABLE_TERMINFO=OFF \
  -DLLVM_ENABLE_LTO=Full \
  -DLLVM_ENABLE_ZLIB=OFF \
  -DLLVM_ENABLE_LIBXML2=OFF \
  -DLLVM_ENABLE_LIBEDIT=OFF \
  -DLLVM_ENABLE_FFI=OFF \
  -DLLVM_ENABLE_THREADS=ON \
  -DLLVM_OPTIMIZED_TABLEGEN=ON \
  -DLLVM_USE_NEWPM=ON \
  -DLLVM_USE_LINKER=lld \
  -DLLVM_PARALLEL_LINK_JOBS=4 \
  -DLLVM_PARALLEL_COMPILE_JOBS=${JOBS} \
  -DLLVM_PARALLEL_TABLEGEN_JOBS=${JOBS} \
  -DLLVM_OPTIMIZED_TABLEGEN=ON \
  -DLLVM_ENABLE_VECTORIZE=ON \
  -DCMAKE_INTERPROCEDURAL_OPTIMIZATION=ON \
  -DCOMPILER_RT_DEFAULT_TARGET_ONLY=OFF \
  -DLLVM_POLLY_BUILD=OFF \
  -DLLVM_ENABLE_Z3_SOLVER=OFF \
  -DLLVM_EXTERNALIZE_DEBUGINFO=OFF \
  -DLIBUNWIND_ENABLE_CROSS_UNWINDING=OFF \
  -DCLANG_ENABLE_STATIC_ANALYZER=ON \
  -DLLVM_INSTALL_BINUTILS_SYMLINKS=ON \
  -DLLVM_INSTALL_CCTOOLS_SYMLINKS=ON \
  -DLLVM_BUILD_LLVM_C_DYLIB=OFF \
  -DLLVM_ENABLE_LIBPFM=OFF \
-DLIBUNWIND_ENABLE_SHARED=OFF \
-DLIBUNWIND_ENABLE_STATIC=ON \
-DCOMPILER_RT_BUILD_SHARED_ASAN=OFF \
-DCOMPILER_RT_BUILD_SHARED_UBSAN=OFF \
-DCOMPILER_RT_BUILD_SHARED_XRAY=OFF \
  -DLLVM_ENABLE_FATLTO=ON \
-DLIBOMP_ENABLE_SHARED=OFF \
-DOPENMP_ENABLE_SHARED=OFF \
  -DLLVM_ENABLE_CURL=OFF \
  -DLIBCXX_HAS_GCC_S_LIB=OFF \
  -DLLVM_APPEND_VC_REV=OFF \
  -DLLVM_INCLUDE_TESTS=OFF \
  -DLLVM_USE_SPLIT_DWARF=ON \
  -DCLANG_ENABLE_ARCMT=ON \
  -DLLVM_ENABLE_ZLIB=OFF

ninja
ninja install

# Stage 2 Build: Use the stage 1 compiler to build LLVM with x86_64-linux-llvm
# as both host and target
cd "${BUILD2_DIR}"

cmake -G Ninja "${LLVM_SRC}/llvm" \
  -DCMAKE_C_COMPILER="${SYSROOT_DIR}/usr/bin/clang" \
  -DCMAKE_CXX_COMPILER="${SYSROOT_DIR}/usr/bin/clang++" \
  -DCMAKE_HOST_TRIPLE="${TARGET_TRIPLE}" \
  -DLLVM_HOST_TRIPLE="${TARGET_TRIPLE}" \
  -DLLVM_DEFAULT_TARGET_TRIPLE="${TARGET_TRIPLE}" \
  -DDEFAULT_SYSROOT="${SYSROOT_DIR}" \
  -DCMAKE_C_FLAGS=" -static -target x86_64-linux-llvm -march=native -stdlib=libc++ -fuse-ld=lld --rtlib=compiler-rt -unwind=libunwind -fno-semantic-interposition -fomit-frame-pointer -fno-common " \
  -DCMAKE_CXX_FLAGS=" -static -target x86_64-linux-llvm -march=native  -stdlib=libc++ -fuse-ld=lld --rtlib=compiler-rt -unwind=libunwind -fno-semantic-interposition -fomit-frame-pointer -fno-common " \
  -DCMAKE_LINKFLAGS=" -static -fuse-ld=lld -target x86_64-linux-llvm -stdlib=libc++ -fuse-ld=lld --rtlib=compiler-rt -unwind=libunwind" \
  -DCMAKE_EXE_LINKER_FLAGS=" -static -L${SYSROOT_DIR}/usr/lib/x86_64-unknown-linux-llvm -lllvmlibc -fuse-ld=lld -target x86_64-linux-llvm -stdlib=libc++ -fuse-ld=lld --rtlib=compiler-rt -unwind=libunwind" \
  -DCMAKE_SHARED_LINKER_FLAGS=" -static -L${SYSROOT_DIR}/usr/lib/x86_64-unknown-linux-llvm -lllvmlibc -fuse-ld=lld -target x86_64-linux-llvm -stdlib=libc++ -fuse-ld=lld --rtlib=compiler-rt -unwind=libunwind" \
  -DCMAKE_BUILD_TYPE=Release \
  -DLLVM_ENABLE_RUNTIMES="libc;libunwind;libcxxabi;libcxx;compiler-rt;openmp" \
  -DLLVM_TARGETS_TO_BUILD="X86" \
  -DLLVM_INCLUDE_TESTS=OFF \
  -DLLVM_INSTALL_UTILS=ON \
  -DLIBOMP_INSTALL_ALIASES=ON\
  -DCMAKE_CXX_STANDARD=20 \
  -DLLVM_INCLUDE_EXAMPLES=OFF \
  -DLIBCXX_ENABLE_EXPERIMENTAL_LIBRARY=ON \
  -DLIBCXX_HERMETIC_STATIC_LIBRARY=ON \
  -DLLVM_ENABLE_PROJECTS="bolt;clang;clang-tools-extra;lld;lldb" \
  -DLIBCXX_CXX_ABI="libcxxabi" \
  -DLIBCXX_ENABLE_STATIC_ABI_LIBRARY=ON \
  -DLIBCXXABI_USE_LLVM_UNWINDER=ON \
  -DLLVM_RUNTIME_TARGETS="${TARGET_TRIPLE}" \
  -DLIBCXX_INCLUDE_TESTS=OFF \
  -DLLVM_ENABLE_ASSERTIONS=OFF \
  -DLIBCXX_USE_COMPILER_RT=ON \
  -DLIBCXXABI_ENABLE_SHARED=OFF \
  -DLIBCXXABI_ENABLE_STATIC=ON \
  -DLIBC_FULL_BUILD=ON \
  -DLIBCXX_CXX_ABI=libcxxabi \
  -DLIBCXX_ENABLE_STATIC=ON \
  -DLIBCXX_ENABLE_SHARED=OFF \
  -DLIBCXXABI_USE_LLVM_UNWINDER=ON \
  -DLIBCXXABI_USE_COMPILER_RT=ON \
  -DLIBUNWIND_USE_COMPILER_RT=ON \
  -DLLVM_BUILD_STATIC=ON \
  -DLLVM_BUILD_SHARED=OFF \
  -DLIBCXX_INCLUDE_TESTS=OFF \
  -DLLVM_ENABLE_ASSERTIONS=OFF \
  -DCLANG_DEFAULT_LINKER="lld" \
  -DLIBCXX_USE_COMPILER_RT=ON \
  -DLIBC_FULL_BUILD=ON \
  -DLIBCXX_CXX_ABI=libcxxabi \
  -DLIBCXX_TARGET_TRIPLE="${TARGET_TRIPLE}" \
   -DLIBCXXABI_TARGET_TRIPLE="${TARGET_TRIPLE}" \
   -DLIBUNWIND_TARGET_TRIPLE="${TARGET_TRIPLE}" \
   -DCOMPILER_RT_TARGET_TRIPLE="${TARGET_TRIPLE}" \
   -DLLVM_TARGET_TRIPLE="${TARGET_TRIPLE}" \
  -DLIBCXX_ENABLE_STATIC=ON \
  -DLIBCXX_ENABLE_SHARED=OFF \
  -DLIBCXXABI_USE_LLVM_UNWINDER=ON \
  -DLIBCXXABI_USE_COMPILER_RT=ON \
  -DLIBUNWIND_USE_COMPILER_RT=ON \
  -DLIBCXX_HAS_GCC_S_LIB=OFF \
  -DCOMPILER_RT_DEFAULT_TARGET_ONLY=OFF \
  -DLLVM_BUILD_STATIC=ON \
  -DLLVM_BUILD_SHARED=OFF \
  -DLLVM_ENABLE_PIC=OFF \
  -DLLVM_ENABLE_LTO=Full \
  -DCOMPILER_RT_ENABLE_PIC=OFF \
  -DLIBCXX_ENABLE_PIC=OFF \
  -DLIBCXXABI_ENABLE_PIC=OFF \
  -DLIBUNWIND_ENABLE_PIC=OFF \
  -DLLVM_STATIC_LINK_CXX_STDLIB=ON \
  -DLLVM_LINK_LLVM_DYLIB=OFF \
  -DLLVM_ENABLE_TERMINFO=OFF \
  -DLLVM_USE_NEWPM=ON \
  -DLLVM_HERMETIC_STATIC_LIBRARY=ON \
  -DLLVM_ENABLE_RTTI=OFF \
  -DLLVM_ENABLE_EH=OFF \
  -DLLVM_ENABLE_UNWIND_TABLES=OFF \
  -DLLVM_ENABLE_EH=OFF \
  -DLLVM_ENABLE_RTTI=OFF \
  -DLLVM_ENABLE_FATLTO=ON \
  -DLLVM_ENABLE_TERMINFO=OFF \
  -DLLVM_ENABLE_ZLIB=OFF \
  -DLLVM_ENABLE_LIBXML2=OFF \
  -DLLVM_ENABLE_LIBEDIT=OFF \
  -DLLVM_ENABLE_FFI=OFF \
  -DLLVM_ENABLE_THREADS=ON \
  -DLLVM_OPTIMIZED_TABLEGEN=ON \
  -DLLVM_USE_NEWPM=ON \
  -DLLVM_USE_LINKER=lld \
  -DLLVM_PARALLEL_LINK_JOBS=4 \
  -DLLVM_PARALLEL_COMPILE_JOBS=${JOBS} \
  -DLLVM_PARALLEL_TABLEGEN_JOBS=${JOBS} \
  -DLLVM_OPTIMIZED_TABLEGEN=ON \
  -DLLVM_ENABLE_VECTORIZE=ON \
  -DCMAKE_INTERPROCEDURAL_OPTIMIZATION=ON \
  -DLLVM_POLLY_BUILD=OFF \
  -DLLVM_ENABLE_Z3_SOLVER=OFF \
  -DLLVM_EXTERNALIZE_DEBUGINFO=OFF \
  -DLIBUNWIND_ENABLE_CROSS_UNWINDING=OFF \
  -DCLANG_ENABLE_STATIC_ANALYZER=ON \
  -DLLVM_INSTALL_BINUTILS_SYMLINKS=ON \
  -DLLVM_INSTALL_CCTOOLS_SYMLINKS=ON \
  -DLLVM_BUILD_LLVM_C_DYLIB=OFF \
  -DLLVM_ENABLE_LIBPFM=OFF \
  -DLLVM_ENABLE_CURL=OFF \
  -DLLVM_APPEND_VC_REV=OFF \
  -DLLVM_INCLUDE_TESTS=OFF \
  -DLLVM_USE_SPLIT_DWARF=ON \
  -DCLANG_ENABLE_ARCMT=ON \
  -DCOMPILER_RT_BUILD_SANITIZERS=ON \
  -DCOMPILER_RT_BUILD_XRAY=ON \
  -DCOMPILER_RT_BUILD_LIBFUZZER=ON \
  -DCOMPILER_RT_BUILD_PROFILE=ON \
  -DCOMPILER_RT_BUILD_MEMPROF=ON \
  -DSANITIZER_USE_STATIC_LLVM_UNWINDER=ON \
  -DSANITIZER_USE_STATIC_CXX_ABI=ON \
  -DCOMPILER_RT_USE_BUILTINS_LIBRARY=ON \
  -DSANITIZER_CXX_ABI_LIBNAME=libc++ \
-DLIBUNWIND_ENABLE_SHARED=OFF \
-DLIBUNWIND_ENABLE_STATIC=ON \
-DCOMPILER_RT_BUILD_SHARED_ASAN=OFF \
-DCOMPILER_RT_BUILD_SHARED_UBSAN=OFF \
-DCOMPILER_RT_BUILD_SHARED_XRAY=OFF \
-DLIBOMP_ENABLE_SHARED=OFF \
-DOPENMP_ENABLE_SHARED=OFF \
  -DSANITIZER_STATIC=ON \
  -DLLVM_ENABLE_ZLIB=OFF

ninja
ninja install

