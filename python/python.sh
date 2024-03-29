#!/usr/bin/env bash
#b8_yang@163.com
#. /etc/profile
bash_path=$(cd "$(dirname "$0")";pwd)
source $bash_path/base.config

if [[ "$(whoami)" != "root" ]]; then
	echo "please run this script as root ." >&2
	exit 1
fi

#log="$bash_path/setup.log"  #操作日志存放路径
#fsize=2000000
#exec 2>>$log  #如果执行过程中有错误信息均输出到日志文件中

echo -e "\033[31m 欢迎关注我的个人公众号“devops的那些事”获得更多实用工具！Please continue to enter or ctrl+C to cancel \033[0m"
#sleep 5
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
  yum -y install chrony && systemctl start chronyd.service && systemctl enable chronyd.service
  systemctl restart chronyd.service
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


rootssh_trust(){
cd $bash_path
num=0
for host in ${hostip[@]}
do
let num+=1
if [[ `get_localip` != $host ]];then

if [[ ! -f /root/.ssh/id_rsa.pub ]];then
echo '###########init key'
expect ssh_trust_init.exp $root_passwd $host
else
echo '###########add key'
expect ssh_trust_add.exp $root_passwd $host
fi

scp base.config trust_node.sh root@$host:/root && ssh root@$host /root/trust_node.sh && ssh root@$host "rm -rf base.config trust_node.sh " && ssh root@$host "rm -rf base.config trust_node.sh"

fi
done
}



download_packed(){
cd $bash_path
num=0
while true ; do
let num+=1
echo "开始下载python安装包，您得等会。可能会很慢，您懂得！！"
test -f Python-$version.tgz || wget https://www.python.org/ftp/python/$version/Python-$version.tgz 
if [[ $? -eq 0 ]] ; then
echo "安装包下载完毕！！！"
break;
else
if [[ num -gt 3 ]];then
echo "你登录 "$masterip" 瞅瞅咋回事？一直无法下载安装包"
break
fi
echo "FK!~没成功？哥再来一次！！"
fi
done
}

install_python(){
echo "开始安装python，您得等会。编译非常慢！！"
cd $bash_path
test -d /usr/local/python3 || mkdir -p /usr/local/python3
tar xf ./Python-$version.tgz && cd ./Python-$version && ./configure --prefix=/usr/local/python3
make && make install
echo "python-$version 安装完毕 "
rm -rf /usr/bin/python3
rm -rf /usr/bin/pip3
ln -sv /usr/local/python3/bin/python3 /usr/bin/python3
ln -sv /usr/local/python3/bin/pip3 /usr/bin/pip3

}

check_result(){
/usr/bin/pip3 -V
/usr/bin/python3 -V
}



main(){
 #yum_update
  yum_config
  yum_init
  ssh_config
  iptables_config
  system_config
  rootssh_trust
  download_packed
  install_python
  check_result
  echo "python-$version 已经全部安装安完毕 "
}
main

