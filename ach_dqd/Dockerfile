ARG DEBIAN_CODENAME=buster
FROM debian:${DEBIAN_CODENAME}-slim
ARG DEBIAN_CODENAME
LABEL maintainer="edenceHealth ohdsi-containers <https://edence.health/>"

COPY cran_apt_pubkey.asc /tmp/

# os-level dependencies
RUN set -x \
  && for section in $(seq 1 8); do \
    mkdir "/usr/share/man/man${section}" \
  ; done \
  && AG="env DEBIAN_FRONTEND=noninteractive apt-get -yq" \
  && [ -n "$DEBIAN_CODENAME" ] || exit 1 \
  && $AG update \
  && $AG install --no-install-recommends \
    apt-transport-https \
    ca-certificates \
    gnupg \
  && DEBIAN_CRAN_REPO="${DEBIAN_CODENAME}-cran40" \
  && printf 'deb %s %s\n' \
    "https://cloud.r-project.org/bin/linux/debian" \
    "${DEBIAN_CRAN_REPO}/" \
    >>/etc/apt/sources.list \
  && apt-key add /tmp/cran_apt_pubkey.asc \
  && $AG update \
  && $AG upgrade --no-install-recommends \
  && $AG install --no-install-recommends \
    gcc \
    git \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    locales \
    openjdk-11-jdk-headless \
  && $AG install --no-install-recommends -t "${DEBIAN_CRAN_REPO}" \
    r-base \
    r-base-dev \
    r-cran-littler \
    r-recommended \
  && $AG autoremove \
  && $AG autoclean \
  && $AG clean \
  && rm -rf /var/lib/apt/lists/* /var/lib/dpkg/*-old /var/cache/debconf/*-old \
  && for util in install.r installGithub.r; do \
    ln -s "/usr/lib/R/site-library/littler/examples/${util}" "/bin/${util}" \
  ; done \
  && true

# app-level dependencies
RUN set -x \
  && printf '%s\n' \
    'options(repos=structure(c(CRAN="https://cloud.r-project.org/")))' \
    >/root/.Rprofile \
  && R CMD javareconf \
  && install.r \
    devtools\
    docopt \
    dplyr \
    formatR \
    httr \
    later \
    lubridate \
    mailR \
    openxlsx \
    plyr \
    promises \
    R.oo \
    R.utils \
    readr \
    remotes \
    rjson \
    RJSONIO \
    rlang \
    shiny \
    snow \
    XML \
  && installGithub.r \
    OHDSI/Castor \
    OHDSI/DatabaseConnector \
    OHDSI/DatabaseConnectorJars \
    OHDSI/ParallelLogger \
    OHDSI/SqlRender \
  && rm -rf /tmp/downloaded_packages/ /tmp/*

# Get achilles source code and install it
ARG ACHILLES_VERSION=trunk
RUN set -e \
  ; get_release() { set -x \
    && curl -sSL -o /pkg.tgz "https://github.com/OHDSI/Achilles/archive/v${ACHILLES_VERSION}.tar.gz" \
    && tar -xzf /pkg.tgz \
    && find "Achilles-${ACHILLES_VERSION}" -maxdepth 1 -mindepth 1 -exec 'mv' '{}' './' ';' \
    && rmdir "Achilles-${ACHILLES_VERSION}" \
    && rm /pkg.tgz \
  ; } \
  ; get_trunk() { set -x \
    && git clone "https://github.com/OHDSI/Achilles.git" "__REPO__" \
    && find "__REPO__" -maxdepth 1 -mindepth 1 -exec 'mv' '{}' './' ';' \
    && rmdir "__REPO__" \
  ; } \
  ; mkdir /build \
  ; cd /build \
  ; if [ "$ACHILLES_VERSION" = "trunk" ] \
  ; then get_trunk \
  ; else get_release \
  ; fi \
  ; set -x \
  ; R CMD INSTALL /build \
  ; rm -rf /tmp/downloaded_packages/ /tmp/* /build

# Get dqd source code and install it
ARG DQD_VERSION=trunk
RUN set -e \
  ; get_release() { set -x \
    && curl -sSL -o /pkg.tgz "https://github.com/OHDSI/DataQualityDashboard/archive/v${DQD_VERSION}.tar.gz" \
    && tar -xzf /pkg.tgz \
    && find "DataQualityDashboard-${DQD_VERSION}" -maxdepth 1 -mindepth 1 -exec 'mv' '{}' './' ';' \
    && rmdir "DataQualityDashboard-${DQD_VERSION}" \
    && rm /pkg.tgz \
  ; } \
  ; get_trunk() { set -x \
    && git clone "https://github.com/OHDSI/DataQualityDashboard.git" "__REPO__" \
    && find "__REPO__" -maxdepth 1 -mindepth 1 -exec 'mv' '{}' './' ';' \
    && rmdir "__REPO__" \
  ; } \
  ; mkdir /build \
  ; cd /build \
  ; if [ "$DQD_VERSION" = "trunk" ] \
  ; then get_trunk \
  ; else get_release \
  ; fi \
  ; set -x \
  ; R CMD INSTALL /build \
  ; rm -rf /tmp/downloaded_packages/ /tmp/* /build

ARG ACH_DQD_UID=10001
ARG ACH_DQD_GID=10001

# Create a non-root user with full access to the /app directory
RUN set -x \
  && groupadd -g ${ACH_DQD_GID} achdqd \
  && useradd -u ${ACH_DQD_UID} -g achdqd achdqd \
  && mkdir /output \
  && chown -R achdqd:achdqd /output/

WORKDIR /output

COPY ["achilles.r", "dqd.r", "dqd_viz.r", "ach_and_dqd.r", "entrypoint.sh", "/app/"]

USER ${ACH_DQD_UID}

ENTRYPOINT ["/app/entrypoint.sh"]
