FROM ruby:2.5.1-alpine3.7

RUN apk add --no-cache build-base

COPY Gemfile Gemfile.lock /usr/src/app/deliveroo.engineering/
WORKDIR /usr/src/app/deliveroo.engineering
RUN gem install bundler && bundle install -j8

EXPOSE 4000
ENTRYPOINT ["jekyll"]
CMD ["serve", "-w", "-t", "-H", "0.0.0.0"]
