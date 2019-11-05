FROM node:10.17.0-alpine

COPY . /synbot

WORKDIR /synbot

RUN npm install

CMD ["bin/hubot", "--name", "synbot", "-a", "slack"]
