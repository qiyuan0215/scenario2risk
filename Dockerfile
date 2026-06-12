FROM rocker/r-ver:4.5.1

RUN apt-get update && apt-get install -y --no-install-recommends \
    g++ \
    make \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /pkg

COPY . /pkg

RUN R -q -e "install.packages('remotes', repos = 'https://cloud.r-project.org')" \
    && R -q -e "remotes::install_local('/pkg', upgrade = 'never', dependencies = TRUE)"

CMD ["R"]
