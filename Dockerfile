# Container image that runs your code
FROM ubuntu:22

# Copies your code file from your action repository to the filesystem path `/` of the container
COPY main.sh /main.sh

# Code file to execute when the docker container starts up (`entrypoint.sh`)
ENTRYPOINT ["/main.sh"]
