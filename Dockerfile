FROM archlinux:base

ENV HOME /home/builder

COPY entrypoint.sh /entrypoint.sh
COPY build.sh /build.sh
COPY ssh_config /ssh_config

RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm --needed --overwrite '*' \
    openssh \
    sudo \
    git \
    fakeroot \
    binutils \
    gcc \
    awk \
    binutils \
    xz \
    libarchive \
    bzip2 \
    coreutils \
    file \
    findutils \
    gettext \
    grep \
    gzip \
    sed \
    ncurses \
    util-linux

ENTRYPOINT ["/entrypoint.sh"]
