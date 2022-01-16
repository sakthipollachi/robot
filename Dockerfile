FROM alpine:3.11

MAINTAINER Open Source Services [opensourceservices.fr]

# Install needed packages. Notes:
#   * dumb-init: a proper init system for containers, to reap zombie children
#   * musl: standard C library
#   * linux-headers: commonly needed, and an unusual package name from Alpine.
#   * build-base: used so we include the basic development packages (gcc)
#   * bash: so we can access /bin/bash
#   * git: to ease up clones of repos
#   * ca-certificates: for SSL verification during Pip and easy_install
#   * python: the binaries themselves
#   * python-dev: are used for gevent e.g.
#   * py2-setuptools: required only in major version 2, installs easy_install so we can install Pip.
ENV PACKAGES=" \
  dumb-init \
  musl \
  linux-headers \
  build-base \
  bash \
  git \
  ca-certificates \
  python2 \
  python2-dev \
  py2-setuptools \
  py-pillow \
  chromium \
  chromium-chromedriver \
  openjdk8-jre \
"

ENV SELENIUM_VERSION 3.141.0
ENV ROBOT_FRAMEWORK_VERSION 3.1.2
ENV SELENIUM_LIBRARY_VERSION 3.2.0
ENV SELENIUM_2_LIBRARY_VERSION 3.0.0
ENV ROBOT_EXECUTION_DIR /opt/robotframework

# Define the default user who'll run the tests
ENV ROBOT_UID 1000
ENV ROBOT_GID 1000

RUN echo \
  # replacing default repositories with edge ones
  && echo "http://dl-cdn.alpinelinux.org/alpine/edge/testing" > /etc/apk/repositories \
  && echo "http://dl-cdn.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories \
  && echo "http://dl-cdn.alpinelinux.org/alpine/edge/main" >> /etc/apk/repositories \

  # Add the packages, with a CDN-breakage fallback if needed
  && apk add --no-cache $PACKAGES || \
    (sed -i -e 's/dl-cdn/dl-4/g' /etc/apk/repositories && apk add --no-cache $PACKAGES) \

  # turn back the clock -- so hacky!
  && echo "http://dl-cdn.alpinelinux.org/alpine/v3.11/main/" > /etc/apk/repositories \

  # make some useful symlinks that are expected to exist
  && if [[ ! -e /usr/bin/python ]];        then ln -sf /usr/bin/python2.7 /usr/bin/python; fi \
  && if [[ ! -e /usr/bin/python-config ]]; then ln -sf /usr/bin/python2.7-config /usr/bin/python-config; fi \
  # && if [[ ! -e /usr/bin/easy_install ]];  then ln -sf /usr/bin/easy_install-2.7 /usr/bin/easy_install; fi \

  # Install and upgrade Pip
  && apk add --update py2-pip \
  && if [[ ! -e /usr/bin/pip ]]; then ln -sf /usr/bin/pip2.7 /usr/bin/pip; fi \

  # Install selenium and associated libraries
  && pip install \
     --no-cache-dir \
     selenium==$SELENIUM_VERSION \
     robotframework==$ROBOT_FRAMEWORK_VERSION \
     robotframework-seleniumlibrary==$SELENIUM_LIBRARY_VERSION \
     robotframework-selenium2library==$SELENIUM_2_LIBRARY_VERSION

  # Setup execution directories
RUN mkdir -p ${ROBOT_EXECUTION_DIR} \
  && mkdir -p ${ROBOT_EXECUTION_DIR}/results \
  && chown ${ROBOT_UID}:${ROBOT_GID} ${ROBOT_EXECUTION_DIR} \
  && chown ${ROBOT_UID}:${ROBOT_GID} ${ROBOT_EXECUTION_DIR}/results \
  && chmod ugo+w ${ROBOT_EXECUTION_DIR} ${ROBOT_EXECUTION_DIR}/results

# Allow any user to write logs
RUN chmod ugo+w /var/log \
  && chown ${ROBOT_UID}:${ROBOT_GID} /var/log \
  && echo \

VOLUME ${ROBOT_EXECUTION_DIR}/test_results

USER ${ROBOT_UID}:${ROBOT_GID}

CMD ["python"]

