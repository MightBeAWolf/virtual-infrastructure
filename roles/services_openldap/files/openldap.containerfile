# Use the latest Alpine Linux image as the base
FROM alpine:latest as base
# Expose the necessary ports
EXPOSE 389 636

# Install necessary packages
RUN apk --no-cache add \
    openldap \
    openldap-back-mdb \
    openldap-overlay-memberof \
    openldap-clients \
    openssl \
    ca-certificates

COPY  --chmod=0444 sudo.schema /etc/openldap/schema/sudo.schema

from base as installed-openldap-dependencies
CMD ["slapd", "-d", "-256", "-h", "ldaps:/// ldap:///"]

