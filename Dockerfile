FROM node:10-slim

COPY . /synbot

WORKDIR /synbot

RUN npm install

CMD ["bin/hubot", "--name", "synbot", "-a", "slack"]
