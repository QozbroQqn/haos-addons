ARG BUILD_FROM
FROM $BUILD_FROM

# Install Node.js runtime and build dependencies needed by Strapi and sharp
# Keep minimal: no external DB clients by default (SQLite is the default DB)
RUN apk add --no-cache \
    nodejs npm \
    nano \
    python3 make g++ pkgconf \
    build-base autoconf automake \
    zlib-dev libpng-dev nasm \
    vips-dev git bash rsync

# Copy entrypoint
COPY run.sh /
RUN chmod a+x /run.sh

# Strapi default port
EXPOSE 1337

CMD [ "/run.sh" ]
