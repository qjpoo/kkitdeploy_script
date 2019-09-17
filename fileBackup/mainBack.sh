#!/bin/bash
bash_path=$(cd "$(dirname "$0")";pwd)
source $bash_path/base.config 

# log="$bash_path/setup.log"  #操作日志存放路径
# fsize=2000000
# exec 2>>$log  #如果执行过程中有错误信息均输出到日志文件中

main(){                  
cd ${src}
/usr/bin/inotifywait -mrq --format  '%Xe %w%f' -e modify,create,delete,attrib,close_write,move ./ | while read file         
do
        INO_EVENT=$(echo $file | awk '{print $1}')      
        INO_FILE=$(echo $file | awk '{print $2}')       
        echo "-------------------------------$(date)------------------------------------"
        echo $file        
	echo $INO_EVENT
	echo $INO_FILE
        if [[ $INO_EVENT =~ 'CREATE' ]] || [[ $INO_EVENT =~ 'MODIFY' ]] || [[ $INO_EVENT =~ 'CLOSE_WRITE' ]] || [[ $INO_EVENT =~ 'MOVED_TO' ]]         
        then
                echo 'CREATE or MODIFY or CLOSE_WRITE or MOVED_TO'
                rsync -avzcR $(dirname ${INO_FILE}) ${des}
                 
        fi

        if [[ $INO_EVENT =~ 'ATTRIB' ]]
        then
                echo 'ATTRIB'
                if [ ! -d "$INO_FILE" ]                 
                then
                        rsync -avzcR  $(dirname ${INO_FILE}) ${des}
                fi
        fi
done
}
main 