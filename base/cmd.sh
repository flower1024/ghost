#!/usr/bin/env bash

handleERR() {
    echo "$0 Error on line $1"
}
set -em
trap 'handleERR $LINENO' ERR

PATH="$PATH:/base/bin"

setState() {
    LOG "STATE" "$(getState) -> $1"
    echo $1 > $STATEFILE
}

getState() {
    if [ -f $STATEFILE ]; then
        cat $STATEFILE
    else
        echo INIT
    fi
}

STOP() {
    if [ ! "$(getState)" == "STOPPING" ] && [ ! "$(getState)" == "STOPPED" ]; then
        setState STOPPING

        ROOT=/app/stop
        if [ -d $ROOT ]; then
            for USER in $(ls $ROOT)
            do
                for CMD in $(ls $ROOT/$USER)
                do
                    LOG "$(getState)" "${USER} @ $ROOT/$USER/$CMD"
                    gosu $USER $ROOT/$USER/$CMD
                done
            done
        fi

        for PID in $(pgrep -P 1)
        do
            echo -n "[STOP] PID $PID "
            kill -SIGTERM $PID > /dev/null 2>&1 && echo OK || echo FAILED
        done

        setState STOPPED
    fi
    exit
}
trap STOP SIGUSR1

setState INIT

ROOT=/app/init
if [ -d $ROOT ]; then
    for USER in $(ls $ROOT); do
        for CMD in $(ls $ROOT/$USER); do
            LOG "$(getState)" "${USER} @ $ROOT/$USER/$CMD"
            gosu $USER $ROOT/$USER/$CMD
        done
    done
fi

setState STARTING

ROOT=/app/start
if [ -d $ROOT ]; then
    for USER in $(ls $ROOT); do
        for CMD in $(ls $ROOT/$USER); do
            LOG "$(getState)" "${USER} @ $ROOT/$USER/$CMD"
            gosu $USER $ROOT/$USER/$CMD &
        done
    done
fi

ROOT=/tmp/start
if [ -d $ROOT ]; then
    for USER in $(ls $ROOT); do
        for CMD in $(ls $ROOT/$USER); do
            LOG "$(getState)" "${USER} @ $ROOT/$USER/$CMD"
            gosu $USER $ROOT/$USER/$CMD &
        done
    done
fi

setState POST

ROOT=/app/post
if [ -d $ROOT ]; then
    for USER in $(ls $ROOT); do
        for CMD in $(ls $ROOT/$USER); do
            LOG "$(getState)" "${USER} @ $ROOT/$USER/$CMD"
            gosu $USER $ROOT/$USER/$CMD
        done
    done
fi

setState RUNNING
wait -n || echo "[STOP] Stopping"
STOP

while [ true ]; do
    sleep 1
done