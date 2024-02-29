#!/bin/bash

name=$1
memo=${2:-4G}
disk=${3:-50G}

# Check if a name was provided
if [ -z "$name" ]; then
  echo "Usage: $0 <name>"
  exit 1
fi

# Create a cloud-init file
mkdir -p ~/.config/multipass
echo -n -e "ssh_authorized_keys:\n  - " > ~/.config/multipass/$name.yml
cat ~/.ssh/id_rsa.pub >> ~/.config/multipass/$name.yml

# Launch the instance
echo "> Launching $name..."
multipass start $name || \
multipass launch -n $name -c 4 -m $memo -d $disk \
  --cloud-init ~/.config/multipass/$name.yml \
  --mount /Users:/mnt/Users

multipass exec $name -- sudo usermod -aG root ubuntu

# Gen SSL certs if not exist
echo "> Generating SSL certs..."
  multipass exec $name -- /bin/bash -c "
    sudo apt install -y openssl
    sudo mkdir -p /etc/nginx/sslcerts
    sudo openssl req \
      -newkey rsa:2048 \
      -x509 \
      -nodes \
      -days 365 \
      -subj '/C=US/ST=Denial/L=Springfield/O=Dis/CN=www.local.com' \
      -keyout /etc/nginx/sslcerts/ssl.key \
      -out /etc/nginx/sslcerts/ssl.cert
  "

# Copy SSH keys to the instance
echo "> Copying SSH keys to the instance..."
multipass transfer ~/.ssh/id_rsa $name:/home/ubuntu/.ssh/id_rsa
multipass transfer ~/.ssh/id_rsa.pub $name:/home/ubuntu/.ssh/id_rsa.pub
multipass exec $name -- sudo chown ubuntu:ubuntu /home/ubuntu/.ssh/id_rsa /home/ubuntu/.ssh/id_rsa.pub

# Install Docker
if [ -z "$(multipass exec $name -- which docker)" ]; then
  echo "> Installing Docker..."
  multipass exec $name -- sudo snap install docker
else
  echo "> Docker is already installed."
fi
