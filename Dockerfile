## ------------------------------- Builder Stage ------------------------------ ##
ARG RESTIC_VERISON="latest"
ARG RCLONE_VERSION="latest"

FROM restic/restic:${RESTIC_VERISON} AS restic
FROM rclone/rclone:${RCLONE_VERSION} AS rclone

## ------------------------------- Production Stage ------------------------------ ##
FROM alpine:latest AS production

WORKDIR /app

COPY --from=restic /usr/bin/restic /usr/bin/
RUN chmod +x /usr/bin/restic

COPY --from=rclone /usr/local/bin/rclone /usr/bin/rclone
RUN chmod +x /usr/bin/rclone

COPY entrypoint.sh .
RUN chmod +x entrypoint.sh

# Set the script as the new ENTRYPOINT
ENTRYPOINT ["./entrypoint.sh"]