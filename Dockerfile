FROM eclipse-temurin:17-jdk-alpine

# Set environment variables
ENV ANDROID_COMPILE_SDK "28" 
ENV ANDROID_BUILD_TOOLS "29.0.2"
ENV ANDROID_SDK_TOOLS "24.4.1"
ENV VERSION_SDK_TOOLS "9123335_latest"
ENV ANDROID_HOME "/home/gitpod/sdk"
ENV PATH "$PATH:${ANDROID_HOME}/tools"

# Install necessary packages
RUN apk update && apk add --no-cache \
    wget \
    tar \
    unzip \
    libstdc++ \
    build-base \
    ruby \
    ruby-dev \
    vim \
    sudo \
    curl \
    git \
    python3 \
    jq \
    bash \
    npm

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
    $ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager ${PACKAGES}

# Install Fastlane
RUN gem install bundler
COPY Gemfile .
RUN bundle update

# Install Firebase CLI
# RUN curl -sL https://firebase.tools | bash
RUN npm install -g firebase-tools

# Download Flutter SDK
WORKDIR /home/gitpod
RUN git clone -b 3.24.0 https://github.com/flutter/flutter.git
# RUN ./flutter/bin/flutter --version

# Adding path: Flutter & Adb
ENV PATH "$PATH:/home/gitpod/flutter/bin:$ANDROID_HOME/platform-tools/"

# Install Tailscale (Note: This might not work on Alpine, you may need to find an alternative)
RUN apk add --no-cache tailscale

# Install Chrome (This won't work directly on Alpine, you might need to use Chromium instead)
# RUN apk add --no-cache chromium

# Terminal 
RUN apk update && apk add zsh && apk add git
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
RUN git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

# Create the gitpod user. UID must be 33333.
RUN adduser -D -u 33333 -G wheel -h /home/gitpod -s /bin/bash gitpod && addgroup -g 33333 gitpod && \
    echo "gitpod ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/gitpod

# Update directory permission
RUN chown -R gitpod:gitpod /home/gitpod/

USER gitpod

# Set default command
CMD ["/bin/bash"]