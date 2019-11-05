FROM valian/docker-python-opencv-ffmpeg
RUN apt-get update && apt-get install -y \
apt-transport-https \
curl \
&& apt-get clean \
&& rm -rf /var/lib/apt/lists/*
RUN curl -sL https://deb.nodesource.com/setup_13.x | bash -
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
RUN apt-get update && apt-get install -y \
libpq-dev postgresql-client rsync libssl-dev \
libreadline-dev imagemagick nfs-common \
nodejs yarn \
&& apt-get clean \
&& rm -rf /var/lib/apt/lists/*
RUN git clone https://github.com/sstephenson/rbenv.git /root/.rbenv
RUN git clone https://github.com/sstephenson/ruby-build.git /root/.rbenv/plugins/ruby-build
RUN /root/.rbenv/plugins/ruby-build/install.sh
ENV PATH /root/.rbenv/bin:/root/.rbenv/shims:$PATH
RUN echo 'eval "$(rbenv init -)"' >> /etc/profile.d/rbenv.sh
RUN echo 'eval "$(rbenv init -)"' >> /root/.bashrc
RUN sh /etc/profile.d/rbenv.sh
ENV CONFIGURE_OPTS --disable-install-doc
RUN rbenv install 2.1.7
RUN rbenv global 2.1.7
RUN echo 'gem: --no-document' >> ~/.gemrc && cp ~/.gemrc /etc/gemrc && chmod uog+r /etc/gemrc
RUN gem update --system 2.7.8
RUN pip install --upgrade pip
RUN pip install git+https://github.com/misasa/image_mosaic.git
#RUN wget https://github.com/misasa/medusa/archive/master.zip -P /srv
#RUN cd /srv && unzip master.zip
#WORKDIR /srv/medusa-master
RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app
COPY Gemfile Gemfile.lock /usr/src/app/
RUN bash -l -c 'bundle install'
COPY package.json yarn.lock /usr/src/app/
RUN bash -l -c 'yarn install'
COPY . /usr/src/app
ENV PORT 3000
EXPOSE $PORT
CMD ["sh", "-c", "bundle exec rails server -p ${PORT}"]