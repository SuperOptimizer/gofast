#clang.cmake

set(CMAKE_C_COMPILER clang )
set(CMAKE_CXX_COMPILER clang++ )
set(CMAKE_ASM_COMPILER clang )
set(CMAKE_AR llvm-ar )
set(CMAKE_RANLIB llvm-ranlib )
set(CMAKE_LINKER lld )
set(LIBCXX_HAS_MUSL_LIBC ON)

set(LLVM_ENABLE_PROJECTS "clang;clang-tools-extra;lld")
set(LLVM_ENABLE_RUNTIMES "compiler-rt;libcxx;libcxxabi;libunwind;libc")

set(LLVM_TARGETS_TO_BUILD Native)

set(CMAKE_BUILD_TYPE MinSizeRel)
set(CMAKE_PLATFORM_NO_VERSIONED_SONAME ON)

set(CMAKE_VISIBILITY_INLINES_HIDDEN ON)
set(CMAKE_C_VISIBILITY_PRESET hidden)
set(CMAKE_CXX_VISIBILITY_PRESET hidden)
set(LLVM_ENABLE_LTO OFF)
set(PACKAGE_VENDOR xxx)
set(BUILD_SHARED_LIBS OFF)

set(LLVM_ENABLE_UNWIND_TABLES OFF)
set(LLVM_STATIC_LINK_CXX_STDLIB ON)
set(LLVM_INCLUDE_TESTS OFF)
set(LLVM_INCLUDE_EXAMPLES OFF)
set(LLVM_INCLUDE_BENCHMARKS OFF)
set(LLVM_LIBC_FULL_BUILD ON)
set(LIBC_HDRGEN_ONLY ON)

set(CLANG_DEFAULT_CXX_STDLIB libc++)
set(CLANG_DEFAULT_LINKER lld)
set(CLANG_DEFAULT_OBJCOPY llvm-objcopy)
set(CLANG_DEFAULT_RTLIB compiler-rt)
set(CLANG_DEFAULT_UNWINDLIB libunwind)
set(CLANG_PLUGIN_SUPPORT OFF)

set(LIBUNWIND_ENABLE_SHARED OFF)
set(LIBUNWIND_INSTALL_LIBRARY ON)
set(LIBUNWIND_USE_COMPILER_RT ON)
set(LIBCXXABI_ENABLE_SHARED OFF)
set(LIBCXXABI_ENABLE_STATIC_UNWINDER ON)
set(LIBCXXABI_INSTALL_LIBRARY ON)
set(LIBCXXABI_USE_COMPILER_RT ON)
set(LIBCXXABI_USE_LLVM_UNWINDER ON)
set(LIBCXX_ABI_VERSION 2)
set(LIBCXX_ENABLE_SHARED OFF)
set(LIBCXX_STATIC_SHARED ON)
set(LIBCXX_ENABLE_STATIC_ABI_LIBRARY ON)
set(LIBCXX_HARDENING_MODE "none")
set(LIBCXX_USE_COMPILER_RT ON)
set(LIBCXX_HAS_MUSL_LIBC ON)
set(LIBCXX_INSTALL_LIBRARY ON)

set(LLVM_ENABLE_PER_TARGET_RUNTIME_DIR OFF)
set(COMPILER_RT_USE_BUILTINS_LIBRARY OFF)
set(COMPILER_RT_BUILD_CRT ON)

set(LIBCXX_ENABLE_EXCEPTIONS OFF)
set(LIBCXXABI_ENABLE_EXCEPTIONS OFF)
set(LIBUNWIND_ENABLE_EXCEPTIONS OFF)

set(COMPILER_RT_BUILD_SANITIZERS OFF)
set(COMPILER_RT_BUILD_XRAY OFF)
set(COMPILER_RT_BUILD_LIBFUZZER OFF)
set(COMPILER_RT_BUILD_PROFILE OFF)
set(LIBUNWIND_FORCE_UNWIND_TABLES OFF)

set(LLVM_OPTIMIZED_TABLEGEN ON)
set(LLVM_PARALLEL_LINK_JOBS 8)
set(LLVM_PARALLEL_COMPILE_JOBS 32)
set(CMAKE_INTERPROCEDURAL_OPTIMIZATION ON)

set(LIBCXX_HAS_GCC_S_LIB OFF)
set(LIBCXXABI_HAS_GCC_S_LIB OFF)
set(LIBUNWIND_HAS_GCC_S_LIB OFF)
set(LIBCXX_HAS_ATOMIC_LIB OFF)
set(LIBCXXABI_HAS_CXA_THREAD_ATEXIT_IMPL OFF)

# Complete Static Linking
set(LLVM_ENABLE_PIC OFF)
set(COMPILER_RT_ENABLE_PIC OFF)
set(LIBCXX_ENABLE_PIC OFF)
set(LIBCXXABI_ENABLE_PIC OFF)
set(LIBUNWIND_ENABLE_PIC OFF)

