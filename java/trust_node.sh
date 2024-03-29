#!/usr/bin/env bash
#b8_yang@163.com
#. /etc/profile
bash_path=$(cd "$(dirname "$0")";pwd)
source $bash_path/base.config


if [[ "$(whoami)" != "root" ]]; then
	echo "please run this script as root ." >&2
	exit 1
fi

log="./setup.log"  #操作日志存放路径 
fsize=2000000         
exec 2>>$log  #如果执行过程中有错误信息均输出到日志文件中

echo -e "\033[31m 这个是java一键部署脚本，node节点正在运行脚本中,请不要刷新或断开连接，结束会有相关提示！ \033[0m"
#sleep 5
#yum update
yum_update(){
	yum update -y
}
#configure yum source
yum_config(){
  yum install wget epel-release -y
  
if [[ $aliyun == "1" ]]; then
  cd /etc/yum.repos.d/ && mkdir bak && mv -f *.repo bak/
  wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
  wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo
  yum clean all && yum makecache

fi

}

yum_init(){
num=0
while true ; do
let num+=1
yum -y groupinstall "Development tools"
yum -y install iotop iftop yum-utils net-tools rsync git lrzsz expect gcc gcc-c++ make cmake libxml2-devel openssl-devel curl curl-devel unzip sudo ntp libaio-devel wget vim ncurses-devel autoconf automake zlib-devel  python-devel bash-completion zlib-devel bzip2-devel openssl-devel ncurses-devel sqlite-devel readline-devel tk-devel gdbm-devel db4-devel libpcap-devel xz-devel
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
  systemctl stop firewalld.service
  systemctl disable firewalld.service
#  iptables -P FORWARD ACCEPT
}

#system config
system_config(){
  sed -i "s/SELINUX=enforcing/SELINUX=disabled/g" /etc/selinux/config
  setenforce 0
  timedatectl set-local-rtc 1 && timedatectl set-timezone Asia/Shanghai
#  yum -y install chrony && systemctl start chronyd.service && systemctl enable chronyd.service
}
ulimit_config(){
  echo "ulimit -SHn 102400" >> /etc/rc.local
  cat >> /etc/security/limits.conf << EOF
  *           soft   nofile       102400
  *           hard   nofile       102400
  *           soft   nproc        102400
  *           hard   nproc        102400
  *           soft  memlock      unlimited 
  *           hard  memlock      unlimited
EOF
}

ssh_config(){

if [[ `grep 'UserKnownHostsFile' /etc/ssh/ssh_config` ]];then
echo "pass"
else
sed -i "2i StrictHostKeyChecking no\nUserKnownHostsFile /dev/null" /etc/ssh/ssh_config
systemctl restart sshd
fi
}


get_localip(){
ipaddr=$(ip addr | awk '/^[0-9]+: / {}; /inet.*global/ {print gensub(/(.*)\/(.*)/, "\\1", "g", $2)}' | grep $ip_segment)
echo "$ipaddr"
}


install_java(){
cd $bash_path
java -version
if [[ $? -eq 0 ]];then
echo "java-$version 安装完毕 "
else
yum -y install java-$version-openjdk*
echo "java-$version 安装完毕 "
fi

}

install_maven(){
test -d /usr/local/maven3 
if [[ $? -eq 0 ]];then
echo "mvn已经安装完毕!!!"
else
wget http://mirrors.tuna.tsinghua.edu.cn/apache/maven/maven-3/3.6.2/binaries/apache-maven-3.6.2-bin.tar.gz && tar zxf apache-maven-3.6.2-bin.tar.gz && mv apache-maven-3.6.2 /usr/local/maven3
grep "M2_HOME" /etc/profile
if [[ $? -eq 0 ]];then
echo "M2_HOME 环境变量配置完毕"
else
cat >> /etc/profile << EOF
export M2_HOME=/usr/local/maven3
export PATH=$PATH:/usr/local/maven3/bin
EOF
source /etc/profile
mvn -v
fi
fi
}
check_result(){
`java -version`
}

main(){
 #yum_update
  yum_config
  yum_init
  ssh_config
  iptables_config
  system_config
  
  if [[ $java == "1" ]];then
  install_java
  fi
  
  if [[ $maven == "1" ]];then
  install_maven
  fi
  
  check_result
  
  echo "java-$version 安装完毕 "
}

main > .setup.log 2>&1

