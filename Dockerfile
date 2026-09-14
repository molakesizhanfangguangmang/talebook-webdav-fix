# Talebook WebDAV reading-progress event image
FROM talebook/talebook:v26.09.01

COPY dav_provider.py /var/www/talebook/webserver/webdav/dav_provider.py
COPY bridge/ /opt/reading-progress-bridge/
RUN chmod 755 /opt/reading-progress-bridge/trigger.sh

LABEL org.opencontainers.image.title="Talebook with reading progress event bridge"
LABEL org.opencontainers.image.version="v26.09.01-reading-progress.1"
