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

from base as installed-openldap-dependencies
# # Create the SSL Certificats and sign them
# RUN mkdir /etc/openldap/certs && \
#     openssl genrsa -out /etc/openldap/certs/ldap_server.key 2048 && \
#     openssl req -new \
#         -key /etc/openldap/certs/ldap_server.key \
#         -out /etc/openldap/certs/ldap_server.csr \
#         -subj "/C=US/ST=UT/L=SaltLakeCity/O=Silicon Technologies In/OU=SWIT/CN=ldap.local.silicontech.us" && \
#     openssl x509 -req \
#     -in /etc/openldap/certs/ldap_server.csr \
#         -signkey /etc/openldap/certs/ldap_server.key \
#         -out /etc/openldap/certs/ldap_server.crt \
#         -days 365 && \
#     ln -s /etc/openldap/certs/ldap_server.crt \
#         /usr/local/share/ca-certificates/ldap_server.crt && \
#     update-ca-certificates

# from installed-openldap-dependencies as ssl-certified-openldap
# Collect the LDAP Secrets from the build args
# ARG LDAP_ROOT_DN
# ARG LDAP_ROOT_RAW_PASSWORD

# # Set environment variables
# ENV LDAP_BASE_DN="dc=sti,dc=local" \
#     LDAP_ORGANIZATION="Silicon Technologies" \
#     LDAP_ROOT_DN=$LDAP_ROOT_DN\
#     LDAP_TLS_VERIFY_CLIENT="never"

# # Create slapd.d directory and add the necessary configuration files
# COPY configs/slapd.conf /etc/openldap/slapd.conf
# COPY configs/slapd.ldif /etc/openldap/slapd.ldif
# COPY configs/ldap.conf  /etc/openldap/ldap.conf
# copy ./data.ldif        /etc/openldap/initial.ldif


# RUN sed -i \
#     -e '/structuralObjectClass:/d' \
#     -e '/entryUUID:/d' \
#     -e '/creatorsName:/d' \
#     -e '/createTimestamp:/d' \
#     -e '/entryCSN:/d' \
#     -e '/modifiersName:/d' \
#     -e '/modifyTimestamp:/d' \
#     /etc/openldap/initial.ldif 

# Replace the environment variables in the configuration
# RUN find /etc/openldap -type f -exec sed -i \
#     -e "s/\${LDAP_BASE_DN}/${LDAP_BASE_DN}/g" \
#     -e "s/\${LDAP_ORGANIZATION}/${LDAP_ORGANIZATION}/g" \
#     -e "s/\${LDAP_ROOT_DN}/${LDAP_ROOT_DN}/g" \
#     -e "s/\${LDAP_TLS_VERIFY_CLIENT}/${LDAP_TLS_VERIFY_CLIENT}/g" \
#     {} \;

# RUN HASHED=$(slappasswd -s ${LDAP_ROOT_RAW_PASSWORD} -h {SSHA}); \
#     find /etc/openldap -type f -exec sed -i 's|\${LDAP_ROOT_PASSWORD}'"|$HASHED|g" {} \;

# Start OpenLDAP server
# Note: The protocol for plain ldap:// is being disabled to ensure that
# connections are made through the SSL protocol ldaps:// To re-enable ldap://
# simply specify it in the -h argument value along side the ldaps:/// like so:
# "-h" "ldap:/// ldaps:///"
CMD ["slapd", "-d", "-1", "-h", "ldaps:/// ldap:///"]

