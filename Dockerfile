# Container image that runs your code
FROM cdue/curl-zip-jq:latest

# Copy any source file(s) required for the action
COPY main.sh /main.sh
RUN chmod +x main.sh

# Configure the container to be run as an executable
ENTRYPOINT ["/main.sh"]
