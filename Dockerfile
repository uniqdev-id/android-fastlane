FROM uniqdev/android-fastlane:android-jdk17


# Download Flutter SDK
WORKDIR /home/gitpod/developer
RUN git clone -b 3.29.0 https://github.com/flutter/flutter.git
RUN ./flutter/bin/flutter --version

ENV PATH "$PATH:/home/gitpod/developer/flutter/bin"
