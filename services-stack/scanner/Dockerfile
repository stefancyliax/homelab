FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

# Default scan settings (can be overridden in docker-compose)
ENV SCAN_DPI=300
ENV SCAN_MODE=Color
ENV SCANBD_DEBUG=2

# Install scanning tools:
#   sane-utils    - scanimage CLI and SANE library
#   hplip         - HP scanner backend (hpaio) for SANE
#   scanbd        - scanner button daemon (polls physical buttons)
#   img2pdf       - converts scanned images to PDF
#   usbutils      - lsusb for debugging USB passthrough
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        sane-utils \
        hplip \
        hplip-data \
        scanbd \
        img2pdf \
        usbutils \
        ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Configure SANE for standalone scanbd mode:
#
# scanbd uses /etc/scanbd/sane.d/ to find the scanner for button polling.
# scanimage uses /etc/sane.d/ to access the scanner for actual scanning.
# Both configs include the hpaio backend — this works because scanbd
# releases the device before calling the action script.
RUN mkdir -p /etc/scanbd/sane.d/dll.d && \
    cp /etc/sane.d/dll.conf /etc/scanbd/sane.d/dll.conf && \
    cp -r /etc/sane.d/dll.d/. /etc/scanbd/sane.d/dll.d/ 2>/dev/null || true

# Create directories
RUN mkdir -p /output /etc/scanbd/scripts /var/run/scanbd

# Copy configuration and scripts
COPY config/scanbd.conf /etc/scanbd/scanbd.conf
COPY scripts/ /etc/scanbd/scripts/
COPY entrypoint.sh /entrypoint.sh

# Set permissions and create convenience symlinks
RUN chmod +x /etc/scanbd/scripts/*.sh /entrypoint.sh && \
    ln -s /etc/scanbd/scripts/toggle-color.sh /usr/local/bin/toggle-color && \
    ln -s /etc/scanbd/scripts/test-buttons.sh /usr/local/bin/test-buttons && \
    # Initialize default color mode
    echo "Color" > /etc/scanbd/color_mode

ENTRYPOINT ["/entrypoint.sh"]
