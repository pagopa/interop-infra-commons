#default value for compatibility
ARG NODE_REGISTRY="docker.io"

FROM ${NODE_REGISTRY}/node:20.19.4-slim@sha256:6db5e436948af8f0244488a1f658c2c8e55a3ae51ca2e1686ed042be8f25f70a AS build 

RUN corepack enable

WORKDIR /app
COPY package.json /app/
COPY package-lock.json /app/
RUN npm ci

COPY tsconfig.json /app/
COPY src /app/src
RUN npm run compile


FROM ${NODE_REGISTRY}/node:20.19.4-slim@sha256:6db5e436948af8f0244488a1f658c2c8e55a3ae51ca2e1686ed042be8f25f70a AS final

COPY --from=build /app/dist /app
COPY --from=build /app/node_modules /app/node_modules
COPY --from=build /app/package.json /app/
COPY --from=build /app/package-lock.json /app/

RUN groupadd -r app && useradd -rm -g app app
RUN chown -R app:app /app && chmod -R 700 /app

RUN apt-get update && apt-get install -y \
    openssl \
    libsasl2-2 \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

USER app

WORKDIR /app

CMD ["node", "index.js"]

