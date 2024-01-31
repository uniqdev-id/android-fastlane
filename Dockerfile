#openjdk:8-jdk
FROM openjdk:11.0-jdk-slim

# Just matched `app/build.gradle`
ENV ANDROID_COMPILE_SDK "28"
# Just matched `app/build.gradle`
ENV ANDROID_BUILD_TOOLS "29.0.2"
# Version from https://developer.android.com/studio/releases/sdk-tools
ENV ANDROID_SDK_TOOLS "24.4.1"
#4333796
ENV VERSION_SDK_TOOLS "7583922_latest"
ENV ANDROID_HOME "/sdk"
ENV PATH "$PATH:${ANDROID_HOME}/tools"

# install OS packages
RUN apt-get --quiet update --yes
RUN apt-get --quiet install --yes wget tar unzip lib32stdc++6 lib32z1 build-essential ruby ruby-dev curl sudo jq git
# We use this for xxd hex->binary
RUN apt-get --quiet install --yes vim-common

# install tailscale for networking
RUN curl -fsSL https://pkgs.tailscale.com/stable/debian/bullseye.noarmor.gpg | sudo tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null
RUN curl -fsSL https://pkgs.tailscale.com/stable/debian/bullseye.tailscale-keyring.list | sudo tee /etc/apt/sources.list.d/tailscale.list
RUN apt-get update && apt-get -y install tailscale

RUN gem install bundler:1.17.3
# install Fastlane
COPY Gemfile Gemfile.lock ./
# RUN gem install bundle
RUN bundle update && bundle install 

#install firebase cli
RUN curl -sL firebase.tools | bash

RUN useradd -l -u 33333 -G sudo -md /home/gitpod -s /bin/bash -p gitpod gitpod
RUN mkdir /sdk && mkdir /install && mkdir /tools
RUN chown -R gitpod /sdk && chown -R gitpod /install && chown -R gitpod /tools
USER gitpod

# install Android SDK
RUN curl -s https://dl.google.com/android/repository/commandlinetools-linux-${VERSION_SDK_TOOLS}.zip > /install/sdk.zip && \
    unzip /install/sdk.zip -d ${ANDROID_HOME} && \
    rm -v /install/sdk.zip

RUN mkdir -p $ANDROID_HOME/licenses/
ADD licenses/* $ANDROID_HOME/licenses

RUN mkdir -p $ANDROID_HOME/cmdline-tools/latest
RUN cp -r $ANDROID_HOME/licenses/. $ANDROID_HOME
RUN ls -al $ANDROID_HOME

RUN cp -r $ANDROID_HOME/cmdline-tools/. /tools/
RUN cp -r /tools/. $ANDROID_HOME/cmdline-tools/latest/

RUN echo "Print sdkmanager version"
RUN $ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager --version
RUN yes | $ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager --sdk_root=${ANDROID_HOME} --licenses

ADD packages.txt ${ANDROID_HOME}
RUN ${ANDROID_HOME}/cmdline-tools/latest/bin/sdkmanager --sdk_root=${ANDROID_HOME}  --update

RUN while read -r package; do PACKAGES="${PACKAGES}${package} "; done < /sdk/packages.txt && \
    ${ANDROID_HOME}/cmdline-tools/latest/bin/sdkmanager --sdk_root=${ANDROID_HOME} ${PACKAGES}

ENV PATH="$PATH:${ANDROID_HOME}/cmdline-tools/latest/bin/:${ANDROID_HOME}/platform-tools/"