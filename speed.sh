#!/bin/bash
# author: weide@foxmail.com

interval=1

function getIfaceInfo()
{
    declare -a Iface
    local Iface
    ifconfig | 
    while read line; do
        if [[ -z "$line" ]]; then
            continue
        fi

        local via=$(echo $line | grep 'flags=' |grep -o "^[^:]*")
        if [[ -n "$via" ]]; then
            while read line; do
                if [[ -z "$line" ]]; then
                    break
                elif echo "$line" | grep -q 'inet '; then
                    local inet=$(echo "$line" | grep -o "inet [0-9.]*"| cut -d' ' -f 2)
                elif echo "$line" | grep -q 'RX packets.*bytes'; then
                    local RX_bytes=$(echo "$line" | grep  -o "RX packets.*bytes.*"| cut -d' ' -f 6)
                elif echo "$line" | grep -q 'TX packets.*bytes'; then
                    local TX_bytes=$(echo "$line" | grep  -o "TX packets.*bytes.*"| cut -d' ' -f 6)
                fi
            done
            echo "$via,($inet),$RX_bytes,$TX_bytes" 
        fi
    done
}

function b2human()
{
    local bytes=$(echo "$1 / $interval"|bc)
    local unit='B'
    if [ $( echo  "$bytes > 1024" | bc ) -eq 1 ]; then
        unit='K'
        bytes=$(echo "scale=3;$bytes/1024"|bc)
        if [ $( echo  "$bytes > 1024" | bc ) -eq 1 ]; then
            unit='M'
            bytes=$(echo "scale=3;$bytes/1024"|bc)
            if [ $( echo  "$bytes > 1024" | bc) -eq 1 ]; then
                unit='G'
                bytes=$(echo "scale=3;$bytes/1024"|bc)
            fi
        fi
    fi
    printf "%.3f %s" $bytes $unit
}

while getopts "n:" arg
do
    case $arg in
        n)
        interval=$OPTARG
        ;;
        *)
        echo "Usage: " $(basename $0) "[-n second]"
        exit 1
        ;;
    esac
done

OLD_IFS="$IFS"
while [[ 1 ]]; do
    if_begin=($(getIfaceInfo))
    width=$(netstat -i | cut -d ' ' -f 1 |awk '{print length}' |sort -n |tail -1)
    sleep $interval
    if_end=($(getIfaceInfo))
    
    clear
    rx_total=0
    tx_total=0
    echo "-------------------------------<speed>------------------------------------"
    for i in "${!if_begin[@]}"; do 
        IFS="," 
        ifb=(${if_begin[i]})
        ife=(${if_end[i]}) 
        IFS="$OLD_IFS"
        if [ "${ifb[0]}" == "${ife[0]}" -a "${ifb[1]}" == "${ife[1]}" ]; then
            rx=$(( ${ife[2]} - ${ifb[2]} ))
            tx=$(( ${ife[3]} - ${ifb[3]} ))
            rx_total=$(( $rx_total + $rx ))
            tx_total=$(( $tx_total + $tx ))
            printf "%-${width}s %-17s : RX = %s/S,\tTX = %s/S\n" ${ifb[0]} ${ifb[1]} "$(b2human $rx)" "$(b2human $tx)"
        fi
    done
    echo "--------------------------------------------------------------------------"
    printf "%-${width}s %-17s : RX = %s/S,\tTX = %s/S\n"  "total" "(0.0.0.0)" "$(b2human $rx_total)" "$(b2human $tx_total)"
done



