FROM alpine:latest

COPY . /app

WORKDIR /app

RUN apk add py3-pip
RUN pip3 install -r requirements.txt

EXPOSE 80

CMD [ "python", "app.py" ]
