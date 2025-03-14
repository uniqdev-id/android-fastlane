FROM uniqdev/android-fastlane:android-jdk17

# Download Flutter SDK
WORKDIR /home/gitpod
RUN git clone -b 3.29.2 https://github.com/flutter/flutter.git
# RUN ./flutter/bin/flutter --version

# Install shorebird
curl --proto '=https' --tlsv1.2 https://raw.githubusercontent.com/shorebirdtech/install/main/install.sh -sSf | bash

# Adding path: Flutter & Adb
ENV PATH "$PATH:/home/gitpod/flutter/bin:$ANDROID_HOME/platform-tools/"

# install tailscale for networking
RUN curl -fsSL https://tailscale.com/install.sh | sh

# Create the gitpod user. UID must be 33333.
RUN useradd -l -u 33333 -G sudo -md /home/gitpod -s /bin/bash -p gitpod gitpod

# Update directory permission
RUN chown -R gitpod:gitpod /home/gitpod/

USER gitpod