FROM selenium/standalone-chrome:4.22.0-20240621

RUN echo $(whoami)
USER root

# install tailscale for networking
RUN curl -fsSL https://pkgs.tailscale.com/stable/debian/bullseye.noarmor.gpg | sudo tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null
RUN curl -fsSL https://pkgs.tailscale.com/stable/debian/bullseye.tailscale-keyring.list | sudo tee /etc/apt/sources.list.d/tailscale.list

RUN apt-get update -y
RUN apt-get --quiet install --yes tar unzip lib32stdc++6 lib32z1 build-essential ruby ruby-dev curl git jq
RUN apt-get update && apt-get install -y \
    wget \
    build-essential \
    libssl-dev \
    libreadline-dev \
    zlib1g-dev \
    vim-common \
    tailscale

#install firebase cli
RUN curl -sL firebase.tools | bash

ENV ANDROID_COMPILE_SDK "28" 
ENV ANDROID_BUILD_TOOLS "29.0.2"
ENV ANDROID_SDK_TOOLS "24.4.1"
ENV VERSION_SDK_TOOLS "9123335_latest"
ENV ANDROID_HOME "/home/gitpod/sdk"
ENV PATH "$PATH:${ANDROID_HOME}/tools"

RUN mkdir -p $ANDROID_HOME

RUN curl -s https://dl.google.com/android/repository/commandlinetools-linux-${VERSION_SDK_TOOLS}.zip > /sdk.zip && \
    unzip /sdk.zip -d $ANDROID_HOME && \
    rm -v /sdk.zip

#accept licenses
RUN mkdir -p $ANDROID_HOME/licenses/
ADD licenses/* $ANDROID_HOME/licenses/    

RUN mkdir -p $ANDROID_HOME/cmdline-tools/latest
RUN cp -r $ANDROID_HOME/licenses/. $ANDROID_HOME
RUN ls -al $ANDROID_HOME
RUN mkdir /tools
RUN cp -r $ANDROID_HOME/cmdline-tools/. /tools/
RUN cp -r /tools/. $ANDROID_HOME/cmdline-tools/latest/
RUN ls -al $ANDROID_HOME/cmdline-tools/latest/bin

RUN yes | $ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager --licenses

ADD packages.txt $ANDROID_HOME
RUN mkdir -p /root/.android && \
  touch /root/.android/repositories.cfg && \
  ${ANDROID_HOME}/cmdline-tools/latest/bin/sdkmanager --update

RUN while read -r package; do PACKAGES="${PACKAGES}${package} "; done < $ANDROID_HOME/packages.txt && \
${ANDROID_HOME}/cmdline-tools/latest/bin/sdkmanager ${PACKAGES}  

COPY pair.sh /usr/bin/pair
RUN chmod 0755 /usr/bin/pair

WORKDIR /home/gitpod

RUN git clone -b 3.22.3 https://github.com/flutter/flutter.git
ENV PATH "$PATH:/home/gitpod/flutter/bin:$ANDROID_HOME/platform-tools/"

# Create the gitpod user. UID must be 33333.
RUN useradd -l -u 33333 -G sudo -md /home/gitpod -s /bin/bash -p gitpod gitpod

# update directory permission
RUN chown -R gitpod:gitpod /home/gitpod/
# USER gitpod

#uid=1200(seluser) gid=1201(seluser) groups=1201(seluser),27(sudo)
USER seluser