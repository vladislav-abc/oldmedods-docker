FROM debian:jessie

RUN apt update ; apt install -y locales

RUN echo 'ru_RU.UTF-8 UTF-8' > /etc/locale.gen && \
locale-gen

ENV LANG ru_RU.UTF-8  
ENV LANGUAGE ru_RU:ru  
ENV LC_ALL ru_RU.UTF-8

RUN apt update ; apt install -y \
curl git redis-server postgresql postgresql-contrib \
libpq-dev sudo vim \
apt-utils nano bash-completion tmux screen slurm busybox net-tools

ARG SOFTS_PASS
ARG PG_PASS

RUN sudo useradd -m -s /bin/bash softs ; \
echo "$SOFTS_PASS\n$SOFTS_PASS" | passwd softs ; \
echo "$PG_PASS\n$PG_PASS" | passwd postgres ; \
echo "softs ALL=(ALL:ALL) NOPASSWD: ALL" > /etc/sudoers.d/softs



RUN curl -sL https://deb.nodesource.com/setup_10.x | sudo bash - ; \
sudo apt update ; \
sudo apt install -y --force-yes nodejs

RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add - ; \
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list ; \
sudo apt-get update ; sudo apt-get install -y yarn


RUN /etc/init.d/postgresql start ; \
/etc/init.d/redis-server start ; \
echo 'local   all             postgres                                trust\nlocal   all             all                                     trust\nhost    all             all             127.0.0.1/32            trust\nhost    all             all             ::1/128                 trust\n' > /etc/postgresql/9.4/main/pg_hba.conf ; \
/etc/init.d/postgresql restart ; \
sudo -u softs bash -c 'gpg --keyserver hkp://keyserver.ubuntu.com --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB' ; \
sudo -u softs bash -c 'curl -Lk https://get.rvm.io | bash ; source $HOME/.rvm/scripts/rvm ; rvm install 2.4.2' ; \
sudo -u softs bash -c 'echo $HOME'

ARG GITHUB_TOKEN

RUN sudo -u softs bash -c 'mkdir $HOME/appserver' ; \
sudo -u softs bash -c "cd /home/softs/appserver ; \
git clone -b v_3_4 --depth 1 https://github-medods:$GITHUB_TOKEN@github.com/medods/medods.git"

RUN sudo -u softs bash -c 'source /home/softs/.rvm/scripts/rvm ; \
cd $HOME/appserver/medods ; \
rvm install "ruby-2.2.5"'

RUN apt install -y shared-mime-info

COPY Gemfile.lock /home/softs/appserver/medods/Gemfile.lock
COPY Gemfile /home/softs/appserver/medods/Gemfile
COPY fix.sql /home/softs/appserver/medods/config/fix.sql

RUN chown softs:softs /home/softs/appserver/medods/Gemfile*
RUN chown softs:softs /home/softs/appserver/medods/config/fix.sql


RUN sudo -u softs bash -c 'cd $HOME/appserver/medods ; \
source $HOME/.rvm/scripts/rvm ; \
gem install bundler -v 1.17.3 ; \
bundle ; \
bundle update carrierwave'


RUN sudo -u softs bash -c 'cd $HOME/appserver/medods ; \
source $HOME/.rvm/scripts/rvm ; \
cp $HOME/appserver/medods/config/_database.yml $HOME/appserver/medods/config/database.yml ; \
sudo /etc/init.d/postgresql start ; \
sudo /etc/init.d/redis-server start ; \
sleep 5 ; cat /home/softs/appserver/medods/config/fix.sql | sudo psql -U postgres ; \
rake db:setup RAILS_ENV=production PRECOMPILE=true ; \
yarn ; \
rake assets:precompile RAILS_ENV=production'

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]

VOLUME /var/lib/postgresql

