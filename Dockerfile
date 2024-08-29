FROM uniqdev/android-fastlane:android-jdk17

# Download Flutter SDK
WORKDIR /home/gitpod
RUN git clone -b 3.24.1 https://github.com/flutter/flutter.git
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
# CMD ["/bin/bash"]