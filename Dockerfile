FROM ruby:2.7.5-alpine3.15

RUN apk add --no-cache build-base

COPY Gemfile Gemfile.lock /usr/src/app/deliveroo.engineering/
WORKDIR /usr/src/app/deliveroo.engineering
RUN gem install bundler && bundle install -j8

EXPOSE 4000
ENTRYPOINT ["jekyll"]
CMD ["serve", "-w", "-t", "-H", "0.0.0.0"]
