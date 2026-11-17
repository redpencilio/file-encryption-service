FROM debian:trixie-slim

ENV ENCRYPT_INTERVAL=3600 \
    ENCRYPT_AFTER_MINUTES=60 \
    ENCRYPT_RECIPIENT='' \
    ENCRYPT_GLOB='/data/pcaps/*.{pcap,har} /data/hars/*.har' \
    ENCRYPTED_DIR='' \
    GNUPGHOME=/root/.gnupg

# tini: init process for signal handling and zombie reaping.
RUN apt-get update \
 && apt-get install -y --no-install-recommends gnupg tini \
 && rm -rf /var/lib/apt/lists/* \
 && mkdir -p /keys "$GNUPGHOME" \
 && chmod 700 "$GNUPGHOME" \
 # Ask for passphrases on the terminal instead of through a pinentry program,
 # so `docker exec -it ... gpg --decrypt` works without extra setup.
 && echo 'pinentry-mode loopback' > "$GNUPGHOME/gpg.conf"

COPY encrypt.sh /app/encrypt.sh

ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["/app/encrypt.sh"]
