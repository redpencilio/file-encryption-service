FROM ubuntu:16.04
ENV ENCRYPT_INTERVAL=3600
ENV ENCRYPT_AFTER_MINUTES=60
ENV ENCRYPT_RECIPIENT=''
ENV ENCRYPT_GLOB='/data/pcaps/*.{pcap,har} /data/hars/*.har'
RUN apt-get update -y && apt-get install gpgv && mkdir -p /keys
COPY encrypt.sh /app/encrypt.sh
CMD ["/app/encrypt.sh"]
