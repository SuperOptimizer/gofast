#!/bin/bash
#
# Chimera Linux chroot script
#
# This script sets up a Chimera Linux chroot using the prebuilt APK static binary
#
# License: BSD-2-Clause
#

set -e

readonly PROGNAME=$(basename "$0")

MOUNTED_PSEUDO=
ROOT_DIR=
REPOSF=
APK_DIR="$(pwd)/apk-build"
APK_BIN=""

# Print colored messages
msg() {
    printf "\033[1m$@\n\033[m"
}

error_sig() {
    if [ -n "$MOUNTED_PSEUDO" ]; then
        umount_pseudo
    fi
    [ -n "$REPOSF" ] && rm -f "$REPOSF"
    exit ${1:=0}
}

trap 'error_sig $? $LINENO' INT TERM 0

die() {
    echo "ERROR: $@"
    error_sig 1 $LINENO
}

usage() {
    cat << EOF
Usage: $PROGNAME root-dir

Sets up and/or enters a Chimera Linux chroot environment using the prebuilt APK static binary.
EOF
    exit ${1:=1}
}

# Ensure we run as root
if [ "$(id -u)" != "0" ]; then
    die "Must run this as root."
fi

if [ $# -lt 1 ]; then
    usage
fi

# Use prebuilt APK binary
setup_apk_binary() {
    # Check if apk-x86_64.static exists in the current directory
    if [ -f "./apk-x86_64.static" ]; then
        APK_BIN="$(pwd)/apk-x86_64.static"
        if [ ! -x "$APK_BIN" ]; then
            chmod +x "$APK_BIN"
        fi
        msg "Using existing APK binary at $APK_BIN"
        return 0
    fi

    # Otherwise download it
    msg "Downloading prebuilt APK binary..."
    APK_URL="https://repo.chimera-linux.org/apk/latest/apk-x86_64.static"
    APK_BIN="$(pwd)/apk-x86_64.static"

    curl -L --fail "$APK_URL" -o "$APK_BIN"
    if [ $? -ne 0 ]; then
        die "Failed to download prebuilt APK binary from $APK_URL"
    fi

    chmod +x "$APK_BIN"
    msg "Successfully downloaded prebuilt APK binary to $APK_BIN"
    file "$APK_BIN" || true
    return 0
}

# Helper functions for mounting/unmounting pseudo filesystems
do_trymount() {
    if mountpoint -q "${ROOT_DIR}/$1" > /dev/null 2>&1; then
        return 0
    fi
    mkdir -m "$2" -p "${ROOT_DIR}/$1" 2>/dev/null
    mount --rbind "/$1" "${ROOT_DIR}/$1" || die "Failed to mount ${1}fs"
    mount --make-rslave "${ROOT_DIR}/$1" || die "Failed to make ${1} rslave"
    MOUNTED_PSEUDO="${MOUNTED_PSEUDO} $1"
}

mount_pseudo() {
    do_trymount dev 755
    do_trymount proc 555
    do_trymount sys 555
    do_trymount tmp 1777
}

umount_pseudo() {
    sync
    for mnt in ${MOUNTED_PSEUDO}; do
        [ -n "$mnt" ] || continue
        umount -R -f "${ROOT_DIR}/$mnt" > /dev/null 2>&1
    done
}

setup_resolv() {
    # Create DNS configuration with hardcoded nameservers
    cat > "${ROOT_DIR}/etc/resolv.conf" << EOF
nameserver 1.1.1.1
nameserver 8.8.8.8
EOF
}

# Copy host certificates into chroot
setup_certificates() {
    msg "Setting up certificate directories..."

    # Create SSL directory structure with proper permissions
    mkdir -p "${ROOT_DIR}/etc/ssl/certs"
    chmod 755 "${ROOT_DIR}/etc/ssl"
    chmod 755 "${ROOT_DIR}/etc/ssl/certs"

    # Create ca-certificates directories
    mkdir -p "${ROOT_DIR}/usr/share/ca-certificates"
    mkdir -p "${ROOT_DIR}/usr/local/share/ca-certificates"
    mkdir -p "${ROOT_DIR}/etc/ca-certificates/update.d"

    chmod 755 "${ROOT_DIR}/usr/share/ca-certificates"
    chmod 755 "${ROOT_DIR}/usr/local/share/ca-certificates"
    chmod 755 "${ROOT_DIR}/etc/ca-certificates"
    chmod 755 "${ROOT_DIR}/etc/ca-certificates/update.d"

    # Copy host certificate bundle if it exists
    if [ -f "/etc/ssl/certs/ca-certificates.crt" ]; then
        cp "/etc/ssl/certs/ca-certificates.crt" "${ROOT_DIR}/etc/ssl/certs/"
        chmod 644 "${ROOT_DIR}/etc/ssl/certs/ca-certificates.crt"
        msg "Host CA certificate bundle copied successfully"
    else
        # Create empty certificate bundle file
        touch "${ROOT_DIR}/etc/ssl/certs/ca-certificates.crt"
        chmod 644 "${ROOT_DIR}/etc/ssl/certs/ca-certificates.crt"
        msg "Created empty CA certificate bundle"
    fi
}

# Create APK keys directory
create_apk_keys_dir() {
    msg "Creating APK keys directory..."
    mkdir -p "$APK_DIR/keys"

    # Create a minimal signing key for bootstrapping
    openssl req -new -x509 -nodes -out "$APK_DIR/keys/chimera.pub" \
        -keyout "$APK_DIR/keys/chimera.priv" \
        -subj "/CN=Chimera-Bootstrap" 2>/dev/null

    if [ ! -f "$APK_DIR/keys/chimera.pub" ]; then
        die "Failed to create APK keys"
    fi
}

# Main script starts here
ROOT_DIR="$1"
shift

# Check if mountpoint command is available
if ! command -v mountpoint > /dev/null 2>&1; then
    die "mountpoint must be present"
fi

# Set up the APK binary
setup_apk_binary

if [ ! -x "$APK_BIN" ]; then
    die "APK binary not found or not executable"
fi

# Create APK keys directory if it doesn't exist
if [ ! -d "$APK_DIR/keys" ]; then
    create_apk_keys_dir
fi

msg "Using APK tools at: $APK_BIN"

# Check if this is a new installation or existing chroot
if [ ! -d "${ROOT_DIR}" ] || [ ! -f "${ROOT_DIR}/usr/bin/bash" ]; then
    # This is a new installation
    msg "Setting up new Chimera Linux chroot at ${ROOT_DIR}..."

    # Create the root directory if needed
    [ -d "$ROOT_DIR" ] || mkdir -p "$ROOT_DIR" || die "failed to create root directory"

    # Ensure the target is writable
    if ! touch "${ROOT_DIR}/.write-test" > /dev/null 2>&1; then
        die "root directory is not writable"
    else
        rm -f "${ROOT_DIR}/.write-test"
    fi

    # Setup repositories file
    REPOSF=$(mktemp)
    [ $? -eq 0 ] || die "failed to generate a repositories file"

    # Add correct Chimera Linux repository URLs
    cat > "$REPOSF" << EOF
https://repo.chimera-linux.org/current/main
https://repo.chimera-linux.org/current/user
EOF

    # Create necessary directory structure following base-files expectations
    msg "Creating directory structure..."
    mkdir -p "${ROOT_DIR}/usr/bin" || die "failed to create ${ROOT_DIR}/usr/bin"
    mkdir -p "${ROOT_DIR}/usr/lib" || die "failed to create ${ROOT_DIR}/usr/lib"

    # Create additional required directories
    mkdir -p "${ROOT_DIR}/etc/apk" || die "failed to create ${ROOT_DIR}/etc/apk"
    mkdir -p "${ROOT_DIR}/var/lib/apk" || die "failed to create ${ROOT_DIR}/var/lib/apk"
    mkdir -p "${ROOT_DIR}/var/cache/apk" || die "failed to create ${ROOT_DIR}/var/cache/apk"
    mkdir -p "${ROOT_DIR}/var/log" || die "failed to create ${ROOT_DIR}/var/log"
    mkdir -p "${ROOT_DIR}/etc" || die "failed to create ${ROOT_DIR}/etc"

    # Set up certificate directories
    setup_certificates

    # Create symlinks exactly matching what base-files expects
    msg "Creating usr-merge symlinks..."

    # /bin and /lib point to their usr counterparts
    ln -sf "usr/bin" "${ROOT_DIR}/bin" || die "failed to create /bin symlink"
    ln -sf "usr/lib" "${ROOT_DIR}/lib" || die "failed to create /lib symlink"

    # Special handling for sbin as per base-files:
    # /sbin points to usr/bin
    ln -sf "usr/bin" "${ROOT_DIR}/sbin" || die "failed to create /sbin symlink"

    msg "Created correct symlinks for usr-merge layout"

    # Copy repository list to the target
    cp "$REPOSF" "${ROOT_DIR}/etc/apk/repositories" || die "failed to copy repositories file"

    # Make it safe to install
    mount_pseudo

    # Initialize the APK database
    msg "Initializing APK database..."
    "$APK_BIN" --root "$ROOT_DIR" --keys-dir "$APK_DIR/keys" \
        --repositories-file "$REPOSF" --no-interactive --allow-untrusted \
        --no-check-certificate add --initdb

    # Update repository indexes
    msg "Updating repository indexes..."
    "$APK_BIN" --root "$ROOT_DIR" --keys-dir "$APK_DIR/keys" \
        --repositories-file "$REPOSF" --no-interactive --allow-untrusted \
        --no-check-certificate update

    # Install base system
    msg "Installing minimal system..."
    "$APK_BIN" --root "$ROOT_DIR" --keys-dir "$APK_DIR/keys" \
        --repositories-file "$REPOSF" --no-interactive --allow-untrusted \
        --no-check-certificate --force-overwrite --no-scripts add base-full zsh bash ca-certificates

    # Install essential packages
    msg "Installing additional essential packages..."
    "$APK_BIN" --root "$ROOT_DIR" --keys-dir "$APK_DIR/keys" \
        --repositories-file "$REPOSF" --no-interactive --allow-untrusted \
        --no-check-certificate --force-overwrite --no-scripts add bash \
        findutils gawk tzdata clang llvm libunwind libunwind-devel \
        libunwind-devel-static musl musl-devel musl-devel-static \
        libcxx libcxx-devel libcxx-devel-static libcxxabi libcxxabi-devel \
        libcxxabi-devel-static clang-rt-devel clang-tools-extra clang-tools-extra-static \
        clang-libs clang-devel-static clang-devel clang-analyzer libatomic-chimera \
        libatomic-chimera-devel libatomic-chimera-devel-static lld lld-devel lld-devel-static \
        automake elfutils gmake gcc rsync python-pyyaml

    # Set up DNS
    setup_resolv

    # Create a helper script inside the chroot to easily use --no-check-certificate
    cat > "${ROOT_DIR}/usr/local/bin/apk-nocheck" << 'EOF'
#!/bin/sh
# Helper script to run apk with --no-check-certificate flag
exec /usr/bin/apk --no-check-certificate "$@"
EOF
    chmod +x "${ROOT_DIR}/usr/local/bin/apk-nocheck"

    # Create a note file inside the chroot explaining how to use Git with --no-check-certificate
    cat > "${ROOT_DIR}/root/SSL_CERTIFICATE_NOTE.txt" << 'EOF'
NOTE FOR USING GIT WITH SSL:

If you encounter SSL certificate validation errors when using Git,
you can disable certificate validation with:

git -c http.sslVerify=false clone <repository-url>

For APK, use the apk-nocheck wrapper script:

apk-nocheck update
apk-nocheck add <package-name>

This is a workaround until proper certificate validation is set up.
EOF

    # Clean up temporary files
    [ -n "$REPOSF" ] && rm -f "$REPOSF"
    unset REPOSF
else
    # This is an existing chroot, just mount pseudo-filesystems
    msg "Entering existing Chimera Linux chroot at ${ROOT_DIR}..."
    mount_pseudo

    # Set up DNS (always refresh)
    setup_resolv
fi

# Enter the chroot environment
msg "Starting Chimera Linux shell..."
PS1="(chimera-chroot) # " chroot "$ROOT_DIR" "/usr/bin/bash"
RC=$?

umount_pseudo

exit $RC