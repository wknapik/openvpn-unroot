FROM scratch
MAINTAINER \
[Adam Miller <maxamillion@fedoraproject.org>] \
[Patrick Uiterwijk <patrick@puiterwijk.org>]
ENV DISTTAG=f26docker FGC=f26
ADD fedora-rawhide-20161211.tar.xz /
RUN dnf update -y bash && dnf install -y openvpn sudo which
