# Sidecar image that runs argocd-cmp-server and contains custom scripts/tools
FROM alpine:3.20

RUN apk add --no-cache bash git curl jq yq helm gettext

# Load CMP config at this exact path in the sidecar
WORKDIR /home/argocd/cmp-server/config
COPY argocd/plugins/microservices/plugin.yaml .

# Copy Init/Generator scripts
WORKDIR /opt/infra-commons
RUN mkdir -p /opt/infra-commons/scripts/helm
COPY scripts/helm/ /opt/infra-commons/scripts/helm
RUN chmod -R +x /opt/infra-commons/scripts/helm

# The CMP server must run as uid 999
USER 999

# Required entrypoint for CMP sidecars
ENTRYPOINT ["/var/run/argocd/argocd-cmp-server"]
