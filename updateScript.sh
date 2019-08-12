#!/bin/bash
bash_path=$(cd "$(dirname "$0")";pwd)
workPath = sys.argv[1]
log="$bash_path/setup.log"  #操作日志存放路径
fsize=2000000
exec 2>>$log  #如果执行过程中有错误信息均输出到日志文件中
updateScript(){
unalias cp

git clone https://gitee.com/yb2018/kkitDeployScriptPackage.git $workPath  && cd $bash_path/kkitDeployScriptPackage && cp -rf * ..
rm -rf $bash_path/kkitDeployScriptPackage
}
updateScript > ./setup.log 2>&1

