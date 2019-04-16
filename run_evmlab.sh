#! /bin/bash

# this file should be in evaluation/evmlabRevised/
source ../evmlabRevised_venv/bin/activate

usage() {
    echo "Usage:"
    echo "  run_evmlab.sh [-h] [-t TIME] [-x TX_NUMBER] [-n DATASET_NUM]"
    echo "Description:"
    echo "  -h                  :show help infomation"
    echo "  -t (TIME)           :running time in seconds"
    echo "  -x (TX_NUMBER)      :maximum number of transacions for each bytecode to replay"
    echo "  -n (DATASET_NUM)    :on which dataset is running"
}


if [ $# -eq 0 ]; then
    usage
    exit 1
fi

while getopts 'ht:n:x:' OPT; do
    case $OPT in
        h) usage
            exit;;
        t) timeLimit=$OPTARG;;
        x) txLimit=$OPTARG;;
        n) setNum=$OPTARG;;
        ?) usage
            exit;;
    esac
done    

shift $((OPTIND -1))
if [ $# -gt 0 ]; then
    echo "Wrong usage"
    usage
    exit 1;
fi

if [[ ! ${timeLimit} || ! ${setNum} || ! ${txLimit} ]]; then
    echo "-d, -n && -x is required!"
    usage
    exit 1
fi

# basic info
evm=`which evm`
echo -e "\033[36m"
echo "time limit: ${timeLimit} seconds"
echo "transaction number limit: ${txLimit}"
echo "running on dataset ${setNum}"
echo "using evm: ${evm}"
echo -e "\033[0m"

start_seconds=`date +%s`

txCountG=0
txAllG=1000000
txRate=`awk "BEGIN {print ${txCountG} / ${txAllG} * 100}"`

for addr in `ls ../vul_contract_info_${setNum}`; do
    echo -e "\033[34m"
    echo "[${txRate}%]Analyzing ${addr}'s transactions..."
    

    txCount=0
    for txHash in `cat ../vul_contract_info_${setNum}/${addr}/${addr}_txList.txt`; do
        if [ ${txCount} -ge ${txLimit} ]; then
            echo -e "\033[31mReach transcation number limit."
            break
        fi
        echo -e "\033[32m"
        echo "[${txRate}%]Analyzing TX:${txHash} ..."
        echo -e "\033[0m"

        python3.7 -m evmlab reproducer -g ${evm} -x ${txHash} -c ../vul_contract_info_${setNum}/${addr}/before/${addr}.bin -o ../vul_contract_info_${setNum}/${addr}/before/${txHash}.json --no-docker
        python3.7 -m evmlab reproducer -g ${evm} -x ${txHash} -c ../vul_contract_info_${setNum}/${addr}/after/${addr}.bin -o ../vul_contract_info_${setNum}/${addr}/after/${txHash}.json --no-docker

        txCount=$[txCount + 1]
        txCountG=$[txCountG + 1]
        txRate=`awk "BEGIN {print ${txCountG} / ${txAllG} * 100}"` 
        echo -e "\033[32m"
        echo "[${txRate}%]${txCount} transcations have been processed."

        end_seconds=`date +%s`
        seconds_all=$[end_seconds - start_seconds]
        echo "[${txRate}%]Total cost ${seconds_all} seconds."
        echo -e "\033[0m"

        sed -i '/'${txHash}'/d' ../vul_contract_info_${setNum}/${addr}/${addr}_txList.txt
        echo ${txHash} >> ../vul_contract_info_${setNum}/${addr}/${addr}_txList_analyzed.txt

        # if [[ ${seconds_all} -ge ${timeLimit} ]];then
        #     echo -e "\033[31mReach time limit.\033[0m"
        #     exit 1
        # fi
    done
done
deactivate