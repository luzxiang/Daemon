#!/bin/bash
source /etc/profile

## add the servers into the PRO_DIR[], add the pro args into the PRO_ARGS[] if necessary
i=0
PRO_DIR[$i]="/home/luzx/Demo/demo/Debug/demo";PRO_ARGS[$i]="log:info";let i+=1

argv="start"
mode="cmd"
slp=10
cmd=$argv
self=${0}

if [[ $# != 0 ]];then
    argv=${1}
fi

if [[ ${argv} != *[!0-9]* ]];then
    slp=${argv}
    mode="digit"
else
    cmd=${argv}
    mode="cmd"
fi

function printf_date()
{
    printf "[%s] " `date "+%T"`
}

#log for info level
function LOG_INFO()
{
    msg=${*}
    printf_date
    echo $msg
}

#get the pid of a pro by string
function getpid_by_str()
{
    str=${1}

    n=`ps aux|grep -v grep|grep -v "${str}\.log"|grep -w "${str}"|awk -F' ' '{print $2}'`
    echo $n
}

function getpid_by_name()
{
    name=${1}

    n=`getpid_by_str $name`
    echo $n
}

function getpid_by_dir()
{
    pdir="${1}"

    n=`getpid_by_str $pdir `
    echo $n
}

#find how much pro is running which match by the str
function getpnum_by_str()
{
    str="${1}"

    n=`ps aux|grep -v grep|grep -w "${str}"|wc -l`
    echo $n
}

function getpnum_by_dir()
{
    pdir="${1}"
    pname=`basename $pdir`

    n=`ps aux|grep -v grep|grep -v "${pname}\.log"|grep -w "${pdir}"|wc -l`
    m=`getpnum_by_str "/${pname}"`
    let n+=m    
    echo $n
}

#start a pro by input dir and args of the pro
function pro_start_by_dir_args()
{
    pdir=$1
    pargs=$2

    LOG_INFO "starting..."
    `nohup ${pdir} ${pargs} > /dev/null 2>&1 &`
}

#kill all the pro that match by the str you input
function pro_kill_by_str()
{
    str=$1
    `ps aux |grep -v grep|grep -w "${str}"|awk -F' ' '{print $2}'|xargs kill -9`
}

#kill all the pro that match by the pro name
function pro_kill_by_name()
{
    str=$1
    pro_kill_by_str "${str}" 
}

#kill all the pro that match by the pro dir
function pro_kill_by_dir()
{
    pdir=$1
    if [ ! -f "$pdir" ];then
        LOG_INFO "invalid :$pdir"
        return
    fi
    pname=`basename $pdir`

    LOG_INFO "all ${pname} is being killed..."
    pro_kill_by_name "${pname}" 
}

function pro_restart_by_dir_args()
{
    pdir=$1
    pargs=$2

    pro_kill_by_dir ${pdir}
    pro_start_by_dir_args ${pdir} ${pargs}
}

function pro_start_nohup_by_dir_args()
{
    str=$*
#    LOG_INFO "pro_start_nohup_by_dir_args $str"
    ans=`nohup ${str}  > /dev/null 2>&1 &`
}

function pro_showinfo_by_dir()
{
    pdir=$1

    pname=`basename $pdir`
    pid=`getpid_by_name ${pname}`
    pro_num=`getpnum_by_dir "$pname"`

    LOG_INFO "$pro_num $pname[$pid] is running..."
}

function pro_showinfo_all()
{
    for pdir in ${PRO_DIR[@]};do
        pname=`basename ${pdir}`
        n=`getpnum_by_dir $pname`
        pro_showinfo_by_dir ${pdir}
    done
}

function pro_killall()
{
    for pdir in ${PRO_DIR[@]};do
        pname=`basename ${pdir}`
        n=`getpnum_by_dir $pname`
        if [[ $n > 0 ]];then
            pro_kill_by_dir "${pdir}"
        fi
        pro_showinfo_by_dir ${pdir}
    done
}

function pro_running_check()
{
    for((i=0;i<${#PRO_DIR[@]};i++));do
        pro_dir=${PRO_DIR[$i]}
        pro_args=${PRO_ARGS[$i]}
        pro_name=`basename ${pro_dir}`
    
        pro_showinfo_by_dir ${pro_dir}
        pro_num=`getpnum_by_dir "$pro_name"`
        if [[ ${pro_num} -gt 1 ]];then
            pro_restart_by_dir_args ${pro_dir} ${pro_args}
        elif [[ ${pro_num} -lt 1 ]];then
            pro_start_by_dir_args ${pro_dir} ${pro_args}
        fi
        pro_showinfo_by_dir ${pro_dir}
    done 
}

function pro_running_keep()
{
    while [[ 1 ]];do
        pro_running_check
        sleep ${slp}
    done
}

function show_helpInfo()
{
    selfname=`basename ${self}`
    echo "Daemon.sh version (2018-05-13 update)"
    echo ""
    printf "%5s: %-30s %s\n" "usage" "bash ${selfname} [Arguments]" "daemon the pro you setting"
    printf "%5s: %-30s %s\n" "or"	 "bash ${selfname}" 		"the same as ${self} start"
    echo ""
    echo "Arguments:"
    printf "%9s         %s\n" 'start' "start the pro if is not running once"
    printf "%9s         %s\n" 'restart' "restart the pro whether it's running or not once"
    printf "%9s         %s\n" 'stop' "stop the pro and exit"
    printf "%9s         %s\n" 'nohup' "run the daemon in the background that check the pro running per 10 second"
    printf "%9s         %s\n" 'n' "n > 0, daemon running in the foreground and check the pro running per n second
                        you can kill the demon by ctrl+c which will send to the pro too"
    printf "%9s         %s\n" 'help' "show the demon help info"
}

function handle_cmd()
{
    startself="${self} ${slp}"
    case $cmd in
        "start")
            pro_running_check
        ;;
        "restart")
            pro_killall
            pro_running_check
        ;;
        "stop")
            pro_killall  
            n=`getpnum_by_str "${startself}"`
            LOG_INFO "$n ${startself} is running!"
            if [[ $n > 0 ]];then
                LOG_INFO "$n ${startself} will be killed"
                pro_killall  
                pro_kill_by_str ${startself}
            fi
        ;;
        "nohup")
            n=`getpnum_by_str "${startself}"`
            pid=`getpid_by_str "${startself}"`
            LOG_INFO "$n ${startself} [$pid]is running..."
            if [[ $n == 0 ]];then
                LOG_INFO "start ${startself} ..."
                pro_start_nohup_by_dir_args ${startself}
                sleep 0.2 
            fi
        ;;
        "help")
            show_helpInfo
        ;;
        *)
            LOG_INFO "invalid arguments !!!"
        ;;
    esac
}

LOG_INFO "${self}[PID=$$]"
pro_showinfo_all
if [[ $mode == "cmd" ]];then
    handle_cmd 
elif [[ $mode == "digit" ]];then
    pro_running_keep
fi
pro_showinfo_all


