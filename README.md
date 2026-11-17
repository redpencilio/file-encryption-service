# file-encryption-service
A docker container to encrypt files using a public GPG key

## configuration
Configuration is done via environment variables

* `ENCRYPT_RECIPIENT`: GPG recipient to use for encryption (required). The service refuses to start if no public key for this recipient is found in `/keys`.
* `ENCRYPT_AFTER_MINUTES`: Only encrypt matching files whose mtime is more than the configured amount of minutes ago (default: 60)
* `ENCRYPT_GLOB`: Pattern of files to encrypt, supports bash globbing including brace expansion. You can provide multiple patterns split by a space (default: `'/data/pcaps/*.{pcap,har} /data/hars/*.har'`)
* `ENCRYPTED_DIR`: Directory to write encrypted files to. When empty, `<file>.gpg` is written next to the original file (default: empty)
* `ENCRYPT_INTERVAL`: Interval to run at in seconds, empty string to run once and exit (default 1h, 3600)

The original file is only removed after its encrypted version has been fully written.

## usage

### one off load
`docker run --rm -v $PWD/keys:/keys -v /your/folder/to/encrypt:/data/ -e ENCRYPT_INTERVAL='' -e ENCRYPT_GLOB='/data/*' -e ENCRYPT_AFTER_MINUTES='60' -e ENCRYPT_RECIPIENT='info@redpencil.io' redpencil/file-encryption-service`

### rotating GPG key
If at some point you wish to replace the gpg key (because it was revoked or will expire soon), add the new (public) key to the keys directory and remove the old key from the gpg store using ```docker exec -it [container-name] gpg --delete-key [key-id]```.

You can retrieve the key using ```docker exec -it [container-name] gpg --list-keys```.

### general GPG information
You can run this container interactively to run the following commands. To do so, just run the following command to get a shell inside the container
```
docker run -it -v $PWD/keys:/keys redpencil/file-encryption-service /bin/bash
```

The image ships GnuPG 2.4. Passphrases are asked for directly on the terminal (`pinentry-mode loopback`).

* generate a key: `gpg --full-generate-key` (or `gpg --quick-generate-key 'Name <email>' default default 2y`)
* export a public key: `gpg --output gpgkey.gpg --armor --export [key-id]`
* export a private key: `gpg --armor --export-secret-keys [key-id] > file.asc`
* import a private key: `gpg --import [file]`
* decrypt a file: `gpg --decrypt [file]`

### keys and files from older versions
Older versions of this image used GnuPG 1.4. Keys generated with those versions (RSA, DSA/ElGamal) and files encrypted by them work as-is with the current image: import the exported private key and decrypt as usual. Files encrypted by the current image can still be decrypted with GnuPG 1.4.
