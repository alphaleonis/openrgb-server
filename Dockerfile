FROM debian:bookworm AS builder

RUN apt update && \
    apt install -y git build-essential qtcreator qtbase5-dev qtchooser qt5-qmake qtbase5-dev-tools libusb-1.0-0-dev libhidapi-dev pkgconf libmbedtls-dev qttools5-dev-tools

RUN git clone https://gitlab.com/CalcProgrammer1/OpenRGB /app
WORKDIR /app

ARG OPENRGB_VERSION
RUN git fetch --tags && \
    if [ -z "$OPENRGB_VERSION" ]; then \
        git checkout master; \
    elif git rev-parse "$OPENRGB_VERSION^{tag}" >/dev/null 2>&1; then \
        echo "Checking out tag: $OPENRGB_VERSION"; \
        git checkout "$OPENRGB_VERSION"; \        
    else \
        echo "Error: Invalid OPENRGB_VERSION specified. '$OPENRGB_VERSION' does not exist." >&2; \
        exit 1; \
    fi


RUN qmake OpenRGB.pro
RUN make -j$(nproc)
RUN /app/scripts/build-udev-rules.sh /app

FROM debian:bookworm-slim

LABEL org.opencontainers.image.source=https://github.com/alphaleonis/openrgb-server

RUN apt update && \
    apt install -y \
    i2c-tools \
    libusb-1.0-0 \
    libhidapi-dev \
    libmbedtls-dev \
    libqt5gui5 \
    tini


RUN mkdir /config

WORKDIR /app

RUN mkdir -p /usr/lib/udev/rules.d 
COPY --from=builder /app/openrgb .
COPY --from=builder /app/60-openrgb.rules /usr/lib/udev/rules.d

ENTRYPOINT [ "/usr/bin/tini", "--", "/app/openrgb", "--server", "--config", "/config" ]
