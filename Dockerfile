FROM ruby:2.5.1-alpine3.7

RUN apk add --no-cache build-base
RUN gem install bundler

COPY . /usr/src/app/deliveroo.engineering
WORKDIR /usr/src/app/deliveroo.engineering

RUN bundle install
