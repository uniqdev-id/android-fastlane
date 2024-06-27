#source https://github.com/corretto/corretto-docker/blob/main/17/jdk/debian/Dockerfile
FROM debian:buster-slim

#11.0.23.9-1 | 17.0.11.9-1
ARG version=17.0.11.9-1
RUN set -eux \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        curl ca-certificates gnupg software-properties-common fontconfig java-common \
    && curl -fL https://apt.corretto.aws/corretto.key | apt-key add - \
    && add-apt-repository 'deb https://apt.corretto.aws stable main' \
    && mkdir -p /usr/share/man/man1 || true \
    && apt-get update \
    && apt-get install -y java-17-amazon-corretto-jdk=1:$version \
    && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
        curl gnupg software-properties-common

ENV LANG C.UTF-8
ENV JAVA_HOME=/usr/lib/jvm/java-17-amazon-corretto

# Just matched `app/build.gradle` | 33
ENV ANDROID_COMPILE_SDK "28" 
# Just matched `app/build.gradle`
ENV ANDROID_BUILD_TOOLS "29.0.2"
# Version from https://developer.android.com/studio/releases/sdk-tools
ENV ANDROID_SDK_TOOLS "24.4.1"
# ENV VERSION_SDK_TOOLS "4333796" | 7583922_latest | 9123335_latest 
ENV VERSION_SDK_TOOLS "9123335_latest"
ENV ANDROID_HOME "/home/gitpod/sdk"
ENV PATH "$PATH:${ANDROID_HOME}/tools"

RUN mkdir -p $ANDROID_HOME

RUN cat /etc/os-release
# install OS packages
RUN apt-get update -y
RUN apt-get --quiet install --yes wget tar unzip lib32stdc++6 lib32z1 build-essential ruby ruby-dev curl git
# We use this for xxd hex->binary
RUN apt-get --quiet install --yes vim-common

# Install dependencies
RUN apt-get update && apt-get install -y \
    wget \
    build-essential \
    libssl-dev \
    libreadline-dev \
    zlib1g-dev

# Download and compile Ruby
ENV RUBY_VERSION 3.0.0
RUN wget https://cache.ruby-lang.org/pub/ruby/3.0/ruby-${RUBY_VERSION}.tar.gz && \
    tar -xzvf ruby-${RUBY_VERSION}.tar.gz && \
    cd ruby-${RUBY_VERSION} && \
    ./configure && \
    make -j$(nproc) && \
    make install

# Clean up
RUN rm -rf ruby-${RUBY_VERSION} ruby-${RUBY_VERSION}.tar.gz

# Verify installation
RUN ruby --version

# install Android SDK
# RUN curl -s https://dl.google.com/android/repository/sdk-tools-linux-${VERSION_SDK_TOOLS}.zip > /sdk.zip && \
#     unzip /sdk.zip -d /sdk && \
#     rm -v /sdk.zip

#https://dl.google.com/android/repository/commandlinetools-linux-9123335_latest.zip
RUN curl -s https://dl.google.com/android/repository/commandlinetools-linux-${VERSION_SDK_TOOLS}.zip > /sdk.zip && \
    unzip /sdk.zip -d $ANDROID_HOME && \
    rm -v /sdk.zip


# RUN mkdir -p $ANDROID_HOME/licenses/ \
#   && echo "8933bad161af4178b1185d1a37fbf41ea5269c55\nd56f5187479451eabf01fb78af6dfcb131a6481e" > $ANDROID_HOME/licenses/android-sdk-license \
#   && echo "84831b9409646a918e30573bab4c9c91346d8abd" > $ANDROID_HOME/licenses/android-sdk-preview-license

RUN mkdir -p $ANDROID_HOME/licenses/
ADD licenses/* $ANDROID_HOME/licenses/

#accept licenses
RUN mkdir -p $ANDROID_HOME/cmdline-tools/latest
RUN cp -r $ANDROID_HOME/licenses/. $ANDROID_HOME
RUN ls -al $ANDROID_HOME
RUN mkdir /tools
RUN cp -r $ANDROID_HOME/cmdline-tools/. /tools/
RUN cp -r /tools/. $ANDROID_HOME/cmdline-tools/latest/
RUN ls -al $ANDROID_HOME/cmdline-tools/latest/bin

# RUN yes | $ANDROID_HOME/tools/bin/sdkmanager "platforms;android-28"
RUN yes | $ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager --licenses

ADD packages.txt $ANDROID_HOME
# RUN mkdir -p /root/.android && \
#   touch /root/.android/repositories.cfg && \
#   ${ANDROID_HOME}/tools/bin/sdkmanager --update

RUN mkdir -p /root/.android && \
  touch /root/.android/repositories.cfg && \
  ${ANDROID_HOME}/cmdline-tools/latest/bin/sdkmanager --update

# RUN while read -r package; do PACKAGES="${PACKAGES}${package} "; done < /workspace/sdk/packages.txt && \
#     ${ANDROID_HOME}/tools/bin/sdkmanager ${PACKAGES}

RUN while read -r package; do PACKAGES="${PACKAGES}${package} "; done < $ANDROID_HOME/packages.txt && \
    ${ANDROID_HOME}/cmdline-tools/latest/bin/sdkmanager ${PACKAGES}

# install Fastlane
RUN gem install bundler
# COPY Gemfile.lock .
COPY Gemfile .
#RUN gem install bundle
# RUN gem install bundler
# RUN gem install bundler:1.17.3
RUN bundle update
# RUN bundle install

RUN ls -al 
# COPY Gemfile.lock .

RUN apt-get update && \
      apt-get -y install sudo

#install firebase cli
RUN curl -sL firebase.tools | bash

# install plugins
#RUN fastlane add_plugin firebase_app_distribution

# Download Flutter SDK
WORKDIR /home/gitpod
#RUN git clone -b stable https://github.com/flutter/flutter.git
RUN git clone -b 3.22.2 https://github.com/flutter/flutter.git
#https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_2.2.3-stable.tar.xz
# RUN ./flutter/bin/flutter --version

# Adding path: Flutter & Adb
ENV PATH "$PATH:/home/gitpod/flutter/bin:$ANDROID_HOME/platform-tools/"

# RUN flutter doctor
RUN flutter --version

# install tailscale for networking
RUN curl -fsSL https://pkgs.tailscale.com/stable/debian/bullseye.noarmor.gpg | sudo tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null
RUN curl -fsSL https://pkgs.tailscale.com/stable/debian/bullseye.tailscale-keyring.list | sudo tee /etc/apt/sources.list.d/tailscale.list

RUN apt-get update && apt-get install -y tailscale     
RUN apt-get install -y jq

# ENV PATH="${PATH}:/workspace/flutter/bin:/workspace/sdk/platform-tools"

# Installing additional apps for development
RUN apt-get install -y python3
# RUN apt install -y chromium

# RUN wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
# RUN dpkg -i google-chrome-stable_current_amd64.deb
# RUN rm google-chrome-stable_current_amd64.deb

# Create the gitpod user. UID must be 33333.
RUN useradd -l -u 33333 -G sudo -md /home/gitpod -s /bin/bash -p gitpod gitpod

# update directory permission
RUN chown -R gitpod:gitpod /home/gitpod/
USER gitpod