# Minimal Runtime Features
set(LIBCXX_ENABLE_LOCALIZATION OFF)
set(LIBCXX_ENABLE_WIDE_CHARACTERS OFF)
set(LIBCXX_ENABLE_FILESYSTEM OFF)
set(LIBCXX_ENABLE_RANDOM_DEVICE OFF)
set(LIBCXX_ENABLE_MONOTONIC_CLOCK OFF)
set(LIBCXX_ENABLE_THREADS OFF)

# Remove External Dependencies
set(LLVM_ENABLE_ZLIB OFF)
set(LLVM_ENABLE_LIBXML2 OFF)
set(LLVM_ENABLE_TERMINFO OFF)
set(LLVM_ENABLE_LIBEDIT OFF)
set(LLVM_ENABLE_FFI OFF)

# libcxx options
set(LIBCXX_ENABLE_SHARED OFF)
set(LIBCXX_ENABLE_STATIC ON)
set(LIBCXX_USE_COMPILER_RT ON)
set(LIBCXX_ENABLE_EXCEPTIONS OFF)
set(LIBCXX_HAS_MUSL_LIBC=ON)



# libcxxabi options
set(LIBCXXABI_ENABLE_SHARED OFF)
set(LIBCXXABI_ENABLE_STATIC ON)
set(LIBCXXABI_USE_COMPILER_RT ON)
set(LIBCXXABI_ENABLE_EXCEPTIONS OFF)

# libunwind options
set(LIBUNWIND_ENABLE_SHARED OFF)
set(LIBUNWIND_ENABLE_STATIC ON)
set(LIBUNWIND_USE_COMPILER_RT ON)
set(LIBUNWIND_ENABLE_EXCEPTIONS OFF)

# compiler-rt options
set(COMPILER_RT_ENABLE_SHARED OFF)
set(COMPILER_RT_ENABLE_STATIC ON)
set(COMPILER_RT_USE_COMPILER_RT ON)
set(COMPILER_RT_ENABLE_EXCEPTIONS OFF)

# libc options
set(LIBC_ENABLE_SHARED OFF)
set(LIBC_ENABLE_STATIC ON)
set(LIBC_USE_COMPILER_RT ON)
set(LIBC_ENABLE_EXCEPTIONS OFF)

# Additional components if included
set(OPENMP_ENABLE_SHARED OFF)
set(OPENMP_ENABLE_STATIC ON)
set(OPENMP_USE_COMPILER_RT ON)
set(OPENMP_ENABLE_EXCEPTIONS OFF)

set(SCUDO_ENABLE_SHARED OFF)
set(SCUDO_ENABLE_STATIC ON)
set(SCUDO_USE_COMPILER_RT ON)
set(SCUDO_ENABLE_EXCEPTIONS OFF)

# Main LLVM target triples
set(LLVM_DEFAULT_TARGET_TRIPLE "${TARGET_TRIPLE}")
set(LLVM_TARGET_TRIPLE "${TARGET_TRIPLE}")
set(LLVM_HOST_TRIPLE "${TARGET_TRIPLE}")
set(CMAKE_HOST_TRIPLE "${TARGET_TRIPLE}")

# Runtime libraries target triples
set(LIBCXX_TARGET_TRIPLE "${TARGET_TRIPLE}")
set(LIBCXXABI_TARGET_TRIPLE "${TARGET_TRIPLE}")
set(LIBUNWIND_TARGET_TRIPLE "${TARGET_TRIPLE}")
set(COMPILER_RT_TARGET_TRIPLE "${TARGET_TRIPLE}")
set(LIBC_TARGET_TRIPLE "${TARGET_TRIPLE}")
set(OPENMP_TARGET_TRIPLE "${TARGET_TRIPLE}")
set(SCUDO_TARGET_TRIPLE "${TARGET_TRIPLE}")

# Clang and related tools
set(CLANG_TARGET_TRIPLE "${TARGET_TRIPLE}")
set(LLD_TARGET_TRIPLE "${TARGET_TRIPLE}")
set(LLDB_TARGET_TRIPLE "${TARGET_TRIPLE}")


set(COMPILER_RT_BUILD_SANITIZERS OFF)
set(COMPILER_RT_BUILD_XRAY OFF)
set(COMPILER_RT_BUILD_LIBFUZZER OFF)
set(COMPILER_RT_BUILD_PROFILE OFF)
set(COMPILER_RT_BUILD_MEMPROF OFF)

# Setting up the stage2 LTO option needs to be done on the stage1 build so that
# the proper LTO library dependencies can be connected.
set(LLVM_TOOLCHAIN_TOOLS
  llvm-ar
  llvm-config
  llvm-cov
  llvm-dwarfdump
  llvm-link
  llvm-nm
  llvm-objcopy
  llvm-objdump
  llvm-profdata
  llvm-ranlib
  llvm-rc
  llvm-readelf
  llvm-readobj
  llvm-size
  llvm-strings
  llvm-strip
  llvm-tblgen
 )

set(LLVM_DISTRIBUTION_COMPONENTS
  clang
  clang-resource-headers
  clang-tblgen
  lld
  runtimes
  builtins
  ${LLVM_TOOLCHAIN_TOOLS}
 )