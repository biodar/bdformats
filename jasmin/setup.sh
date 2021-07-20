# fully reproducible changes on the server

## STEP 1 setup docker + docker-compose
# place this in a file and run or line by line
###################
## this script targets Ubuntu 20.04 but works on macOS 11 (big sur) too
###################
## install docker using
# https://www.digitalocean.com/community/tutorials/how-to-install-and-use-docker-on-ubuntu-20-04
sudo apt update
sudo apt install apt-transport-https ca-certificates curl software-properties-common
# debian
# curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
# debian
# echo \
#  "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian \
#  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"
sudo apt update
apt-cache policy docker-ce
sudo apt install docker-ce -y
sudo systemctl status docker

# enable no sudo mode
sudo usermod -aG docker ${USER}
# log out and back in
# OR
# su - ${USER}
# id -nG
# user sudo docker
docker ps -a
## install docker-compose
# https://www.digitalocean.com/community/tutorials/how-to-install-and-use-docker-compose-on-ubuntu-20-04
# feel free to replace these with snap
sudo curl -L "https://github.com/docker/compose/releases/download/1.27.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
docker-compose --version
###################
## END docker setup script
###################

## STEP 2 setup Nginx & Nginx config
# this could also be dockerized and both put in a docker-compose.yml
sudo apt update
sudo apt install nginx
sudo service nginx status # just checking
# setup the proxy using bioatlas.conf file as basic.conf
# sym-link it to /etc/nginx/sites-enabled/

## STEP 3 run bioAtlas
# TODO, see github issue #7

