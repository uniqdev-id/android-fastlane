FROM uniqdev/android-fastlane:android-jdk17

COPY debug.sh /user/local/bin/
RUN chmod +x /user/local/bin/debug.sh

# Download Flutter SDK
WORKDIR /home/gitpod

# Adding path: Flutter & Adb
ENV PATH "$PATH:$ANDROID_HOME/platform-tools/"

# install tailscale for networking
RUN curl -fsSL https://tailscale.com/install.sh | sh

# Create the gitpod user. UID must be 33333.
RUN useradd -l -u 33333 -G sudo -md /home/gitpod -s /bin/bash -p gitpod gitpod

# Update directory permission
RUN chown -R gitpod:gitpod /home/gitpod/

USER gitpod