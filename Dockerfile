FROM alpine

# Use to cache bust system dependencies
ENV LAST_UPDATED 2021-08-03

# Install Doppler CLI and kubectl
RUN wget -q -t3 'https://packages.doppler.com/public/cli/rsa.8004D9FF50437357.key' -O /etc/apk/keys/cli@doppler-8004D9FF50437357.rsa.pub && \
    echo 'https://packages.doppler.com/public/cli/alpine/any-version/main' | tee -a /etc/apk/repositories && \
    apk add doppler bind-tools gnupg && \
    \
    wget -O /usr/local/bin/kubectl "https://dl.k8s.io/release/$(wget --quiet -O - https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \
    && chmod +x /usr/local/bin/kubectl

WORKDIR /usr/src/app
COPY ./bin/docker-creds-sync.sh ./bin/docker-creds-sync.sh

CMD ["./bin/docker-creds-sync.sh"]
