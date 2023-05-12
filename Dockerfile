FROM alpine:latest

WORKDIR .

RUN apk update && apk add --update docker openrc

RUN service docker start

CMD ["rc-update","add","docker","boot"]
