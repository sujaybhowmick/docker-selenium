#!/usr/bin/env bash

sudo -E -i -u seluser \
    DOCKER_HOST_IP=$DOCKER_HOST_IP \
    java -jar /opt/selenium/selenium-server-standalone.jar -port $SELENIUM_PORT 2>&1 | tee $SELENIUM_LOG