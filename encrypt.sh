#!/usr/bin/env bash


# Convenience logging function.
info()    {
    now=$(date +%Y%m%dT%H%M%S)
    echo "[INFO] $now:  $@";
}

encrypt_files() {
    for gl in $ENCRYPT_GLOB;do
        for file in $gl;do
            if [ -f "$file" ]; then
                 #Checks if the file is a file not a directory
                 fileTime=$(stat --printf "%Y" "$file")
                 curTime=$(date +%s)
                 if (( ( ($curTime - $fileTime) / 60 ) > $ENCRYPT_AFTER_MINUTES ))
                 then
                     info "encrypting $file"
                     gpg --encrypt -o "$ENCRYPTED_DIR/$(basename "$file").gpg" --recipient "$ENCRYPT_RECIPIENT" --trust-model always "$file"
                     rm "$file"
                 fi
             fi
        done
    done
}

info "importing GPG keys"
for x in /keys/*;do
    gpg --import "$x";
done

if [ -z $ENCRYPT_RECIPIENT ]; then
    info "ENCRYPT_RECIPIENT environment variable not set!"
    info "This is a required setting!"
    exit -1
fi

if [ -z $ENCRYPT_INTERVAL ];then
    encrypt_files
else
    while true
    do
        encrypt_files
        sleep "$ENCRYPT_INTERVAL"
    done
fi

