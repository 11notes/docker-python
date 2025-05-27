FROM 11notes/python:3.13.3
# switch to root during setup
USER root
# setup your app
RUN set -ex; \
  pip install -r requirements.txt;
# start image as 1000:1000
USER docker