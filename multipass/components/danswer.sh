#!/bin/bash

CURRENT_DIR="$( cd "$(dirname "$0")" ; pwd -P )"

multipass start danswer || "$CURRENT_DIR/../launch.sh" danswer 12G 100G

multipass exec danswer -- /bin/bash -c "
cd ~

if [ ! -d danswer ]; then
  git clone git@github.com:danswer-ai/danswer.git
fi

cd danswer/deployment/docker_compose

cp -f env.prod.template .env
sed -i 's/WEB_DOMAIN=http:\/\/localhost:3000/WEB_DOMAIN=https:\/\/danswer.local.com/g' .env
sed -i 's/AUTH_TYPE=google_oauth/AUTH_TYPE=disabled/g' .env

cp -f env.nginx.template .env.nginx
sed -i 's/DOMAIN=/DOMAIN=local.com/g' .env.nginx

mkdir -p ../data/sslcerts
sudo cp -f /etc/nginx/sslcerts/* ../data/sslcerts/

docker compose -f docker-compose.prod-no-letsencrypt.yml \
  -p danswer-stack up -d --pull always --force-recreate
"
