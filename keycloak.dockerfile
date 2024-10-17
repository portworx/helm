FROM registry.access.redhat.com/ubi9/ubi-minimal as nc-builder

RUN microdnf install -y nc && microdnf clean all

FROM portworx/keycloak:25.0.2:25.0.2

USER root

COPY --from=nc-builder /bin/nc /usr/bin/nc

COPY --from=nc-builder /lib64/libssl.so.3 /lib64/
COPY --from=nc-builder /lib64/libcrypto.so.3 /lib64/
COPY --from=nc-builder /lib64/libpcap.so.1 /lib64/
COPY --from=nc-builder /lib64/libibverbs.so.1 /lib64/
COPY --from=nc-builder /lib64/libnl-route-3.so.200 /lib64/
COPY --from=nc-builder /lib64/libnl-3.so.200 /lib64/

RUN chmod +x /usr/bin/nc

USER 1000