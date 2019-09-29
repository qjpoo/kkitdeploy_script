#!/bin/bash
#b8_yang@163.com
#source ./base.config
bash_path=$(cd "$(dirname "$0")";pwd)
source $bash_path/base.config

if [[ "$(whoami)" != "root" ]]; then
	echo "please run this script as root ." >&2
	exit 1
fi

#log="./setup.log"  #操作日志存放路径
#fsize=2000000
#exec 2>>$log  #如果执行过程中有错误信息均输出到日志文件中

echo -e "\033[31m 欢迎关注我的个人公众号“devops的那些事”获得更多实用工具！ \033[0m"
sleep 5
#yum update
yum_update(){
	yum update -y
}
#configure yum source
yum_config(){

  yum install wget epel-release -y
  
  if [[ $aliyun == "1" ]];then
  test -d /etc/yum.repos.d/bak/ || yum install wget epel-release -y && cd /etc/yum.repos.d/ && mkdir bak && mv -f *.repo bak/ && wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo && wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo && yum clean all && yum makecache

  fi
  
}


check_path(){
test -d $des || mkdir -p $des
test -d $src || mkdir -p $src
}

yum_init(){
num=0
while true ; do
let num+=1
yum -y install iotop iftop yum-utils net-tools rsync git lrzsz expect gcc gcc-c++ make cmake libxml2-devel openssl-devel curl curl-devel unzip sudo ntp libaio-devel wget vim ncurses-devel autoconf automake zlib-devel  python-devel bash-completion inotify-tools 
if [[ $? -eq 0 ]] ; then
echo "初始化安装环境配置完成！！！"
break;
else
if [[ num -gt 3 ]];then
echo "你登录 "$masterip" 瞅瞅咋回事？一直无法yum包"
break
fi
echo "FK!~没成功？哥再来一次！！"
fi
done
}

#firewalld
iptables_config(){
if [[ `ps -ef | grep firewalld |wc -l` -gt 1 ]];then
  systemctl stop firewalld.service
  systemctl disable firewalld.service
  echo "防火墙我关了奥！！！"
fi
#  iptables -P FORWARD ACCEPT
}
#system config
system_config(){
grep "SELINUX=disabled" /etc/selinux/config
if [[ $? -eq 0 ]];then
  echo "SELINUX 已经禁用！！"
else
  sed -i "s/SELINUX=enforcing/SELINUX=disabled/g" /etc/selinux/config
  setenforce 0
  echo "SELINUX 已经禁用！！"
fi

if [[ `ps -ef | grep chrony |wc -l` -eq 1 ]];then
  timedatectl set-local-rtc 1 && timedatectl set-timezone Asia/Shanghai
  yum -y install chrony && systemctl start chronyd.service && systemctl enable chronyd.service
  systemctl restart chronyd.service
  echo "时钟同步chrony服务安装完毕！！"
fi
}


ulimit_config(){
grep 'ulimit' /etc/rc.local
if [[ $? -eq 0 ]];then
echo "内核参数调整完毕！！！"
else
  echo "ulimit -SHn 102400" >> /etc/rc.local
  cat >> /etc/security/limits.conf << EOF
  *           soft   nofile       102400
  *           hard   nofile       102400
  *           soft   nproc        102400
  *           hard   nproc        102400
  *           soft  memlock      unlimited 
  *           hard  memlock      unlimited
EOF
  cat >> /etc/sysctl.conf << EOF
    kernel.pid_max=4194303
    vm.swappiness = 0
EOF
sysctl -p
echo "内核参数调整完毕！！！"
fi
}

ssh_config(){
grep 'UserKnownHostsFile' /etc/ssh/ssh_config
if [[ $? -eq 0 ]];then
echo "ssh参数配置完毕！！！"
else
sed -i "2i StrictHostKeyChecking no\nUserKnownHostsFile /dev/null" /etc/ssh/ssh_config
echo "ssh参数配置完毕！！！"
fi
}



get_localip(){
ipaddr=$(ip addr | awk '/^[0-9]+: / {}; /inet.*global/ {print gensub(/(.*)\/(.*)/, "\\1", "g", $2)}' | grep $ip_segment)
echo "$ipaddr"
}


change_hosts(){
cd $bash_path
`hostnamectl set-hostname $hostname`
echo $masterip `hostname` >> /etc/hosts
}



deploy_object(){
cd $bash_path
chmod 600 $bash_path/mainBack.sh
chmod +x $bash_path/mainBack.sh
`nohup $bash_path/mainBack.sh > fileBackup.log 2>&1` 

}


main(){
 #yum_update
  yum_config
  yum_init
  check_path
  ulimit_config
  if [[ $changsHostname == "1" ]];then
  change_hosts
  fi
  deploy_object
  echo "已经完毕，请登录相关服务器验收！"
    
}
main