#!/bin/bash

# 备份指定目录文件到指定目录,备份文件名称为：备份目录最后一层目录+"_"+日期.tar.gz
# 第一个参数：backdir 第二参数：备份文件保存目录 第三个参数：备份目录/文件
backdir(){
    # 备份文件保存目录
    BACKUP_DIR=`echo $2`

    # 备份目录
    SOURCE_DIR=`echo $3`
    FILE_NAME=`basename "$SOURCE_DIR"`
    # 备份文件名称
    BACKUP_FILE=$FILE_NAME\_$(date +%Y%m%d).tar.gz
    #如果备份文件保存目录不存在则创建
    if [ ! -d "$BACKUP_DIR" ]; then
      mkdir -p $BACKUP_DIR
    fi
    # 创建备份文件
    tar -zcvPf $BACKUP_DIR/$BACKUP_FILE $SOURCE_DIR
}

# 内存，cpu，磁盘使用
baseinfo(){

    # CPU usage
    CPU_USAGE=$(top -b -n 1 | grep "^%Cpu" | awk '{print $2}')

    # Memory usage
    MEM_USAGE=$(free | awk 'NR==2{printf "%.2f%%", $3/$2*100}')

    # Disk usage
    DISK_USAGE=$(df -h / | awk 'NR==2{print $5}')

    # Write results to log file
    echo "$(date +"%Y-%m-%d %H:%M:%S") CPU usage: $CPU_USAGE, Memory usage: $MEM_USAGE, Disk usage: $DISK_USAGE" 
}

# 开启防火墙
startFirewall(){
  			# 获取 Linux 系统版本
        OS=$(awk -F= '/^NAME/{print $2}' /etc/os-release)
      	# 根据系统版本执行相应的命令启动防火墙
        if [[ $OS == *"CentOS"* || $OS == *"Red Hat"* ]]; then
            systemctl start firewalld
            systemctl enable firewalld
            systemctl start iptables
            systemctl enable iptables
            systemctl status iptables
            systemctl status firewalld
            echo "Firewall has been started and enabled successfully."
        elif [[ $OS == *"Ubuntu"* || $OS == *"Debian"* ]]; then
            ufw enable
            echo "Firewall has been enabled successfully."
        else
            echo "Unsupported operating system."
            exit 1
        fi
}
#关闭防火墙
stopFirewall(){
        # 获取 Linux 系统版本
        OS=$(awk -F= '/^NAME/{print $2}' /etc/os-release)

        # 根据系统版本执行相应的命令关闭防火墙
        if [[ $OS == *"CentOS"* || $OS == *"Red Hat"* ]]; then
            systemctl stop firewalld
            systemctl disable firewalld
            systemctl stop iptables
            systemctl disable iptables
            systemctl status iptables
            systemctl status firewalld
            echo "Firewall has been stopped and disabled successfully."
        elif [[ $OS == *"Ubuntu"* || $OS == *"Debian"* ]]; then
            ufw disable
            echo "Firewall has been disabled successfully."
        else
            echo "Unsupported operating system."
            exit 1
        fi
}

# 查看进程pid，启动时间，持续执行时间
pstime(){
  ps -eo pid,lstart,etime,cmd | grep $2
}

# 根据进程ID查看进程工作目录
psdir(){
  ls -l /proc/$2/cwd 
}

# 释放缓存
dropCache(){
    sync
    echo 3 > /proc/sys/vm/drop_caches
}

# 第二个参数ip，第三个参数端口
pingPort(){
        # 定义IP地址和端口
        IP_ADDRESS=`echo $2`
        PORT=`echo $3`

        # 检查nc命令是否已经安装，如果未安装，则尝试安装
        if ! command -v nc &> /dev/null; then
            if command -v apt-get &> /dev/null; then
                sudo apt-get update && sudo apt-get -y install netcat
            elif command -v yum &> /dev/null; then
                sudo yum install -y nc
            else
                echo "无法自动安装nc命令，请手动安装后重试。"
                exit 1
            fi
        fi

        # 使用nc命令检查IP地址和端口是否可用
        if nc -z -w 2 $IP_ADDRESS $PORT; then
            echo "端口 $PORT 可以访问 $IP_ADDRESS"
        else
            echo "端口 $PORT 无法访问 $IP_ADDRESS"
        fi
}

# 查看进程使用的端口号
# 第二个参数出入安需要查询的进程，可以为pid，也可以为进程名称
catProcessorPort(){
				echo "-------------------------------------------------"
        PROCESS_NAME=`echo $2`

        # 使用pidof命令查找进程ID
        PID=$(pidof $PROCESS_NAME)

        # 如果找不到进程ID，则使用ps命令查找
        if [ -z "$PID" ]; then
            PID=$(ps -ef | grep $PROCESS_NAME | grep -v grep | awk '{print $2}')
        fi
        echo 所有进程ID:$PID
        # 如果还是找不到进程ID，则输出错误信息并退出
        if [ -z "$PID" ]; then
            echo "找不到进程 $PROCESS_NAME。"
            exit 1
        fi
        
        for PID2 in $PID; do
        		echo "-------------------------------------------------"
            echo 进程ID:$PID2
            # 使用lsof命令查找进程占用的端口号
            PORTS=$(lsof -nP -p $PID2 | grep LISTEN | awk '{print $9}' | cut -d':' -f2 | sort -u)

            # 输出占用端口号
            if [ -n "$PORTS" ]; then
                echo "进程 $PROCESS_NAME 占用的端口号：$PORTS"
            else
                echo "进程 $PROCESS_NAME 没有占用任何端口。"
            fi
        done
        echo "-------------------------------------------------"
        
}

