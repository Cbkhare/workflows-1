ARG REGISTRY
FROM $REGISTRY/debian:base
COPY grub.default /tmp/
COPY cleanup.sh /
ENTRYPOINT ["./cleanup.sh"]

