FROM archlinux:latest AS build

WORKDIR /opt/CTFd

# Update system dan install dependensi yang diperlukan
RUN pacman -Sy --noconfirm \
    && pacman -S --noconfirm \
        base-devel \
        libffi \
        openssl \
        git \
        python \
    && pacman -Scc --noconfirm

# Setup Python virtual environment
RUN python -m venv /opt/venv

ENV PATH="/opt/venv/bin:$PATH"

# Salin kode sumber ke dalam kontainer
COPY . /opt/CTFd

# Install dependensi Python
RUN pip install --no-cache-dir -r requirements.txt \
    && for d in CTFd/plugins/*; do \
        if [ -f "$d/requirements.txt" ]; then \
            pip install --no-cache-dir -r "$d/requirements.txt";\
        fi; \
    done;

FROM archlinux:latest AS release
WORKDIR /opt/CTFd

# Install dependensi runtime untuk Arch Linux
RUN pacman -Sy --noconfirm \
    && pacman -S --noconfirm \
        libffi \
        openssl \
    && pacman -Scc --noconfirm

# Salin kode sumber ke dalam kontainer dan set permissions
COPY --chown=1001:1001 . /opt/CTFd

RUN useradd \
    --no-log-init \
    --shell /bin/bash \
    -u 1001 \
    ctfd \
    && mkdir -p /var/log/CTFd /var/uploads \
    && chown -R 1001:1001 /var/log/CTFd /var/uploads /opt/CTFd \
    && chmod +x /opt/CTFd/docker-entrypoint.sh

# Salin environment virtual Python dari build stage
COPY --chown=1001:1001 --from=build /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

USER 1001
EXPOSE 7000
ENTRYPOINT ["/opt/CTFd/docker-entrypoint.sh"]
