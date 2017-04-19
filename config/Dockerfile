FROM zekiunal/ruby-portus

ENV COMPOSE=1

EXPOSE 3000

WORKDIR /portus

COPY Gemfile* ./

RUN bundle install --retry=3 && bundle binstubs phantomjs

ADD . .

#RUN cd /portus

RUN yarn install

RUN npm install webpack -g

#RUN  rake webpack:compile