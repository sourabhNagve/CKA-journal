# dockerfile simple example
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
EXPOSE 3000
CMD ["node", "app.js"]

- FROM: uses the official node18 image as base image.
- WORKDIR: sets /app as the working directory inside the container, all commands run from that folder.
- COPY: copies package.json and package-lock.json into the container first. this helps docker cache the dependency install step better.
- RUN: installs all dependencies listed in package.json inside the container.
- COPY .. : copies the rest of project files into the container.
- EXPOSE: app listens on port 3000. it just documents it and does on actually publish the port by iteself, that is how the app is created.
- CMD: defines default command that runs when the container starts.in this case it starts with node app.js

now you build the image using
docker build -t srvwin/devops:tag 
docker push srvwin/devops:tag