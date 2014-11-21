
FROM ubuntu:14.04.1
MAINTAINER Sujay Bhowmick <sujaybhowmick@gmail.com>

ENV DEBIAN_FRONTEND noninteractive
ENV DEBCONF_NONINTERACTIVE_SEEN true

#================================================
# Customize sources for apt-get
#================================================
RUN  echo "deb http://archive.ubuntu.com/ubuntu trusty main universe\n" > /etc/apt/sources.list \
  && echo "deb http://archive.ubuntu.com/ubuntu trusty-updates main universe\n" >> /etc/apt/sources.list

#========================
# Miscellaneous packages
#========================
RUN apt-get update -qqy \
  && apt-get -qqy --no-install-recommends install \
    ca-certificates \
    unzip \
    wget \
  && rm -rf /var/lib/apt/lists/*

#=================
# Locale settings
#=================
ENV LANGUAGE en_US.UTF-8
ENV LANG en_US.UTF-8
RUN locale-gen en_US.UTF-8 \
  && dpkg-reconfigure --frontend noninteractive locales \
  && apt-get update -qqy \
  && apt-get -qqy --no-install-recommends install \
    language-pack-en \
  && rm -rf /var/lib/apt/lists/*

#===================
# Timezone settings
#===================
ENV TZ "US/Pacific"
RUN echo "US/Pacific" | sudo tee /etc/timezone \
  && dpkg-reconfigure --frontend noninteractive tzdata

#==============
# VNC and Xvfb
#==============
RUN apt-get update -qqy \
  && apt-get -qqy install \
    x11vnc \
    xvfb \
  && rm -rf /var/lib/apt/lists/* \
  && mkdir -p ~/.vnc \
  && x11vnc -storepasswd secret ~/.vnc/passwd

#===============
# Install CURL
#===============
RUN apt-get update -qqy \
  && apt-get -qqy install \
  curl
  && rm -rf /var/lib/apt/lists/*

#=========
# Java 7
# Minimal runtime used for executing non GUI Java programs
#=========
RUN apt-get update -qqy \
  && apt-get -qqy --no-install-recommends install \
    openjdk-7-jre-headless \
  && rm -rf /var/lib/apt/lists/*

#=======
# Fonts
#=======
RUN apt-get update -qqy \
  && apt-get -qqy --no-install-recommends install \
    fonts-ipafont-gothic \
    xfonts-100dpi \
    xfonts-75dpi \
    xfonts-cyrillic \
    xfonts-scalable \
  && rm -rf /var/lib/apt/lists/*

#==========
# Selenium
#==========
RUN  mkdir -p /opt/selenium \
  && wget --no-verbose http://selenium-release.storage.googleapis.com/2.44/selenium-server-standalone-2.44.0.jar -O /opt/selenium/selenium-server-standalone.jar

#==================
# Maven
#==================
ENV MAVEN_VERSION 3.2.3

RUN curl -sSL http://archive.apache.org/dist/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz | tar xzf - -C /usr/share \
  && mv /usr/share/apache-maven-$MAVEN_VERSION /usr/share/maven \
  && ln -s /usr/share/maven/bin/mvn /usr/bin/mvn

#==================
# Chrome webdriver
#==================
ENV CHROME_DRIVER_VERSION 2.12
RUN cd /tmp \
  && wget --no-verbose -O chromedriver_linux64.zip http://chromedriver.storage.googleapis.com/$CHROME_DRIVER_VERSION/chromedriver_linux64.zip \
  && cd /opt/selenium \
  && rm -rf chromedriver \
  && unzip /tmp/chromedriver_linux64.zip \
  && rm /tmp/chromedriver_linux64.zip \
  && mv /opt/selenium/chromedriver /opt/selenium/chromedriver-$CHROME_DRIVER_VERSION \
  && chmod 755 /opt/selenium/chromedriver-$CHROME_DRIVER_VERSION \
  && ln -fs /opt/selenium/chromedriver-$CHROME_DRIVER_VERSION /usr/bin/chromedriver

#=========
# fluxbox
# A fast, lightweight and responsive window manager
#=========
RUN apt-get update -qqy \
  && apt-get -qqy --no-install-recommends install \
    fluxbox \
  && rm -rf /var/lib/apt/lists/*

#===============
# Google Chrome
#===============
RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
  && echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list \
  && apt-get update -qqy \
  && apt-get -qqy --no-install-recommends install \
    google-chrome-stable \
  && rm -rf /var/lib/apt/lists/* \
  && rm /etc/apt/sources.list.d/google-chrome.list

#=================
# Mozilla Firefox
#=================
RUN apt-get update -qqy \
  && apt-get -qqy --no-install-recommends install \
    firefox \
  && rm -rf /var/lib/apt/lists/*

#========================================
# Add normal user with passwordless sudo
#========================================
RUN sudo useradd seluser --shell /bin/bash --create-home \
  && sudo usermod -a -G sudo seluser \
  && echo 'ALL ALL = (ALL) NOPASSWD: ALL' >> /etc/sudoers

#====================================================================
# Script to run selenium standalone server for Chrome and/or Firefox
#====================================================================
COPY ./bin/start_env.sh /opt/selenium/
COPY ./bin/local-sel-headless.sh /opt/selenium/

RUN  chmod +x /opt/selenium/*.sh

#===========
# DNS stuff
#===========
#COPY ./etc/hosts /tmp/hosts
# Below hack is no longer necessary since docker >= 1.2.0, commented to ease old users transition
#  Poor man /etc/hosts updates until https://github.com/dotcloud/docker/issues/2267
#  Ref: https://stackoverflow.com/questions/19414543/how-can-i-make-etc-hosts-writable-by-root-in-a-docker-container
#  RUN mkdir -p -- /lib-override && cp /lib/x86_64-linux-gnu/libnss_files.so.2 /lib-override
#  RUN perl -pi -e 's:/etc/hosts:/tmp/hosts:g' /lib-override/libnss_files.so.2
#  ENV LD_LIBRARY_PATH /lib-override

#============================
# Some configuration options
#============================
ENV SCREEN_WIDTH 1360
ENV SCREEN_HEIGHT 1020
ENV SCREEN_DEPTH 24
ENV SELENIUM_PORT 4444
ENV DISPLAY :20.0

#================================
# Expose Container's Directories
#================================
VOLUME /var/log

#================================
# Expose Container's Ports
#================================
EXPOSE 4444 5900

#===================
# CMD or ENTRYPOINT
#===================

#start vnc server
CMD ["/opt/selenium/start_env.sh"]