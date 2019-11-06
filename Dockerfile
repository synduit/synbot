FROM node:0.10.48-slim

COPY . /synbot

WORKDIR /synbot

RUN npm install

CMD ["bin/hubot", "--name", "synbot", "-a", "slack"]
