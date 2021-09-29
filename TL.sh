#!/bin/bash
# shell by 心语难诉
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
LANG=en_US.UTF-8
echo "
+----------------------------------------------------------------------
| CentOS 7.x 天龙服务端环境 安装脚本
+----------------------------------------------------------------------
| Copyright © 2020-2099 MUMAWU 版权所有.
+----------------------------------------------------------------------
| 作者: MUMAWU
+----------------------------------------------------------------------
"
GetSysInfo(){
	if [ -s "/etc/redhat-release" ];then
		SYS_VERSION=$(cat /etc/redhat-release)
	elif [ -s "/etc/issue" ]; then
		SYS_VERSION=$(cat /etc/issue)
	fi

    is64bit=$(getconf LONG_BIT)
    if [ "${is64bit}" != '64' ];then
        echo "Error message: The script can only be run on CentOS 7.x 64-bit series "
        exit;
    fi
    isPy26=$(python -V 2>&1|grep '2.6.')
    if [ "${isPy26}" ];then
        echo "Error message: The script can only be run on CentOS 7.x 64-bit series"
        exit;
    fi
}

GetSysInfo

while [ "$go" != 'y' ] && [ "$go" != 'n' ]
do
	read -p "Are you sure you want to install the Tianlong server to this system? Please select Y (OK) or N (Cancel):" go;
done

if [ "$go" == 'n' ];then
	exit;
fi

Select_Install_Version(){
    version_arr=(7.2 7.3 7.6 7.7 7.8)
    echo "------Select the system version you want to install (enter the version number, such as :7.3)------"
    for i in ${version_arr[@]}
    do
        echo "--------------   $i   --------------"
    done
    echo "-------------------------------------"
    read -p "Enter the version number CentOS: " version;

    while [[ $version < 7.2 ]] || [[ $version > 7.8 ]]
    do
        read -p "The version number is incorrect, please re-enter: " version;
    done
}

downloadPack(){
    if [ ! -f "/opt/tlbbfor7x.tar.gz" ];then
        wget -P /opt http://www.mumawu.com/tlbb/tlbbfor7x.tar.gz
    fi
    tar zxvf /opt/tlbbfor7x.tar.gz -C /opt
}

installTlbbService(){
    # 设置数据库密码
    read -p "Please enter the MySQL database password you need to set: " dbpass;
    LimitIsTure=0
    while [[ "$LimitIsTure" == 0 ]]
    do
        if [[ "${#dbpass}" -ge 8 ]];then
            LimitIsTure=1
        else
            read -p "The password must be greater than or equal to 8 digits, please re-enter: " dbpass;
        fi
    done

    # 进入安装目录
    cd /opt

    # 数据库安装
    yum -y remove mysql-libs
    tar zxvf MySQL.tar.gz
    rpm -ivh mysql-client.rpm
    rpm -ivh mysql-server.rpm

    # 数据库权限相关操作
    mysql -e "grant all privileges on *.* to 'root'@'%' identified by 'root' with grant option;";
    mysql -e "use mysql;update user set password=password('${dbpass}') where user='root';";
    mysql -e "create database tlbbdb;";
    mysql -e "create database web;";
    mysql -e "flush privileges;";
    # 导入纯净数据库
    mysql -uroot -p${dbpass} tlbbdb < tlbbdb.sql
    mysql -uroot -p${dbpass} web < web.sql

    # 安装依赖组件
    yum -y install glibc.i686 libstdc++-4.4.7-4.el6.i686 libstdc++.so.6

    # 安装ODBC与ODBC相关依赖组件
    tar zxvf lib.tar.gz
    rpm -ivh unixODBC-libs.rpm
    rpm -ivh unixODBC-2.2.11.rpm
    rpm -ivh libtool-ltdl.rpm
    rpm -ivh unixODBC-devel.rpm --nodeps --force

    # 安装MYSQL ODBC驱动
    tar zxvf ODBC.tar.gz
    ln -s /usr/lib64/libz.so.1 /usr/lib/lib
    rpm -ivh mysql-odbc.rpm --nodeps

    # ODBC配置
    tar zvxf Config.tar.gz -C /etc
    chmod 644 /etc/my.cnf
    sed -i "s/^\(Password        = \).*/\1${dbpass}/" /etc/odbc.ini

    # 解压ODBC支持库到use/lib目录
    tar zvxf odbc.tar.gz -C /usr/lib
}

claerSetupLib(){
   
    echo "
    +----------------------------------------------------------------------
    | 天龙服务端架设成功 !!!
    +----------------------------------------------------------------------
    | 请保存您的MySQL密码: ${dbpass}
    +----------------------------------------------------------------------
    | 作者: MUMAWU
    +----------------------------------------------------------------------
    "
}

# 选择系统版本
Select_Install_Version
# 下载Lib
downloadPack
# 安装TLBB Service
installTlbbService
# 清理安装包
claerSetupLib