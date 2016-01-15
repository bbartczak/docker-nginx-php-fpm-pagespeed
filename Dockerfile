FROM centos:7.2.1511

MAINTAINER Alexander Trost <galexrt@googlemail.com>

ENV NPS_VERSION=1.10.33.2 NGINX_VERSION=1.8.0

ADD entrypoint.sh /entrypoint.sh

RUN chmod 755 /entrypoint.sh && \
    yum -q update -y && \
    yum -q install -y wget unzip gcc-c++ pcre-devel zlib-devel make unzip \
        openssl python-setuptools php-fpm php-common php-mysql php-xml php-pgsql \
        php-pecl-memcache php-pdo php-odbc php-mysql php-mbstring php-ldap \
        php-intl php-gd php-bcmath php-soap php-process php-pear php-recode \
        php-pspell php-snmp php-xmlrpc && \
    adduser -r -m -d /var/cache/nginx -s /sbin/nologin nginx && \
    easy_install pip && \
    pip install supervisor && \
    mkdir -p /var/log/supervisord/ && \
    sed -i 's/;cgi.fix_pathinfo.*/cgi.fix_pathinfo=0/g' /etc/php.ini && \
    sed -i 's/user.*/user = nginx/g' /etc/php-fpm.d/www.conf && \
    sed -i 's/group.*/group = nginx/g' /etc/php-fpm.d/www.conf && \
    cd /root && \
    wget -q https://github.com/pagespeed/ngx_pagespeed/archive/release-${NPS_VERSION}-beta.zip -O release-${NPS_VERSION}-beta.zip && \
    unzip release-${NPS_VERSION}-beta.zip && \
    cd ngx_pagespeed-release-${NPS_VERSION}-beta/ && \
    wget -q https://dl.google.com/dl/page-speed/psol/${NPS_VERSION}.tar.gz && \
    tar -xzf ${NPS_VERSION}.tar.gz && \
    cd /root && \
    wget -q http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz && \
    tar -xzf nginx-${NGINX_VERSION}.tar.gz && \
    cd nginx-${NGINX_VERSION}/ && \
    ./configure --add-module=/root/ngx_pagespeed-release-${NPS_VERSION}-beta ${PS_NGX_EXTRA_FLAGS} && \
    make && \
    make install && \
    rm -f /etc/nginx/conf.d/* && \
    mkdir -p /var/ngx_pagespeed_cache /etc/nginx/conf.d/ /var/log/nginx /var/log/pagespeed && \
    chown nginx:nginx -R /var/ngx_pagespeed_cache /var/log/pagespeed && \
    rm -rf /root/* && \
    yum -q remove -y wget tar unzip gcc-c++ pcre-devel zlib-devel make unzip && \
    yum -q clean all && \
    rm -rf /tmp/* /var/tmp/*

ADD nginx.conf /usr/local/nginx/conf/nginx.conf
ADD nginx-default.conf /etc/nginx/conf.d/default.conf
ADD supervisord.conf /supervisord.conf

VOLUME ["/usr/share/nginx/html", "/etc/nginx/conf.d/"]

ENTRYPOINT ["/usr/bin/supervisord", "-c", "/supervisord.conf"]
