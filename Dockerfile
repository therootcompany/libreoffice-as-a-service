FROM node:alpine

RUN apk --no-cache add libreoffice ttf-dejavu

WORKDIR /usr/app
COPY ./ /usr/app
COPY example.env /usr/app/.env
RUN npm install

EXPOSE 5227
CMD [ "npm","start" ]
