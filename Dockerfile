#openjdk:8-jdk
FROM openjdk:11.0-jdk

# install OS packages
RUN apt-get --quiet update --yes
RUN apt-get --quiet install --yes wget tar unzip lib32stdc++6 lib32z1 build-essential ruby ruby-dev
# We use this for xxd hex->binary
RUN apt-get --quiet install --yes vim-common

# https://developer.android.com/studio#cmdline-tools
# ENV VERSION_SDK_TOOLS "7583922_latest"
ENV VERSION_SDK_TOOLS "9123335_latest"
ENV ANDROID_HOME "/sdk"
ENV PATH "$PATH:${ANDROID_HOME}/tools"

RUN mkdir -p $ANDROID_HOME

# Install Android SDK
RUN curl -s https://dl.google.com/android/repository/commandlinetools-linux-${VERSION_SDK_TOOLS}.zip > /sdk.zip && \
    unzip /sdk.zip -d $ANDROID_HOME && \
    rm -v /sdk.zip

# Set up Android SDK
RUN mkdir -p $ANDROID_HOME/licenses/
COPY licenses/* $ANDROID_HOME/licenses/

RUN mkdir -p $ANDROID_HOME/cmdline-tools/latest
RUN mkdir -p /tmp/android
RUN cp -r $ANDROID_HOME/cmdline-tools/. /tmp/android/ 
RUN cp -r /tmp/android/. $ANDROID_HOME/cmdline-tools/latest/
RUN rm -rf /tmp/android
RUN yes | $ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager --licenses

COPY packages.txt $ANDROID_HOME/
RUN mkdir -p /root/.android && \
    touch /root/.android/repositories.cfg && \
    $ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager --update

RUN while read -r package; do PACKAGES="${PACKAGES}${package} "; done < $ANDROID_HOME/packages.txt && \
    $ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager --install ${PACKAGES}

# install Fastlane
COPY Gemfile.lock .
COPY Gemfile .
# RUN gem install bundle
RUN gem install bundler:1.17.3
# RUN bundle install
RUN bundle update
RUN bundle install

RUN apt-get update && \
      apt-get -y install sudo

#install firebase cli
RUN curl -sL firebase.tools | bash

# RUN fastlane add_plugin firebase_app_distribution
