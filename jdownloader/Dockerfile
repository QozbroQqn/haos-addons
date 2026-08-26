ARG BUILD_FROM
FROM $BUILD_FROM

# The base image declares /output as a volume, so it cannot be redirected to
# the HAOS share. Instead the share is mapped as-is and the download target
# folder is created here, ready to be picked in JDownloader's settings.
COPY rootfs/ /
RUN chmod +x /etc/cont-init.d/55-haos-share.sh
