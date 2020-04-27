FROM python:3.7-slim-buster
LABEL maintainer="rsanchezavalos"
ENV PROJECT_NAME pipeline

# Never prompt the user for choices on installation/configuration of packages
ENV DEBIAN_FRONTEND noninteractive
ENV TERM linux

# Airflow
ARG AIRFLOW_VERSION=1.10.9
ENV AIRFLOW_HOME=/usr/local/airflow
ENV AIRFLOW_DAGS_WORKSPACE=${AIRFLOW_HOME} \
    # AIRFLOW_DAGS_DIR=${AIRFLOW_HOME}/${PROJECT_NAME}/${PROJECT_NAME}/dags/ \
    AIRFLOW_FERNET_KEY=some_very_secret_key \
    AIRFLOW_WEBSERVER_SECRET_KEY=some_very_very_secret_key
ARG AIRFLOW_DEPS=""
ARG PYTHON_DEPS=""

# Define en_US.
ENV LANGUAGE en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8
ENV LC_CTYPE en_US.UTF-8
ENV LC_MESSAGES en_US.UTF-8

RUN echo "America/New_York" > /etc/timezone
RUN dpkg-reconfigure -f noninteractive tzdata

RUN set -ex \
    && buildDeps=' \
        freetds-dev \
        libkrb5-dev \
        libsasl2-dev \
        libssl-dev \
        libffi-dev \
        libpq-dev \
        git \
    ' \
    && apt-get update -yqq \
    && apt-get upgrade -yqq \
    && apt-get install -yqq --no-install-recommends \
        $buildDeps \
        freetds-bin \
        build-essential \
        default-libmysqlclient-dev \
        apt-utils \
        curl \
        rsync \
        netcat \
        locales \
    && sed -i 's/^# en_US.UTF-8 UTF-8$/en_US.UTF-8 UTF-8/g' /etc/locale.gen \
    && locale-gen \
    && update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 \
    && useradd -ms /bin/bash -d ${AIRFLOW_HOME} airflow \
    && pip install -U pip setuptools wheel \
    && pip install pytz \
    && pip install pyOpenSSL \
    && pip install ndg-httpsclient \
    && pip install pyasn1 \
    && pip install apache-airflow[crypto,celery,postgres,hive,jdbc,mysql,ssh${AIRFLOW_DEPS:+,}${AIRFLOW_DEPS}]==${AIRFLOW_VERSION} \
    && pip install 'redis==3.2' \
    && if [ -n "${PYTHON_DEPS}" ]; then pip install ${PYTHON_DEPS}; fi \
    && apt-get purge --auto-remove -yqq $buildDeps \
    && apt-get autoremove -yqq --purge \
    && apt-get clean \
    && rm -rf \
        /var/lib/apt/lists/* \
        /tmp/* \
        /var/tmp/* \
        /usr/share/man \
        /usr/share/doc \
        /usr/share/doc-base


RUN apt-get update --fix-missing && \
    apt-get -y install \
        wget \
        bzip2 \
        ca-certificates \
        libxext6 \
        libsm6 \
        libxrender1 \
        libpq-dev \
        libsasl2-dev \
        libssl-dev \
        libkrb5-dev \
        libffi-dev \
        libxml2-dev \
        libxslt-dev \
        default-libmysqlclient-dev\
        python-numpy

RUN set -ex \
    && buildDeps=' \
        freetds-dev \
        libkrb5-dev \
    ' \
    && apt-get update -yqq \
    && apt-get upgrade -yqq \
    && apt-get install -yqq --no-install-recommends \
        freetds-bin \
        build-essential \
        default-libmysqlclient-dev \
        apt-utils \
        rsync \
    && sed -i 's/^# en_US.UTF-8 UTF-8$/en_US.UTF-8 UTF-8/g' /etc/locale.gen \
    && locale-gen \
    && update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 \
    && pip install -U pip setuptools\
    && pip install pytz \
    && pip install pyOpenSSL \
    && pip install ndg-httpsclient \
    && pip install pyasn1 \
    && pip install 'redis==3.2' \
    && apt-get purge --auto-remove -yqq $buildDeps \
    && apt-get autoremove -yqq --purge \
    && apt-get clean \
    && rm -rf \
        /var/lib/apt/lists/* \
        /tmp/* \
        /var/tmp/* \
        /usr/share/man \
        /usr/share/doc \
        /usr/share/doc-base

RUN apt-get update && \
      apt-get -y install sudo

# Install project
ADD . ${AIRFLOW_HOME}/
WORKDIR ${AIRFLOW_HOME}

# Config
COPY dags/config/ ${AIRFLOW_HOME}
COPY bin/ ${AIRFLOW_HOME}

# Workdir
COPY bin/entrypoint.sh /entrypoint.sh
COPY dags/config/airflow.cfg ${AIRFLOW_HOME}/airflow.cfg

# Install dependencies
RUN pip install -r requirements-pip.txt

# User workspace
RUN echo "airflow:airflow" | chpasswd && adduser airflow sudo
RUN groupadd project
RUN usermod -a -G project airflow
CMD chown -R airflow:project ${AIRFLOW_HOME}
RUN chmod -R 777  ${AIRFLOW_HOME}
RUN chown -R airflow: ${AIRFLOW_HOME}
RUN chmod +x entrypoint.sh
EXPOSE 8080 5555 8793

# User
USER airflow
WORKDIR ${AIRFLOW_HOME}
ENTRYPOINT ["sh", "/entrypoint.sh"]
CMD ["webserver"]
