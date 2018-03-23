FROM ruby:2.5.0-alpine3.7

RUN apk update

WORKDIR /app

ADD . /app

RUN apk add --update musl-dev gcc make && DISABLE_SSL=true gem install google_drive && apk del musl-dev gcc make && rm -rf /var/cache/apk/*

ENTRYPOINT ["ruby", "script.rb"]
