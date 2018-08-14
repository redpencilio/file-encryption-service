# file-encryption-service
A docker container to encrypt files using a public GPG key

## configuration
Configuration is done via environment variables

* `ENCRYPT_RECIPIENT`: GPG recipient to use for encryption
* `ENCRYPT_AFTER_MINUTES`: Encrypt matching files with mtime of at least the configured amount of hours (default: 60) 
* `ENCRYPT_GLOB`: Pattern of files to encrypt, supports bash globbing. You can provide multiple patterns split by a space (default: '/data/pcaps/*.{pcap,har} /data/hars/*.har')
* `ENCRYPT_INTERVAL`: Interval to run at in seconds, empty string to disable (default 1h, 3600)

## usage

# one off load
`docker run --rm -v $PWD/keys:/keys -v /your/folder/to/encrypt:/data/ -e ENCRYPT_INTERVAL='' -e ENCRYPT_GLOB='/data/*' -e ENCRYPT_AFTER_HOURS='1' -e ENCRYPT_RECIPIENT='info@redpencil.io' lblod/file-encryption-service`
