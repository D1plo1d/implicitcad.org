#!/bin/sh

# exit on error
set -o errexit
# echos commands being run
set -o xtrace

sudo apt-get update -y -qq
sudo apt-get install -y -q git curl
sudo apt-get install -y libsqlite3-dev

# Ruby 1.9
sudo apt-get install -y -q ruby1.9.1 ruby1.9.1-dev \
  rubygems1.9.1 irb1.9.1 ri1.9.1 rdoc1.9.1 \
  build-essential libopenssl-ruby1.9.1 libssl-dev zlib1g-dev

# Needed for Meshlab - TODO: This may be an old version, and if so, we should shift to 1.30a
sudo apt-get install -y xvfb
sudo apt-get install -y meshlab
sudo apt-get install -y libicu-dev
#sudo apt-get install -y qt4-make

# Curb dependencies
sudo apt-get install -y libcurl3 libcurl3-gnutls libcurl4-openssl-dev

# Finally install bundler if it isn't already
which bundle || sudo gem install bundler --no-rdoc --no-ri

# and update our bundled gems
bundle install

# setting up base sessions so they start in the /vagrant share by default
echo "cd /vagrant" >> /home/vagrant/.bashrc


cd /vagrant

rails s -d -p 9001
