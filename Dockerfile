FROM archlinux:base@sha256:204e91950fd364961088a01773eee9012243b7e965fed42b1d82d12416190782

ENV HOME /home/builder

RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm --needed --overwrite '*' \
    openssh \
    sudo \
    git \
    fakeroot \
    binutils \
    gcc \
    awk \
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
    util-linux \
    rsync && \
    pacman -Scc --noconfirm

COPY entrypoint.sh /entrypoint.sh
COPY build.sh /build.sh
COPY ssh_config /ssh_config

ENTRYPOINT ["/entrypoint.sh"]
