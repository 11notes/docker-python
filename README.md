![Banner](https://github.com/11notes/defaults/blob/main/static/img/banner.png?raw=true)

# 🏔️ python on Alpine
[<img src="https://img.shields.io/badge/github-source-blue?logo=github&color=040308">](https://github.com/11notes/docker-python)![size](https://img.shields.io/docker/image-size/11notes/python/3.11?color=0eb305)![version](https://img.shields.io/docker/v/11notes/python/3.11?color=eb7a09)![pulls](https://img.shields.io/docker/pulls/11notes/python?color=2b75d6)[<img src="https://img.shields.io/github/issues/11notes/docker-python?color=7842f5">](https://github.com/11notes/docker-python/issues)

**Python, compiled from source**

# SYNOPSIS 📖
**What can I do with this?** Use this image as base image for your Python applications you want to run on Alpine.

# COMPOSE ✂️
```yaml
name: "python"
services:
  python:
    image: "11notes/python:3.11"
    container_name: "python"
    environment:
      TZ: "Europe/Zurich"
    restart: "always"
```

# DEFAULT SETTINGS 🗃️
| Parameter | Value | Description |
| --- | --- | --- |
| `user` | docker | user name |
| `uid` | 1000 | [user identifier](https://en.wikipedia.org/wiki/User_identifier) |
| `gid` | 1000 | [group identifier](https://en.wikipedia.org/wiki/Group_identifier) |
| `home` | /python | home directory of user docker |

# ENVIRONMENT 📝
| Parameter | Value | Default |
| --- | --- | --- |
| `TZ` | [Time Zone](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones) | |
| `DEBUG` | Will activate debug option for container image and app (if available) | |

# SOURCE 💾
* [11notes/python](https://github.com/11notes/docker-python)

# PARENT IMAGE 🏛️
* [11notes/alpine:stable](https://hub.docker.com/r/11notes/alpine)

# BUILT WITH 🧰
* [python](https://www.python.org)
* [alpine](https://alpinelinux.org)

# GENERAL TIPS 📌
* Use a reverse proxy like Traefik, Nginx, HAproxy to terminate TLS and to protect your endpoints
* Use Let’s Encrypt DNS-01 challenge to obtain valid SSL certificates for your services
  
# ElevenNotes™️
This image is provided to you at your own risk. Always make backups before updating an image to a different version. Check the [releases](https://github.com/11notes/docker-python/releases) for breaking changes. If you have any problems with using this image simply raise an [issue](https://github.com/11notes/docker-python/issues), thanks. You can find all my repositories on [github](https://github.com/11notes?tab=repositories).