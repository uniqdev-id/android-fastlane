FROM eclipse-temurin:17-jdk

# Set environment variables
ENV ANDROID_COMPILE_SDK "28" 
ENV ANDROID_BUILD_TOOLS "29.0.2"
ENV ANDROID_SDK_TOOLS "24.4.1"
ENV VERSION_SDK_TOOLS "9123335_latest"
ENV ANDROID_HOME "/home/gitpod/sdk"
ENV PATH "$PATH:${ANDROID_HOME}/tools"

# Install necessary packages
RUN apt-get --quiet update --yes
RUN apt-get --quiet install --yes wget \
    tar \
    unzip \
    lib32stdc++6 \
    lib32z1 \
    build-essential \
    ruby \
    ruby-dev \
    npm \
    vim-common \
    jq \
    sudo

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

# Install Fastlane
RUN gem install bundler
COPY Gemfile .
RUN bundle update

# Install Firebase CLI
# RUN curl -sL https://firebase.tools | bash
RUN npm install -g firebase-tools