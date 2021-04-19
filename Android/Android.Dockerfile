FROM openjdk:8

WORKDIR project/

# Install Build Essentials
RUN apt-get update \
    && apt-get install build-essential -y

# Set Environment Variables
ENV SDK_URL="https://dl.google.com/android/repository/commandlinetools-linux-6200805_latest.zip" \
    ANDROID_SDK_ROOT="/opt/android" \
    ANDROID_VERSION=29 

# Download Android SDK
RUN mkdir -p $ANDROID_SDK_ROOT \
    && curl -o sdk.zip $SDK_URL \
    && unzip sdk.zip -d $ANDROID_SDK_ROOT \
    && yes | $ANDROID_SDK_ROOT/tools/bin/sdkmanager --licenses --sdk_root=$ANDROID_SDK_ROOT

RUN mkdir $ANDROID_SDK_ROOT/licenses || true
RUN echo "24333f8a63b6825ea9c5514f83c2829b004d1fee" > $ANDROID_SDK_ROOT/licenses/android-sdk-license

# Install Android Build Tool and Libraries
RUN yes | $ANDROID_SDK_ROOT/tools/bin/sdkmanager --update --sdk_root=$ANDROID_SDK_ROOT 
RUN yes | $ANDROID_SDK_ROOT/tools/bin/sdkmanager 'build-tools;29.0.2' 'platform-tools' 'platforms;android-29' --sdk_root=$ANDROID_SDK_ROOT 
ENV PATH="/opt/android/tools/bin:${PATH}"

# Install Nodejs
ARG NODE_VERSION=14.16.0
ARG NODE_PACKAGE=node-v$NODE_VERSION-linux-x64
ARG NODE_HOME=/opt/$NODE_PACKAGE

ENV NODE_PATH $NODE_HOME/lib/node_modules
ENV PATH $NODE_HOME/bin:$PATH

RUN curl https://nodejs.org/dist/v$NODE_VERSION/$NODE_PACKAGE.tar.gz | tar -xzC /opt/

CMD ["/bin/bash"]