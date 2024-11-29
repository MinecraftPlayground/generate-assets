# Container image that runs your code
FROM ubuntu:22.04

# Set the working directory inside the container
WORKDIR /usr/src

# Copy any source file(s) required for the action
COPY main.sh .
RUN chmod +x /usr/src/main.sh

# Configure the container to be run as an executable
ENTRYPOINT ["/usr/src/main.sh"]
