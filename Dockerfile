FROM node:10

RUN apt-get update; apt-get install curl -y
RUN apt-get update; apt-get install git -y