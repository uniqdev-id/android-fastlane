FROM uniqdev/android-fastlane:android-jdk17

# Download Flutter SDK
WORKDIR /home/gitpod
RUN git clone -b 3.24.1 https://github.com/flutter/flutter.git
# RUN ./flutter/bin/flutter --version

# Adding path: Flutter & Adb
ENV PATH "$PATH:/home/gitpod/flutter/bin:$ANDROID_HOME/platform-tools/"

# install tailscale for networking
RUN curl -fsSL https://pkgs.tailscale.com/stable/debian/bullseye.noarmor.gpg | sudo tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null
RUN curl -fsSL https://pkgs.tailscale.com/stable/debian/bullseye.tailscale-keyring.list | sudo tee /etc/apt/sources.list.d/tailscale.list
RUN apt-get update && apt-get install -y tailscale 

# Create the gitpod user. UID must be 33333.
RUN useradd -l -u 33333 -G sudo -md /home/gitpod -s /bin/bash -p gitpod gitpod

# Update directory permission
RUN chown -R gitpod:gitpod /home/gitpod/

USER gitpod