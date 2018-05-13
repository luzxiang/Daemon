#!/bin/bash
source /etc/profile
LOGTYPES=(ERROR WARN INFO DEBUG)
log_level=INFO

LOG_LEVEL_SET(){
    for log in ${LOGTYPES[@]};do
        n=`echo $*|grep -v grep|grep ":${log}"|wc -l`
        if [ $n -gt 0 ];then
            log_level=${log}
        fi
    done
#    echo "log_level=${log_level}"
}

PRINT_TIME(){
    printf "[%s] " `date "+%T"`
}

LOG_ERROR(){
    if [[ "${log_level}" != "ERROR" ]]; then
        return
    fi
    PRINT_TIME 
    printf "${log_level}| "
    echo $*
}

LOG_WARN(){
    if [[ "${log_level}" != "WARN" ]]; then
        return
    fi
    PRINT_TIME 
    printf "${log_level}| "
    echo $*
}


LOG_INFO(){
    if [[ "${log_level}" != "INFO" ]]; then
        return
    fi
    PRINT_TIME 
    printf "${log_level}| "
    echo $*
}

LOG_DEBUG(){
    if [[ "${log_level}" != "DEBUG" ]]; then
        return
    fi
    PRINT_TIME 
    printf "${log_level}| "
    echo $*
}

#LOG_LEVEL_SET log:INFO
#LOG_INFO "dir=$0 num=$#"
