FROM centos:7

MAINTAINER Morgany V. Mendes “morgany.mendes@gmail.com"

ENV container docker

COPY ./files/docker/systemctl.py /usr/bin/systemctl

RUN (cd /lib/systemd/system/sysinit.target.wants/; for i in *; do [ $i == \
	systemd-tmpfiles-setup.service ] || rm -f $i; done); \
	rm -f /lib/systemd/system/multi-user.target.wants/*;\
	rm -f /etc/systemd/system/*.wants/*;\
	rm -f /lib/systemd/system/local-fs.target.wants/*; \
	rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
	rm -f /lib/systemd/system/sockets.target.wants/*initctl*; \
	rm -f /lib/systemd/system/basic.target.wants/*;\
	rm -f /lib/systemd/system/anaconda.target.wants/*;

VOLUME [ "/sys/fs/cgroup" ]

CMD ["/usr/sbin/init"]
