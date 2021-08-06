#openjdk:8-jdk
FROM openjdk:11.0-jdk

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
RUN apt-get --quiet install --yes wget tar unzip lib32stdc++6 lib32z1 build-essential ruby ruby-dev
# We use this for xxd hex->binary
RUN apt-get --quiet install --yes vim-common

# install Android SDK
RUN curl -s https://dl.google.com/android/repository/sdk-tools-linux-${VERSION_SDK_TOOLS}.zip > /sdk.zip && \
    unzip /sdk.zip -d /sdk && \
    rm -v /sdk.zip

# RUN mkdir -p $ANDROID_HOME/licenses/ \
#   && echo "8933bad161af4178b1185d1a37fbf41ea5269c55\nd56f5187479451eabf01fb78af6dfcb131a6481e" > $ANDROID_HOME/licenses/android-sdk-license \
#   && echo "84831b9409646a918e30573bab4c9c91346d8abd" > $ANDROID_HOME/licenses/android-sdk-preview-license

RUN mkdir -p $ANDROID_HOME/licenses/
RUN cp licenses/android-sdk-license $ANDROID_HOME/licenses/android-sdk-license \
    && cp licenses/android-sdk-preview-license $ANDROID_HOME/licenses/android-sdk-preview-license

#RUN yes | $ANDROID_HOME/tools/bin/sdkmanager "platforms;android-28"
RUN yes | $ANDROID_HOME/tools/bin/sdkmanager --licenses

ADD packages.txt /sdk
RUN mkdir -p /root/.android && \
  touch /root/.android/repositories.cfg && \
  ${ANDROID_HOME}/tools/bin/sdkmanager --update

RUN while read -r package; do PACKAGES="${PACKAGES}${package} "; done < /sdk/packages.txt && \
    ${ANDROID_HOME}/tools/bin/sdkmanager ${PACKAGES}

# install Fastlane
#COPY Gemfile.lock .
COPY Gemfile .
RUN gem install bundle
RUN bundle install

RUN apt-get update && \
      apt-get -y install sudo

#install firebase cli
RUN curl -sL firebase.tools | bash

# RUN fastlane add_plugin firebase_app_distribution
