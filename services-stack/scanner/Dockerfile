FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

# Default scan settings (can be overridden in docker-compose)
ENV SCAN_DPI=300
ENV ADF_POLL_INTERVAL=2
ENV ADF_LOAD_DELAY=5

# Install scanning tools:
#   sane-utils    - scanimage CLI and SANE library
#   ipp-usb       - bridges USB scanner to HTTP (IPP-over-USB)
#   sane-airscan  - eSCL/AirScan SANE backend (connects via HTTP)
#   img2pdf       - converts scanned images to PDF
#   usbutils      - lsusb for debugging USB passthrough
#   curl          - for eSCL status polling (ADF detection)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        sane-utils \
        ipp-usb \
        sane-airscan \
        img2pdf \
        usbutils \
        curl \
        ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Configure ipp-usb to use a fixed HTTP port
# (so sane-airscan can be statically configured without Avahi)
RUN mkdir -p /etc/ipp-usb && \
    printf '[network]\n  http-min-port = 60000\n  http-max-port = 60001\n  interface = loopback\n  dns-sd = disable\n' \
    > /etc/ipp-usb/ipp-usb.conf

# Configure sane-airscan to connect to the ipp-usb endpoint
# No mDNS/Avahi needed — we point directly at localhost
RUN printf '[devices]\n  HP ScanJet Pro 2600 f1 = http://localhost:60000/eSCL, eSCL\n\n[options]\n  discovery = disable\n' \
    > /etc/sane.d/airscan.conf

# Create directories
RUN mkdir -p /output /scripts /var/lib/scanner /var/run/ipp-usb

# Copy scripts
COPY scripts/ /scripts/
COPY entrypoint.sh /entrypoint.sh

# Set permissions and create convenience symlinks
RUN chmod +x /scripts/*.sh /entrypoint.sh && \
    ln -s /scripts/toggle-color.sh /usr/local/bin/toggle-color && \
    ln -s /scripts/toggle-duplex.sh /usr/local/bin/toggle-duplex && \
    ln -s /scripts/scanner-status.sh /usr/local/bin/scanner-status && \
    # Initialize default modes
    echo "Color" > /var/lib/scanner/color_mode && \
    echo "off" > /var/lib/scanner/duplex_mode

ENTRYPOINT ["/entrypoint.sh"]
