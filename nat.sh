#! /bin/bash
# chkconfig: 2345 55 25
# Description: Startup script for nginx webserver on Debian. Place in /etc/init.d and
# run 'update-rc.d -f router defaults', or use the appropriate command on your
# distro. For CentOS/Redhat run: 'chkconfig --add nat'

#open nat       
echo 1 > /proc/sys/net/ipv4/ip_forward
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
NAME=iptables
R_BIN=/usr/sbin/$NAME
LAN=10.0.0.0/24  #虚拟机的网络
IPi=13.7.8.15    #外网的ip
WAN=eth0         #外网端口

case "$1" in
    start)
        echo -n "Starting router.. "
        $R_BIN -t nat -A PREROUTING -d $IPi -p tcp --dport $2 -j DNAT --to-destination $3 
        echo " done"
        ;;

    stop)
        echo -n "Stoping router.. "
        $R_BIN -t nat -D PREROUTING -d $IPi -p tcp --dport $2 -j DNAT --to-destination $3 
        echo " done"
        ;;
    status)
        $R_BIN -t nat -nL
        ;;

    startr)
        echo -n "Starting router.. "
        if [ $2 ];then
           LAN=$2
        fi
        $R_BIN -t nat -A POSTROUTING -s $LAN -o eth0 -j MASQUERADE 
        echo " done"
        ;;

    stopr)
        echo -n "Stoping router.. "
        if [ $2 ];then 
           LAN=$2
        fi
        $R_BIN -t nat -D POSTROUTING -s $LAN -o eth0 -j MASQUERADE 
        echo " done"
        ;;
    *)
        echo "Usage: $0 {start <iport> <dip:dport>|stop <iport> <dip:dport>|status|startr <IPv4/CIDR>|stopr <IPv4/CIDR> }"
        exit 1
        ;;

esac