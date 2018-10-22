FROM centos-sysctl:7

MAINTAINER Morgany V. Mendes “morgany.mendes@gmail.com"

EXPOSE 749 88

RUN yum -y update; yum install krb5-server -y; yum clean all;

ENV REALM ${REALM:-EXAMPLE.COM}
ENV SUPPORTED_ENCRYPTION_TYPES ${SUPPORTED_ENCRYPTION_TYPES:-aes256-cts-hmac-sha1-96:normal}
ENV KADMIN_PRINCIPAL ${KADMIN_PRINCIPAL:-kadmin/admin}
ENV KADMIN_PASSWORD ${KADMIN_PASSWORD:-MITiys4K5}

COPY init-script.sh /tmp/

#CMD /tmp/init-script.sh
