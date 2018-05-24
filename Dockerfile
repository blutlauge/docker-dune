FROM debian:latest
LABEL maintainer="Marc Schlienger <marc@schlienger.net>"

ENV DEBIAN_FRONTEND noninteractive

# Common packages
RUN apt-get update && apt-get install -y \
    autoconf \
    automake \
    bison \
    build-essential \
    ca-certificates \
    clang \
    cmake \
    curl \
    flex \
    g++ \
    gcc \
    gfortran \
    git \
    gnuplot-nox \
    libadolc-dev \
    libalberta-dev \
    libarpack++2-dev \
    libboost-dev \
    libboost-program-options-dev \
    libboost-serialization-dev \
    libboost-system-dev \
    libeigen3-dev \
    libgmp-dev \
    libltdl-dev \
    libscotchmetis-dev \
    libsuitesparse-dev \
    libsuperlu-dev \
    libtinyxml2-dev \
    libtool \
    libvc-dev \
    locales \
    locales-all \
    mpi-default-bin \
    mpi-default-dev \
    pkg-config \
    python-dev \
    python-numpy \
    python-vtk6 \
    python3 \
    python3-dev \
    python3-matplotlib \
    python3-mpi4py \
    python3-numpy \
    python3-pip \
    python3-pytest \
    python3-scipy \
    zsh \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Locale
ENV LANG de_DE.UTF-8
ENV LANGUAGE de_DE:de
ENV LC_ALL de_DE.UTF-8

# Tini
RUN apt-get install -y curl grep sed dpkg && \
    TINI_VERSION=`curl https://github.com/krallin/tini/releases/latest | grep -o "/v.*\"" | sed 's:^..\(.*\).$:\1:'` && \
    curl -L "https://github.com/krallin/tini/releases/download/v${TINI_VERSION}/tini_${TINI_VERSION}.deb" > tini.deb && \
    dpkg -i tini.deb && \
    rm tini.deb && \
    apt-get clean

# User
RUN useradd -ms /usr/bin/zsh dune
RUN echo 'dune:screencast' | chpasswd

USER dune

# Install Dune and DuMux
RUN mkdir -p /home/dune/modules
WORKDIR /home/dune/modules
ENV DUNE_CONTROL_PATH=.:/home/dune/modules
RUN for MODULES in common geometry grid istl localfunctions; do \
        git clone -b releases/2.6 https://gitlab.dune-project.org/core/dune-$MODULES.git; \
    done \
    && git clone -b releases/2.6 https://gitlab.dune-project.org/extensions/dune-alugrid.git \
    && git clone -b releases/2.6 https://gitlab.dune-project.org/staging/dune-uggrid.git \
    && git clone -b releases/2.6 https://gitlab.dune-project.org/pdelab/dune-pdelab.git \
    && git clone -b releases/2.6 https://gitlab.dune-project.org/staging/dune-functions.git \
    && git clone -b releases/2.6 https://gitlab.dune-project.org/staging/dune-typetree.git \
    && git clone -b releases/2.6 https://gitlab.dune-project.org/staging/dune-python.git \
    && git clone -b releases/2.12 https://git.iws.uni-stuttgart.de/dumux-repositories/dumux.git

COPY opts.gcc /home/dune/modules
RUN ./dune-common/bin/dunecontrol --opts=opts.gcc all

WORKDIR /home/dune

ENTRYPOINT [ "/usr/bin/tini", "--" ]
CMD [ "/bin/bash" ]

