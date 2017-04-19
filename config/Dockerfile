FROM library/ruby:2.3.1
MAINTAINER Flavio Castelli <fcastelli@suse.com>

ENV COMPOSE=1
EXPOSE 3000

WORKDIR /portus

COPY Gemfile* ./

RUN bundle install --retry=3 && bundle binstubs phantomjs

RUN apt-get update && \
    apt-get install -y --no-install-recommends nodejs

RUN apt-get install -y apt-transport-https && \
    curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list && \
    apt-get update && \
    curl -sL https://deb.nodesource.com/setup_6.x | bash - && \
    apt-get install -y nodejs

RUN apt-get install -y yarn

RUN yarn install

RUN cd portus && npm install webpack -g

RUN webpack --watch --config config/webpack.js

ADD . .