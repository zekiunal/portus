FROM zekiunal/ruby-portus

ENV COMPOSE=1

EXPOSE 3000

WORKDIR /portus

COPY Gemfile* ./

RUN bundle install --retry=3 && bundle binstubs phantomjs

ADD . .

RUN yarn install

#RUN npm install  && npm install webpack -g

#RUN rake webpack:compile