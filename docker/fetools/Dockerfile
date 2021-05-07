FROM node:11

WORKDIR /data/themesrc
ENV HOME=/data

RUN mkdir -p /data/themesrc/node_modules

COPY themesrc/package*.json /data/themesrc/
COPY themesrc/.eslintrc /data/themesrc/
COPY themesrc/.npmrc /data/themesrc/
COPY themesrc/.*.yml /data/themesrc/

RUN npm install -g npm  \
	&& npm install -g grunt-cli \
    && npm install -g gulp

CMD ["bash"]
