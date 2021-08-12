FROM ruby:2.7.3-buster

RUN apt-get update && apt-get install -y curl vim

RUN curl -L -o fly.tar.gz https://github.com/concourse/concourse/releases/download/v7.3.2/fly-7.3.2-linux-amd64.tgz \
  && tar -xzf fly.tar.gz -C /usr/local/bin/ \
  && rm fly.tar.gz \
  && chmod +x /usr/local/bin/fly

WORKDIR /app

COPY . .

RUN gem update --system
RUN gem install bundler:1.16.1
RUN bundle install

ENTRYPOINT [ "rackup", "--host", "0.0.0.0" ]
