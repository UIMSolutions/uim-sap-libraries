FROM dlang2/dmd-ubuntu:2.111.0 AS build

WORKDIR /app

COPY dub.sdl dub.selections.json ./
COPY source ./source

RUN dub build --build=release

FROM ubuntu:24.04

RUN apt-get update \
    && apt-get install -y --no-install-recommends libssl3 ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/uim-sap-oau

COPY --from=build /app/build/uim-oau-service ./uim-oau-service

ENV OAU_HOST=0.0.0.0 \
    OAU_PORT=8090 \
    OAU_BASE_PATH=/api/oau

EXPOSE 8090

CMD ["./uim-oau-service"]
