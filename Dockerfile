FROM node:alpine
WORKDIR /app
USER root
ENV PATH /app/node_modules/.bin:$PATH
COPY package.json ./
COPY package-lock.json ./
RUN mkdir -p /app/node_modules
RUN chown node:node /app/node_modules
RUN npm i
COPY . ./
CMD ["npm","start"]