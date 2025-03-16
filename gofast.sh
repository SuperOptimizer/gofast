#!/usr/bin/env bash
set -euo pipefail

WORK_DIR="/home/forrest/"
JOBS=16

SRC_DIR="${WORK_DIR}/srcdir"
BUILD_DIR="${WORK_DIR}/build"
BUILD2_DIR="${WORK_DIR}/build2"
SYSROOT_DIR="${WORK_DIR}/sysroot"
LLVM_SRC="${SRC_DIR}/llvm-project"


#rm -rf "${BUILD_DIR}" "${SYSROOT_DIR}"
mkdir -p "${SRC_DIR}" "${BUILD_DIR}"
mkdir -p "${SYSROOT_DIR}/usr/include" "${SYSROOT_DIR}/usr/lib" "${SYSROOT_DIR}/lib"

cd "${SRC_DIR}"
[ ! -d "llvm-project" ] && git clone https://github.com/llvm/llvm-project.git --depth 1

cd "${BUILD_DIR}"

cmake -G Ninja "${LLVM_SRC}/llvm" \
  -DCMAKE_C_COMPILER="/usr/bin/clang" \
  -DCMAKE_CXX_COMPILER="/usr/bin/clang++" \
  -DCMAKE_C_FLAGS="-march=native -stdlib=libc++ -fuse-ld=lld --rtlib=compiler-rt -unwind=libunwind -fno-semantic-interposition -fomit-frame-pointer -fno-common " \
  -DCMAKE_CXX_FLAGS="-march=native  -stdlib=libc++ -fuse-ld=lld --rtlib=compiler-rt -unwind=libunwind -fno-semantic-interposition -fomit-frame-pointer -fno-common " \
  -DCMAKE_LINKFLAGS="-stdlib=libc++ -fuse-ld=lld --rtlib=compiler-rt -unwind=libunwind" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="${SYSROOT_DIR}/usr" \
  -DLLVM_ENABLE_RUNTIMES="libc;libunwind;libcxxabi;libcxx;compiler-rt;openmp" \
  -DLLVM_TARGETS_TO_BUILD="X86" \
  -DLLVM_INCLUDE_TESTS=OFF \
  -DLLVM_INSTALL_UTILS=ON \
  -DCMAKE_CXX_STANDARD=20 \
  -DLLVM_INCLUDE_EXAMPLES=OFF \
  -DLIBCXX_ENABLE_EXPERIMENTAL_LIBRARY=ON \
  -DLIBCXX_HERMETIC_STATIC_LIBRARY=ON \
  -DLLVM_ENABLE_PROJECTS="bolt;clang;clang-tools-extra;lld;lldb" \
  -DLIBCXX_CXX_ABI="libcxxabi" \
  -DLIBCXX_ENABLE_STATIC_ABI_LIBRARY=ON \
  -DLIBCXXABI_USE_LLVM_UNWINDER=ON \
  -DDLLVM_RUNTIME_TARGETS="x86_64-linux-llvm" \
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
  -DCOMPILER_RT_DEFAULT_TARGET_ONLY=ON \
  -DLLVM_BUILD_STATIC=ON \
  -DLLVM_BUILD_SHARED=OFF \
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
  -DCOMPILER_RT_DEFAULT_TARGET_ONLY=ON \
  -DLLVM_BUILD_STATIC=ON \
  -DLLVM_BUILD_SHARED=OFF \
  -DLLVM_ENABLE_PIC=OFF \
  -DLLVM_ENABLE_LTO=Thin \
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
  -DLLVM_ENABLE_ZLIB=OFF \
  -DLLVM_ENABLE_LIBXML2=OFF \
  -DLLVM_ENABLE_LIBEDIT=OFF \
  -DLLVM_ENABLE_FFI=OFF \
  -DLLVM_ENABLE_THREADS=ON \
  -DLLVM_OPTIMIZED_TABLEGEN=ON \
  -DLLVM_USE_NEWPM=ON \
  -DLLVM_USE_LINKER=lld \
  -DLLVM_PARALLEL_LINK_JOBS=${JOBS} \
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
  -DLLVM_ENABLE_ZLIB=OFF

ninja
ninja install

cd "${BUILD2_DIR}"


cmake -G Ninja "${LLVM_SRC}/llvm" \
  -DCMAKE_C_COMPILER="${SYSROOT_DIR}/usr/bin/clang" \
  -DCMAKE_C_COMPILER="${SYSROOT_DIR}/usr/bin/clang++" \
  -DCMAKE_C_FLAGS="-march=native -stdlib=libc++ -fuse-ld=lld --rtlib=compiler-rt -unwind=libunwind -fno-semantic-interposition -fomit-frame-pointer -fno-common " \
  -DCMAKE_CXX_FLAGS="-march=native  -stdlib=libc++ -fuse-ld=lld --rtlib=compiler-rt -unwind=libunwind -fno-semantic-interposition -fomit-frame-pointer -fno-common " \
  -DCMAKE_LINKFLAGS="-stdlib=libc++ -fuse-ld=lld --rtlib=compiler-rt -unwind=libunwind" \
  -DCMAKE_BUILD_TYPE=Release \
  -DLLVM_ENABLE_RUNTIMES="libc;libunwind;libcxxabi;libcxx;compiler-rt;openmp" \
  -DLLVM_TARGETS_TO_BUILD="X86" \
  -DLLVM_INCLUDE_TESTS=OFF \
  -DLLVM_INSTALL_UTILS=ON \
  -DCMAKE_CXX_STANDARD=20 \
  -DLLVM_INCLUDE_EXAMPLES=OFF \
  -DLIBCXX_ENABLE_EXPERIMENTAL_LIBRARY=ON \
  -DLIBCXX_HERMETIC_STATIC_LIBRARY=ON \
  -DLLVM_ENABLE_PROJECTS="bolt;clang;clang-tools-extra;lld;lldb" \
  -DLIBCXX_CXX_ABI="libcxxabi" \
  -DLIBCXX_ENABLE_STATIC_ABI_LIBRARY=ON \
  -DLIBCXXABI_USE_LLVM_UNWINDER=ON \
  -DDLLVM_RUNTIME_TARGETS="x86_64-linux-llvm" \
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
  -DCOMPILER_RT_DEFAULT_TARGET_ONLY=ON \
  -DLLVM_BUILD_STATIC=ON \
  -DLLVM_BUILD_SHARED=OFF \
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
  -DCOMPILER_RT_DEFAULT_TARGET_ONLY=ON \
  -DLLVM_BUILD_STATIC=ON \
  -DLLVM_BUILD_SHARED=OFF \
  -DLLVM_ENABLE_PIC=OFF \
  -DLLVM_ENABLE_LTO=Thin \
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
  -DLLVM_ENABLE_ZLIB=OFF \
  -DLLVM_ENABLE_LIBXML2=OFF \
  -DLLVM_ENABLE_LIBEDIT=OFF \
  -DLLVM_ENABLE_FFI=OFF \
  -DLLVM_ENABLE_THREADS=ON \
  -DLLVM_OPTIMIZED_TABLEGEN=ON \
  -DLLVM_USE_NEWPM=ON \
  -DLLVM_USE_LINKER=lld \
  -DLLVM_PARALLEL_LINK_JOBS=${JOBS} \
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
  -DLLVM_ENABLE_ZLIB=OFF

ninja
ninja install


