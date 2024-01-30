# Builder
FROM openjdk:11-jdk-slim AS builder

ENV ANDROID_SDK_ROOT=/opt/android-sdk-linux 
ENV FLUTTER_HOME=/opt/flutter
ENV PATH="$FLUTTER_HOME/bin:$ANDROID_SDK_ROOT/platform-tools:$PATH"
ENV FLUTTER_VERSION='3.16.9'

COPY packages.txt ${ANDROID_SDK_ROOT}

RUN apt-get update && apt-get install -y wget unzip lib32stdc++6 lib32z1 --no-install-recommends && \
    wget -O sdk.zip https://dl.google.com/android/repository/commandlinetools-linux-${VERSION_SDK_TOOLS}.zip && \ 
    unzip sdk.zip -d ${ANDROID_SDK_ROOT} && \
    mkdir -p ${ANDROID_SDK_ROOT}/licenses/ && \ 
    cp -r ${ANDROID_SDK_ROOT}/licenses/. ${ANDROID_SDK_ROOT} && \  
    yes | ${ANDROID_SDK_ROOT}/tools/bin/sdkmanager --licenses && \ 
    ${ANDROID_SDK_ROOT}/tools/bin/sdkmanager --update && \
    ${ANDROID_SDK_ROOT}/tools/bin/sdkmanager $(tr '\n' ' ' < packages.txt)

COPY Gemfile Gemfile.lock ./ 

RUN gem install bundler && bundle install

RUN apt update && apt install -y wget unzip

WORKDIR /opt
RUN wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_$FLUTTER_VERSION-stable.tar.xz && \
    tar xf flutter_linux_*.tar.xz && \ 
    rm flutter_linux_*.tar.xz
ENV FLUTTER_HOME /opt/flutter
ENV PATH $PATH:$FLUTTER_HOME/bin

# Pre-cache Flutter dependencies early in builder stage 
RUN $FLUTTER_HOME/bin/flutter precache

# Runtime 
FROM openjdk:11-jdk-slim

COPY --from=builder /opt/android-sdk-linux /opt/android-sdk-linux
COPY --from=builder /opt/flutter /opt/flutter 

ENV PATH="$PATH:/opt/flutter/bin:/opt/android-sdk-linux/platform-tools"

USER gitpod