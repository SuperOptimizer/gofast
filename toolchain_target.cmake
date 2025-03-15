set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR x86_64)

# Paths to our Stage 1 toolchain
set(STAGE1_DIR "/home/forrest/llvm-musl-toolchain/stage1")
set(SYSROOT "/home/forrest/llvm-musl-toolchain/sysroot")
set(TARGET_TRIPLE "x86_64-linux-musl")

# Explicitly use the Stage 1 compiler binaries
set(CMAKE_C_COMPILER "${STAGE1_DIR}/bin/clang")
set(CMAKE_CXX_COMPILER "${STAGE1_DIR}/bin/clang++")
set(CMAKE_LINKER "${STAGE1_DIR}/bin/lld")

# Ensure we're using the Stage 1 LLVM-based binutils
set(CMAKE_AR "${STAGE1_DIR}/bin/llvm-ar")
set(CMAKE_NM "${STAGE1_DIR}/bin/llvm-nm")
set(CMAKE_OBJDUMP "${STAGE1_DIR}/bin/llvm-objdump")
set(CMAKE_RANLIB "${STAGE1_DIR}/bin/llvm-ranlib")
set(CMAKE_STRIP "${STAGE1_DIR}/bin/llvm-strip")

# Enable ccache for faster builds
set(CMAKE_C_COMPILER_LAUNCHER "ccache")
set(CMAKE_CXX_COMPILER_LAUNCHER "ccache")

# Explicitly specify include and library paths for musl
set(MUSL_INCLUDE "${SYSROOT}/include")
set(MUSL_LIB "${SYSROOT}/lib")

# Set flags for the toolchain - NO PIC/PIE with explicit paths
set(CMAKE_C_FLAGS_INIT
    " -ffreestanding \
    -fomit-frame-pointer \
    -fstrict-aliasing \
    -fno-math-errno \
    -march=native \
    -fno-semantic-interposition \
    -fvisibility=hidden \
    -ffunction-sections \
    -fdata-sections \
    -O3 \
    -flto=thin \
    -ffat-lto-objects \
    -fno-pic \
    -fno-pie \
    --target=${TARGET_TRIPLE} \
    -fuse-ld=lld \
    -rtlib=compiler-rt \
    -unwindlib=libunwind \
    -nostdinc \
    -nostdlib \
    -isystem ${MUSL_INCLUDE} \
    -isystem ${SYSROOT}/usr/include \
    -static \
    --sysroot=${SYSROOT}"
)

set(CMAKE_CXX_FLAGS_INIT
    " -ffreestanding \
    -fomit-frame-pointer \
    -fstrict-aliasing \
    -fno-math-errno \
    -march=native \
    -fno-semantic-interposition \
    -fvisibility=hidden \
    -fvisibility-inlines-hidden \
    -ffunction-sections \
    -fdata-sections \
    -O3 \
    -flto=thin \
    -ffat-lto-objects \
    -fno-pic \
    -fno-pie \
    --target=${TARGET_TRIPLE} \
    -fuse-ld=lld \
    -rtlib=compiler-rt \
    -unwindlib=libunwind \
    -stdlib=libc++ \
    -nostdinc \
    -nostdinc++ \
    -nostdlib \
    -isystem ${MUSL_INCLUDE} \
    -isystem ${SYSROOT}/usr/include \
    -static \
    --sysroot=${SYSROOT}"
)

# Link flags with explicit library paths
set(LINKER_FLAGS
    "-fuse-ld=lld \
    -nostdlib \
    -L${MUSL_LIB} \
    -L${SYSROOT}/usr/lib \
    -Wl,-O3 \
    -Wl,--gc-sections \
    -Wl,--as-needed \
    -Wl,--icf=all \
    -Wl,--no-undefined \
    -Wl,--build-id=none \
    -Wl,--start-group \
    -Wl,--end-group \
    -fno-pic \
    -fno-pie \
    -static \
    -Wl,--exclude-libs,ALL \
    -Wl,-z,separate-code \
    -Wl,-z,relro \
    -Wl,-z,now \
    -Wl,-z,noexecstack \
    -Wl,--relax \
    -Wl,--sort-common \
    -Wl,-z,defs"
)

set(CMAKE_EXE_LINKER_FLAGS_INIT "${LINKER_FLAGS}")
set(CMAKE_SHARED_LINKER_FLAGS_INIT "${LINKER_FLAGS}")
set(CMAKE_MODULE_LINKER_FLAGS_INIT "${LINKER_FLAGS}")

# musl-specific options
add_compile_definitions(_LIBCPP_HAS_MUSL_LIBC=1)

# Ensure we don't use host system libraries
set(CMAKE_FIND_ROOT_PATH "${SYSROOT}")
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

# For cross-compiling
set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)