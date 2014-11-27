

# Centos OwnCloud latest 

FROM centos:centos6 
MAINTAINER Tobias Sgoff

#RUN yum -y update
RUN yum -y install https://anorien.csc.warwick.ac.uk/mirrors/epel/6/i386/epel-release-6-8.noarch.rpm
RUN yum -y install http://rpms.famillecollet.com/enterprise/remi-release-6.rpm

RUN yum -y install nginx wget tar bzip2 unzip
RUN yum -y install php-fpm php-gd php-mysqlnd php-pgsql php-mbstring php-xml php-ldap --enablerepo=remi
RUN sed -i 's/user = apache/user = nginx/' /etc/php-fpm.d/www.conf
RUN sed -i 's/group = apache/group = nginx/' /etc/php-fpm.d/www.conf
#RUN yum -y update --enablerepo=remi
RUN chown nginx:nginx /var/lib/php/session/

RUN wget https://download.owncloud.org/download/community/owncloud-latest.zip
RUN unzip owncloud-latest.zip
RUN mv owncloud /usr/share/nginx/
#RUN mkdir /usr/share/nginx/owncloud
RUN chown -R nginx:nginx /usr/share/nginx/owncloud
RUN rm owncloud-latest.zip 
ADD default.conf /etc/nginx/conf.d/default.conf 
RUN service nginx start && service php-fpm start

ADD init.sh /init.sh
RUN chmod +x /init.sh

EXPOSE 80

CMD ["/init.sh"]