# 查看使用端口的进程pid
# 第二个参数为端口号
catPortProcessor(){
		catPortProcessorPort=`echo $2`
    # 使用 lsof 命令查询端口号对应的进程
    pid=$(sudo lsof -t -i:$catPortProcessorPort)

    # 如果找到了进程，打印进程名称和 PID
    if [ ! -z "$pid" ]; then
      process_name=$(ps -p $pid -o comm=)
      echo "端口 $port 对应的进程是 $process_name，PID 是 $pid。"
    else
      echo "端口 $port 没有被占用。"
    fi
}

# 查看哪个目录占用磁盘空间大
# 第二个参数为：需要查看的目录
duh(){
		directory=`echo $2`
	
    # 遍历目录并计算大小
    du -h -d 1 $directory | sort -h

    # 输出占用存储空间最大的目录
    echo "占用存储空间最大的目录或文件是："
    du -sh $directory/* | sort -hr | head -n 1
}

# 使用内存最多的前十个进程
topMem(){
		echo "下面是 内存 占用率最高的前 10 个进程："
		echos
		echo "进程ID 内存使用大小 启动命令"
		ps aux --sort=-%mem | head -n 11 | tail -n 10 | awk '{print $2,$6/1024"M",$11}'
		echos
}

# 使用CPU最多的前十个进程
topCpu(){
		echo "下面是 CPU 占用率最高的前 10 个进程："
		echos
		echo "进程ID cpu占用率 启动命令"
    ps aux --sort=-%cpu | head -n 11 | tail -n 10 | awk '{print $2,$3,$11}'
    echos
}

# 查看有多少远程的 IP 在连接本机(不管是通过 ssh 还是 web 还是 ftp 都统计) 
# 使用 netstat ‐atn 可以查看本机所有连接的状态,‐a 查看所有,
# -t仅显示 tcp 连接的信息,‐n 数字格式显示
# Local Address(第四列是本机的 IP 和端口信息)
# Foreign Address(第五列是远程主机的 IP 和端口信息)
# 使用 awk 命令仅显示第 5 列数据,再显示第 1 列 IP 地址的信息
# sort 可以按数字大小排序,最后使用 uniq 将多余重复的删除,并统计重复的次数
connectIp(){
		echo "连接数量 来源IP端口"
		# 第一列是连接数量，第二列是连接ip:port
		netstat -atn  |  awk  '{print $5}'  | awk  '{print $1}' | sort -nr  |  uniq -c
}

# 查看网卡流量
iftop(){
   sudo yum -y install iftop
   echo "请手动输入命令查看流量：iftop -P"
}

# 显示系统基础信息
info(){
    # 获取系统 CPU 数量
    cpu_logical_count=$(nproc)
    cpu_physical_count=$(grep "physical id" /proc/cpuinfo | sort -u | wc -l)

    # 获取系统内存总容量、已使用内存量和可用内存量
    mem_total=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    mem_used=$(free -m | awk 'NR==2{print $3}')
    mem_available=$(free -m | awk 'NR==2{print $4}')

    # 获取系统磁盘总容量、已使用磁盘空间和可用磁盘空间
    disk_total=$(df -BG --total | awk 'END{print $2}')
    disk_used=$(df -BG --total | awk 'END{print $3}')
    disk_available=$(df -BG --total | awk 'END{print $4}')

    # 获取系统 CPU 使用率
    cpu_usage=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1"%"}')

    # 将容量单位转换为 GB
    #disk_total=$(echo "scale=2;$disk_total/1024" | bc)
    #disk_used=$(echo "scale=2;$disk_used/1024" | bc)

    # 显示基础监控信息
    echo "系统 CPU 数量（逻辑处理器数量）：$cpu_logical_count"
    echo "系统 CPU 数量（物理处理器数量）：$cpu_physical_count"
    echo "系统内存总容量：$((mem_total / 1024)) MB"
    echo "系统已使用内存量：$mem_used MB"
    echo "系统可用内存量：$mem_available MB"
    echo "系统磁盘总容量：$disk_total GB"
    echo "系统已使用磁盘空间：$disk_used GB"
    echo "系统可用磁盘空间：$disk_available GB"
    echo "系统 CPU 使用率：$cpu_usage"
}

echos(){
	echo "-------------------------------------------------"
}

case "$1" in
  			'backdir')
          backdir $*
                ;;
        'baseinfo')
          baseinfo
                ;;
        'stopFirewall')
					stopFirewall
                ;;
        'startFirewall')
          startFirewall
                ;;
        'pstime')
          pstime $*
                ;;
        'psdir')
        psdir $*
        ;;
         'dropCache')
        dropCache
        ;;
         'ping-port')
        pingPort $*
        ;;
         'processor-port')
        catProcessorPort $*
        ;;
         'port-processor')
        catPortProcessor $*
        ;;
         'duh')
        duh $*
        ;;
          'top-mem')
        topMem 
        ;;
          'top-cpu')
        topCpu 
        ;;
          'connect-ip')
        connectIp
        ;;
         'iftop')
        iftop
        ;;
         'info')
        info
        ;;
        *)
                exit 1
esac