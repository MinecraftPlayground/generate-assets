# Container image that runs your code
FROM cdue/curl-zip-jq:latest

# Set the working directory inside the container
WORKDIR /usr/src

# Copy any source file(s) required for the action
COPY ./main.sh .
RUN chmod +x /usr/src/main.sh

RUN ls -al /usr/src
# Configure the container to be run as an executable
ENTRYPOINT ["/usr/src/main.sh"]
