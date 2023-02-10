docker container stop ubuntu
docker container rm ubuntu
docker run --name ubuntu \
    -v once_once-development:/var/dev \
    -t ubuntu /var/dev/once.sh/init/oosh
#docker run --name ubuntu \
#    -v once_once-development:/var/dev \
#    -it ubuntu \
#    /bin/bash -c "/var/dev/once.sh/init/oosh && bash"