# Builder
FROM openjdk:11-jdk-slim AS builder

ENV ANDROID_SDK_ROOT=/opt/android-sdk 
ENV FLUTTER_HOME=/opt/flutter
ENV PATH="$FLUTTER_HOME/bin:$ANDROID_SDK_ROOT/platform-tools:$PATH"
ENV FLUTTER_VERSION='3.16.9'
ENV VERSION_SDK_TOOLS "9123335_latest"

COPY packages.txt .

RUN apt-get update && apt-get install -y wget unzip lib32stdc++6 lib32z1 build-essential ruby ruby-dev --no-install-recommends && \
    wget -O sdk.zip https://dl.google.com/android/repository/commandlinetools-linux-${VERSION_SDK_TOOLS}.zip && \ 
    unzip sdk.zip -d ${ANDROID_SDK_ROOT} && \
    mkdir -p ${ANDROID_SDK_ROOT}/licenses/ && \ 
    cp -r ${ANDROID_SDK_ROOT}/licenses/. ${ANDROID_SDK_ROOT} && \  
    yes | ${ANDROID_SDK_ROOT}/cmdline-tools/bin/sdkmanager --sdk_root=${ANDROID_SDK_ROOT} --licenses && \ 
    ${ANDROID_SDK_ROOT}/cmdline-tools/bin/sdkmanager --sdk_root=${ANDROID_SDK_ROOT} --update && \
    ${ANDROID_SDK_ROOT}/cmdline-tools/bin/sdkmanager --sdk_root=${ANDROID_SDK_ROOT} $(tr '\n' ' ' < packages.txt)

COPY Gemfile ./ 
RUN gem install bundler && bundle install


WORKDIR /opt
RUN wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_$FLUTTER_VERSION-stable.tar.xz && \
    tar xf flutter_linux_*.tar.xz && \ 
    rm flutter_linux_*.tar.xz

# Runtime 
FROM openjdk:11-jdk-slim

COPY --from=builder /opt/android-sdk /opt/android-sdk
COPY --from=builder /opt/flutter /opt/flutter 

ENV PATH="$PATH:/opt/flutter/bin:/opt/android-sdk/platform-tools"
ENV FLUTTER_HOME /opt/flutter

RUN useradd -l -u 33333 -G sudo -md /opt -s /bin/bash -p gitpod gitpod
RUN chown -R gitpod /opt
USER gitpod

# Pre-cache Flutter dependencies early in builder stage 
RUN $FLUTTER_HOME/bin/flutter precache