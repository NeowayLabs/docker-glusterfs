FROM neowaylabs/baseimage:latest

# gluster
RUN apt-get update -qq && \
    apt-get install -y \
        python-software-properties \
        wget && \
    add-apt-repository -y ppa:semiosis/ubuntu-glusterfs-3.5 && \
    apt-get update -qq && \
    apt-get install -y \
        glusterfs-server

ENV GLUSTERFS_TYPE "master"

VOLUME /data

ADD ./start.sh /start.sh

CMD ["/start.sh"]

# Expose ports.
EXPOSE 111 24007 2049 38465 38466 38467 1110 4045
