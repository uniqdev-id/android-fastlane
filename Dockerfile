FROM uniqdev/android-fastlane:flutter-jdk11-3.24.1

# install tailscale for networking
RUN curl -fsSL https://pkgs.tailscale.com/stable/debian/bullseye.noarmor.gpg | sudo tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null
RUN curl -fsSL https://pkgs.tailscale.com/stable/debian/bullseye.tailscale-keyring.list | sudo tee /etc/apt/sources.list.d/tailscale.list

RUN apt-get update && apt-get install -y tailscale     
RUN apt-get install -y jq

COPY pair.sh /usr/bin/pair
RUN chmod 0755 /usr/bin/pair

ENV PATH="${PATH}:/home/gitpod/developer/flutter/bin:/sdk/platform-tools"

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
RUN chown -R gitpod:gitpod /sdk
USER gitpod
