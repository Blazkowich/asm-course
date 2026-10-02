# test-env/Dockerfile
# Assembly-ის სასწავლო კურსის სრული გარემო
# Build:  docker buildx build -t asm-course .
# Run:    docker run --rm -it -v "$PWD/..:/work" asm-course

FROM ubuntu:22.04

LABEL maintainer="asm-course"
LABEL description="x86-64 NASM learning environment"

# ინტერაქტიული prompt-ების გამორთვა
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# ძირითადი ინსტრუმენტები
RUN apt-get update && apt-get install -y --no-install-recommends \
    nasm \
    binutils \
    gcc \
    gcc-multilib \
    gdb \
    libc6-dev \
    libc6-dev-i386 \
    strace \
    ltrace \
    make \
    git \
    vim \
    nano \
    less \
    file \
    xxd \
    python3 \
    python3-pip \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# GEF (gdb enhancement) — სურვილისამებრ
# RUN bash -c "$(curl -fsSL https://gef.blah.cat/sh)"

# gdb-ის კონფიგურაცია: Intel სინტაქსი
RUN echo "set disassembly-flavor intel" > /root/.gdbinit \
    && echo "set pagination off" >> /root/.gdbinit

# სამუშაო დირექტორია
WORKDIR /work

# სასარგებლო alias-ები
RUN echo 'alias ll="ls -lah"' >> /root/.bashrc \
    && echo 'alias nasmb="nasm -f elf64 -g -F dwarf"' >> /root/.bashrc \
    && echo 'alias dis="objdump -d -M intel --no-show-raw-insn"' >> /root/.bashrc

# ნაგულისხმევი shell
CMD ["/bin/bash"]