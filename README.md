# file-encryption-service
A docker container to encrypt files using a public GPG key

## configuration
Configuration is done via environment variables

* `ENCRYPT_RECIPIENT`: GPG recipient to use for encryption
* `ENCRYPT_AFTER_MINUTES`: Encrypt matching files with mtime of at least the configured amount of hours (default: 60) 
* `ENCRYPT_GLOB`: Pattern of files to encrypt, supports bash globbing. You can provide multiple patterns split by a space (default: '/data/pcaps/*.{pcap,har} /data/hars/*.har')
* `ENCRYPT_INTERVAL`: Interval to run at in seconds, empty string to disable (default 1h, 3600)

## usage

### one off load
`docker run --rm -v $PWD/keys:/keys -v /your/folder/to/encrypt:/data/ -e ENCRYPT_INTERVAL='' -e ENCRYPT_GLOB='/data/*' -e ENCRYPT_AFTER_HOURS='1' -e ENCRYPT_RECIPIENT='info@redpencil.io' redpencil/file-encryption-service`

### rotating GPG key
If at some point you wish to replace the gpg key (because it was revoked or will expire soon), add the new (public) key tot the keys directory and remove the old key from the gpg store using ```docker exec -it [container-name] gpg --delete-key [key-id]```.

You can retrieve the key using ```docker exec -it [container-name] gpg --list-keys```.

### general GPG information
You can run this container interactively to run the following commands. To do so, just run the following command to get a shell inside the container
```
docker run -it -v $PWD/keys:/keys redpencil/file-encryption-service /bin/bash
```
*tip*: if you lack entropy for generating a key, you can run `rngd -r /dev/urandom` on the host machine to provide some.

* generate a key: `gpg --gen-key`
* export a public key: `gpg --output gpgkey.gpg --armor --export [key-id]`
* export a private key: `gpg --export-secret-keys [key-id] > file.asc`
* import a private key: `gpg --import [file]`
* decrypt a file: `gpg --decrypt [file]`
