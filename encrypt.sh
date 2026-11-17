#!/usr/bin/env bash
set -uo pipefail
shopt -s nullglob

ENCRYPT_RECIPIENT="${ENCRYPT_RECIPIENT:-}"
ENCRYPT_INTERVAL="${ENCRYPT_INTERVAL:-}"
ENCRYPT_AFTER_MINUTES="${ENCRYPT_AFTER_MINUTES:-60}"
ENCRYPT_GLOB="${ENCRYPT_GLOB:-/data/pcaps/*.{pcap,har} /data/hars/*.har}"
# Directory to write encrypted files to. When empty, the encrypted file is
# written next to the original.
ENCRYPTED_DIR="${ENCRYPTED_DIR:-}"
KEYS_DIR="${KEYS_DIR:-/keys}"

info()  { echo "[INFO]  $(date +%Y%m%dT%H%M%S): $*"; }
error() { echo "[ERROR] $(date +%Y%m%dT%H%M%S): $*" >&2; }

encrypt_file() {
    local file="$1" target_dir target tmp
    target_dir="${ENCRYPTED_DIR:-$(dirname "$file")}"
    target="$target_dir/$(basename "$file").gpg"
    tmp="$target.part"

    info "encrypting $file -> $target"
    # Write to a temporary file first so a half-written .gpg never appears,
    # and only remove the original once the encrypted file is in place.
    if gpg --batch --yes --trust-model always \
           --recipient "$ENCRYPT_RECIPIENT" \
           --output "$tmp" --encrypt "$file" \
       && mv -f "$tmp" "$target"; then
        rm -f "$file"
    else
        rm -f "$tmp"
        error "failed to encrypt $file, leaving it in place"
    fi
}

encrypt_files() {
    local pattern file now mtime
    local -a patterns matches
    now=$(date +%s)
    # Split on whitespace without globbing; expansion happens below.
    read -ra patterns <<< "$ENCRYPT_GLOB"
    for pattern in "${patterns[@]}"; do
        # eval so brace expansion in patterns (e.g. *.{pcap,har}) works.
        eval "matches=( $pattern )"
        for file in "${matches[@]}"; do
            [ -f "$file" ] || continue
            case "$file" in *.gpg|*.gpg.part) continue ;; esac
            mtime=$(stat --printf "%Y" "$file") || continue
            if (( (now - mtime) / 60 > ENCRYPT_AFTER_MINUTES )); then
                encrypt_file "$file"
            fi
        done
    done
}

if [ -z "$ENCRYPT_RECIPIENT" ]; then
    error "ENCRYPT_RECIPIENT environment variable not set!"
    error "This is a required setting!"
    exit 1
fi

if [ -n "$ENCRYPTED_DIR" ]; then
    mkdir -p "$ENCRYPTED_DIR"
fi

info "importing GPG keys from $KEYS_DIR"
for key in "$KEYS_DIR"/*; do
    [ -f "$key" ] || continue
    gpg --batch --import "$key" || error "could not import $key"
done

if ! gpg --batch --list-keys "$ENCRYPT_RECIPIENT" > /dev/null 2>&1; then
    error "no public key found for recipient '$ENCRYPT_RECIPIENT'"
    exit 1
fi

if [ -z "$ENCRYPT_INTERVAL" ]; then
    encrypt_files
else
    trap 'info "stopping"; exit 0' TERM INT
    while true; do
        encrypt_files
        # Sleep in the background so signals are handled immediately.
        sleep "$ENCRYPT_INTERVAL" &
        wait $!
    done
fi
