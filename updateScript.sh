#!/bin/bash
bash_path=$(cd "$(dirname "$0")";pwd)
workPath=$1
log="$bash_path/setup.log"  #操作日志存放路径
fsize=2000000
exec 2>>$log  #如果执行过程中有错误信息均输出到日志文件中
updateScript(){
#unalias cp
`sed -i "/^alias cp='cp -i'/d" /root/.bashrc`

#test -d ./kkitDeployScriptPackage || mkdir -p ./kkitDeployScriptPackage 
git clone https://gitee.com/yb2018/kkitDeployScriptPackage.git "${workPath}"kkitDeployScriptPackage && cd "${workPath}"kkitDeployScriptPackage && cp -rf * $workPath
cd $workPath && rm -rf ./kkitDeployScriptPackage
}
updateScript > ./setup.log 2>&1

