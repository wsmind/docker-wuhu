FROM ubuntu:14.04

RUN apt-get -y update
RUN apt-get -y install apache2 php5 php5-gd php5-mysqlnd php5-curl mysql-server-5.5 libapache2-mod-php5 mc git ssh sudo

COPY ./wuhu-install.sh /usr/sbin
RUN chmod +x /usr/sbin/wuhu-install.sh
RUN /usr/sbin/wuhu-install.sh

EXPOSE 80
