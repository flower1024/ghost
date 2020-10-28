FROM debian:stable

ARG TZ=Europe/Berlin

ENV STATEFILE="/tmp/state"
STOPSIGNAL SIGUSR1

COPY /base /base/

RUN apt-get update && \
    apt-get install -y -q gosu procps busybox-static software-properties-common curl && \
    chmod ugo+x /base/cmd.sh && \
    chmod ugo+x -R /base/bin && \
    ln -s /base/bin/* /usr/bin && \
    cp /usr/share/zoneinfo/${TZ} /etc/localtime && \
    echo ${TZ} > /etc/timezone && \
    mkdir -p /var/spool/cron/crontabs && \
    echo "auth sufficient pam_shells.so" > /etc/pam.d/chsh

CMD [ "/base/cmd.sh" ]
