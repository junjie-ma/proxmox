#! /bin/bash
#create restore clone
bwlimit=
description=
hostname=
pool=

#create restore
storage=nfs
ostemplate=
arch=
cmode=
console=
cores=1
cpulimit=
cpuunits=
features=
force=
hookscript=
ignoreunpackerrors=1
lock=
memory=
mp0=
nameserver=
net0=
onboot=
ostype=centos
password=12345
protection=
rootfs=local-zfs
searchdomain=
sshpublickeys=
start=
startup=
swap=
tags=
template=
tty=
unique=
unprivileged=
unused0=

#create
rootfssize=2
restore=

#clone
newid=
full=
snapname=
target=


scmd=" "
//附加的配置，可以根据需要修改为自己的
function wconfig(){
echo "write configfile $1"
cat>>$1<<EOF
lxc.apparmor.profile: unconfined
lxc.mount.auto: cgroup:rw
lxc.mount.auto: proc:rw
lxc.mount.auto: sys:rw
lxc.cgroup.devices.allow: b 259:0 rwm
lxc.cgroup.devices.allow: b 259:1 rwm
EOF
}
//删除上面的配置
function sedfile(){
	echo "delete config $1"
	sed -i '/^lxc./d' $1 
}

function replaceconf(){
	echo "replace $1 to $2"
	a1=$1
	a2=$2
	a1=${a1//\//\\\/}
	a2=${a2//\//\\\/}
	a3="sed -i 's/$a1/$a2/g' $3"
	eval $a3
}

read -n1 -p $'请选择:\n1 创建容器\n2 设置容器\n3 修改配置\n:' choose
case "$choose" in
1)
	read -n1 -p $'\n1 创建\n2 恢复\n3 克隆\n:' ncreate
    read -p $'\n容器名:' hostname 
    case "$ncreate" in
    1)
    	read -p $'模版存储:\n'"`pvesh ls /storage |awk '{print $2}'`"$'\n:' storage
    	ost=`pveam list $storage | awk 'NR>1{print $1}'`
    	read -p $'模版:\n'"$ost"$'\n:' ostemplate
    	if [[ "$ost" =~ "$ostemplate" ]] ; then
    		read -p $'存储:\n'"`pvesh ls /storage |awk '{print $2}'`"$'\n:' rootfs
    		read -p "硬盘大小 N(GB):" rootfssize0
    		read -p "网桥<bridge>(i.e:vmbr0):" bridge
	     	read -p "IPv4地址<IPv4/CIDR|dhcp>:" ip
	      if [[ "$ip" != "dhcp" ]] ; then
	      	cidr=${ip##*/}
	      	ip=${ip%/*}
	    		read -p "网关地址:" gw
	    	fi
	    	read -p "域名(默认和主机一致):" searchdomain
	    	read -p "DNS(默认和主机一致):" nameserver
			  if [[ "`pvesh ls /storage |awk '{print $2}'`" =~ $rootfs ]] ; then
					if [ $rootfssize0 ] ; then
						scmd=$scmd" --rootfs "$rootfs:$rootfssize0
					else
						scmd=$scmd" --rootfs "$rootfs:$rootfssize
					fi
		    else
			   		echo "没有设置存储!"
			     	exit
		    fi
				read -p $'其他选项(可多个选项,空格分隔):\n--arch <amd64|arm64|armhf|i386>(default=amd64)\n--bwlimit <number>(0-N)\n--cmode <console|shell|tty>(default=tty)\n--console <boolean>(default=1)\n--cores <integer>(1-128)\n--cpulimit <number>(0-128)(default=0)\n--cpuunits <integer>(0-500000)(default=1024)\n--description <string>\n--features [force_rw_sys=<1|0>][,fuse=<1|0>][,keyctl=<1|0>][,mknod=<1|0>][,mount=<fstype;fstype;...>][,nesting=<1|0>]\n--force <boolean>\n--hookscript <string>\n--ignore-unpack-errors <boolean>\n--lock <backup|create|destroyed|disk|fstrim|migrate|mounted|rollback|snapshot|snapshot-delete>\n--memory <integer>(16-N)(default=512)\n--mp[n] [volume=]<volume>,mp=<Path>[,acl=<1|0>][,backup=<1|0>][,mountoptions=<opt[;opt...]>][,quota=<1|0>][,replicate=<1|0>][,ro=<1|0>][,shared=<1|0>][,size=<DiskSize>]\n--nameserver <string>\n--net[n] name=<string>[,bridge=<bridge>][,firewall=<1|0>][,gw=<GatewayIPv4>][,gw6=<GatewayIPv6>][,hwaddr=<XX:XX:XX:XX:XX:XX>][,ip=<(IPv4/CIDR|dhcp|manual)>][,ip6=<(IPv6/CIDR|auto|dhcp|manual)>][,mtu=<integer>][,rate=<mbps>][,tag=<integer>][,trunks=<vlanid[;vlanid...]>][,type=<veth>]\n--onboot <boolean>(default=0)\n--ostype <alpine|archlinux|centos|debian|fedora|gentoo|opensuse|ubuntu|unmanaged>\n--password <password>\n--pool <string>\n--protection <boolean> (default=0)\n--restore <boolean>\n--rootfs [volume=]<volume>[,acl=<1|0>][,mountoptions=<opt[;opt...]>][,quota=<1|0>][,replicate=<1|0>][,ro=<1|0>][,shared=<1|0>][,size=<DiskSize>]\n--searchdomain <string>\n--ssh-public-keys <filepath>\n--start <boolean> (default = 0)\n--startup  `[[order=]\d+] [,up=\d+] [,down=\d+] `\n--swap <integer> (0 - N) (default = 512)\n--tags <string>\n--template <boolean> (default = 0)\n--tty <integer>(0-6)(default=2)\n--unique <boolean>\n--unprivileged <boolean> (default = 0)\n:' ocp
				scmd=$scmd" "$ocp
 
		
			  if ( [ $arch ] && ! [[ $scmd =~ "--arch" ]] ) then
						scmd=$scmd" --arch "$arch
				fi
		         	    	
			  if ( [ $bwlimit ] && ! [[ $scmd =~ "--bwlimit" ]] ) then
					scmd=$scmd" --bwlimit "$bwlimit
				fi
		
				if ( [ $cmode ] && ! [[ $scmd =~ "--cmode" ]] ) then
					scmd=$scmd" --cmode "$cmode
				fi
		
				if ( [ $console ] && ! [[ $scmd =~ "--console" ]] ) then
					scmd=$scmd" --console "$console
				fi
				if ( [ $cores ]  && ! [[ $scmd =~ "--cores" ]] ) then
					scmd=$scmd" --cores "$cores
				fi
			  if ( [ $cpulimit ]  && ! [[ $scmd =~ "--cpulimit" ]] ) then
					scmd=$scmd" --cpulimit "$cpulimit
				fi
				if ( [ $cpuunits ]  && ! [[ $scmd =~ "--cpuunits" ]] ) then
					scmd=$scmd" --cpuunits "$cpuunits
				fi
				if ( [ $description ]  && ! [[ $scmd =~ "--description" ]] ) then
					scmd=$scmd" --description "$description
				fi
				if ( [ $features ]  && ! [[ $scmd =~ "--features" ]] ) then
					scmd=$scmd" --features "$features
				fi
				if ( [ $force ]  && ! [[ $scmd =~ "--force" ]] ) then
					scmd=$scmd" --force "$force
				fi
			  if ( [ $hookscript ]  && ! [[ $scmd =~ "--hookscript" ]] ) then
					scmd=$scmd" --hookscript "$hookscript
				fi
				if ( [ $ignoreunpackerrors ]  && ! [[ $scmd =~ "--ignore-unpack-errors" ]] ) then
					scmd=$scmd" --ignore-unpack-errors "$ignoreunpackerrors
				fi
				if ( [ $lock ] && ! [[ $scmd =~ "--lock" ]] ) then
					scmd=$scmd" --lock "$lock
				fi
				if ( [ $memory ] && ! [[ $scmd =~ "--memory" ]] ) then
					scmd=$scmd" --memory "$memory
				fi
				if ( [ $nameserver ] && ! [[ $scmd =~ "--nameserver" ]] ) then
					scmd=$scmd" --nameserver "$nameserver
				fi
				if ( [ $mp0 ]  && ! [[ $scmd =~ "--mp0" ]] ) then
					scmd=$scmd" --mp0 "$mp0
				fi
				if ( [ $onboot ]  && ! [[ $scmd =~ "--onboot" ]] ) then
					scmd=$scmd" --onboot "$onboot
				fi
				if ( [ $ostype ]  && ! [[ $scmd =~ "--ostype" ]] ) then
					scmd=$scmd" --ostype "$ostype
				fi
				if ( [ $password ]  && ! [[ $scmd =~ "--password" ]] ) then
					scmd=$scmd" --password "$password
				fi
				if ( [ $pool ]  && ! [[ $scmd =~ "--pool" ]] ) then
					scmd=$scmd" --pool "$pool
				fi
				if ( [ $protection ]  && ! [[ $scmd =~ "--protection" ]] ) then
					scmd=$scmd" --protection "$protection
				fi
				if ( [ $restore ]  && ! [[ $scmd =~ "--restore" ]] ) then
					scmd=$scmd" --restore "$restore
				fi				
				if ( [ $sshpublickeys ]  && ! [[ $scmd =~ "--ssh-public-keys" ]] ) then
					scmd=$scmd" --ssh-public-keys "$sshpublickeys
				fi
				if ( [ $start ]  && ! [[ $scmd =~ "--start" ]] ) then
					scmd=$scmd" --start "$start
				fi
				if ( [ $startup ]  && ! [[ $scmd =~ "--startup" ]] ) then
					scmd=$scmd" --startup "$startup
				fi
				if ( [ $swap ]  && ! [[ $scmd =~ "--swap" ]] ) then
					scmd=$scmd" --swap "$swap
				fi			
				if ( [ $tags ]  && ! [[ $scmd =~ "--tags" ]] ) then
					scmd=$scmd" --tags "$tags
				fi
				if ( [ $template ]  && ! [[ $scmd =~ "--template" ]] ) then
					scmd=$scmd" --template "$template
				fi
				if ( [ $tty ]  && ! [[ $scmd =~ "--tty" ]] ) then
					scmd=$scmd" --tty "$tty
				fi
				if ( [ $unique ]  && ! [[ $scmd =~ "--unique" ]] ) then
					scmd=$scmd" --unique "$unique
				fi
				if ( [ $unprivileged ] && ! [[ $scmd =~ "--unprivileged" ]] ) then
					scmd=$scmd" --unprivileged "$unprivileged
				fi
				if ( [ $unused0 ]  && ! [[ $scmd =~ "--unused0" ]] ) then
					scmd=$scmd" --unused0 "$unused0
				fi
					
			else
				echo "模版不存在!"
				exit
			fi
		    ;;    
    2)
    	read -p $'备份存储:\n'"`pvesh ls /storage |awk '{print $2}'`"$'\n:' storage
    	node=`hostname`
    	read -p $'源:\n'"`pvesh ls nodes/$node/storage/$storage/content/ | awk '/backup\/vzdump-lxc/{print $2}'`"$'\n:' ostemplate
    	if [[ "$ostemplate" =~ "`pvesh ls nodes/$node/storage/$storage/content/ | awk '/backup\/vzdump-lxc/{print $2}'`" ]] ; then
    		read -p $'存储:\n'"`pvesh ls /storage |awk '{print $2}'`"$'\n:' storage
    		read -p "读取限制(MiB/s):" bwlimit
    		read -p "自动生成唯一属性,如MAC地址<1|0>:" unique
    		read -p "无特权容器<1|0>:" unprivileged
    		read -p "恢复完成自动启动<1|0>:" start
    		if [ $bwlimit ] ; then
			scmd=$scmd" --bwlimit "$bwlimit
		fi
    		if [ $start ] ; then
			scmd=$scmd" --start "$start
		fi
    		if [ $unique ] ; then
			scmd=$scmd" --unique "$unique
		fi
    		if [ $unprivileged ] ; then
			scmd=$scmd" --unprivileged "$unprivileged
		fi				
    	else
    		echo "模版不存在!"
    		exit 8
    	fi
    ;;

    3)
        read -p "模版容器id:" vmid
        if [ -f /etc/pve/lxc/$vmid.conf ] ; then
	        read -p "宿主机名(仅限容器运行于共享存储):" target
	        read -p $'存储:\n'"`pvesh ls /storage |awk '{print $2}'`"$'\n:' storage 
		read -n1 -p "克隆模式(完全 1 | 链接 0):" full
		read -p $'\n快照名:' snapname
		if [ $bwlimit ] ; then
			scmd=$scmd" --bwlimit "$bwlimit
		fi
		if [ $description ] ; then
			scmd=$scmd" --description "$description
		fi
		if [ $full ] ; then
			scmd=$scmd" --full "$full
		fi
		if [ $pool ] ; then
			scmd=$scmd" --pool "$pool
		fi
		if [ $target ] ; then
			scmd=$scmd" --target "$target
		fi
		if [ $snapname ] ; then
			scmd=$scmd" --snapname "$snapname
		fi
		if [ $storage ] ; then
			scmd=$scmd" --storage "$storage
		fi
	else
		echo "模版不存在!"
		exit 3
	fi
    ;;

    esac
    
	read -p "起始id:" svid
    read -p "数量:" nct
   
    tmpid=$svid    
    for((i=1;i<=$nct;i++));
    do
	case "$ncreate" in
	1)
	if [ $hostname ] ; then
		scmd=$scmd" --hostname "$hostname$i
	fi
	if [ $searchdomain ] ; then
		scmd=$scmd" --searchdomain "$hostname$i.$searchdomain
	fi
	if [[ "$ip"!="dhcp" ]] ; then
		netstr=" --net0 bridge=$bridge,name=eth0,ip=$ip/$cidr,gw=$gw"
		ip=${ip%.*}.$(expr 1 + ${ip##*.} ) 
	else
		netstr=" --net0 bridge=$bridge,name=eth0,ip=dhcp"
	fi
            echo "pct create $svid $ostemplate $netstr$scmd" 
            pct create $svid $ostemplate $netstr$scmd 
            echo "容器 $hostname$i 创建成功! ip ${ip%.*}.$(expr -1 + ${ip##*.}  )  "
            #wconfig /etc/pve/lxc/$svid.conf

        ;;
   2)
   if [ $hostname ] ; then
		scmd=$scmd" --hostname "$hostname$i
	 fi
   echo "pct restore $svid $ostemplate$scmd"
   pct restore $svid $ostemplate$scmd
    	;;
   3)
	 if [ $hostname ] ; then
		scmd=$scmd" --hostname "$hostname$i
	 fi
   echo "pct clone $vmid $svid $scmd" 
   pct clone $vmid $svid $scmd
   echo "容器 $hostname$i 克隆成功! "
     	;;
   esac
    
	svid=$(expr 1 + $svid )

     done
     echo "$nct 个容器创建成功 id 为$tmpid 到 $(expr $svid - 1 ) ." 
     ;;
2)
     read -n1 -p $'\n1 挂载目录\n2 运行命令\n3 设置参数\n4 批量操作\n5 杀进程\n:' command
     case "$command" in
      1)
        read -p $'\n'"挂载点ID(N)：" mpid
        read -p "主机目录(/xx)：" path1
        read -p "容器内目录(/xx)：" cpath1
        ;;
      2)
        read -p $'\n完整命令\n:' cmdline
        read -p $'各容器执行间隔秒数(N)\n:' nsecond
        ;;
      3)
        read -p $'\n参数 <arch|cmode|cores|console|cpulimit|cpuunits|delete|features|hookscript|hostname|lock|memory|mp[n]|nameserver|net[n]|onboot|ostype|protection|revert|rootfs|searchdomain|searchdomain|startup|swap|tags|template|tty> \n：' para1
     	case "$para1" in
       	arch)
       		read -p $'选项 amd64 | arm64 | armhf | i386 (default=amd64)\n:' opt1
       	;;
       	cmode)
       		read -p $'选项 console | shell | tty (default=tty)\n:' opt1
       	;;
       	console)
       		read -p "选项 <boolean> (default=1):" opt1
       	;;
       	cores)
       		read -p "选项 <integer> (1-128) :" opt1
       	;;
       	cpulimit)
       		read -p "选项 <integer> (0-128)(default=0) :" opt1
       	;;
       	cpuunits)
       		read -p "选项 <number> (0-500000)(default=1024):" opt1
       	;;
       	delete)
       		read -p "选项 <string>(i.e.: mp1):" opt1
       	;;
       	features)
       		read -p $'选项 [force_rw_sys=<1|0>][,fuse=<1|0>][,keyctl=<1|0>][,mknod=<1|0>][,mount=<fstype;fstype;...>][,nesting=<1|0>]\n:' opt1
       	;;
       	hookscript)
       		read -p "选项 <string>:" opt1
       	;;
       	lock)
       		read -p $'选项 <backup | create | destroyed | disk | fstrim | migrate | mounted | rollback | snapshot | snapshot-delete>\n:' opt1
       	;;
       	memory)
       		read -p "选项 <integer>(16-N):" opt1
       	;;
       	mp*)
       		read -p $'选项 [volume=]<volume>,mp=<Path>[,acl=<1|0>][,backup=<1|0>][,mountoptions=<opt[;opt...]>][,quota=<1|0>][,replicate=<1|0>][,ro=<1|0>][,shared=<1|0>][,size=<DiskSize>]\n:' opt1
       	;;
       	nameserver)
       		read -p "选项 <string>:" opt1
       	;;
       	net*)
       		#read -p $'选项name=<string>[,bridge=<bridge>][,firewall=<1|0>][,gw=<GatewayIPv4>][,gw6=<GatewayIPv6>][,hwaddr=<XX:XX:XX:XX:XX:XX>][,ip=<(IPv4/CIDR|dhcp|manual)>][,ip6=<(IPv6/CIDR|auto|dhcp|manual)>][,mtu=<integer>][,rate=<mbps>][,tag=<integer>][,trunks=<vlanid[;vlanid...]>][,type=<veth>]\n:' opt1
       		read -p "网卡名<string>(i.e:eth0):" nname
       		read -p "网桥<bridge>(i.e:vmbr0):" bridge
       		read -p "ip地址<IPv4/CIRD|dhcp>:" ip
		if [[ "$ip" != "dhcp" ]] ; then
		      	cidr=${ip##*/}
		      	ip=${ip%/*}
	    		read -p "网关地址:" gw
	    	fi
       		read -p $'其他选项[,firewall=<1|0>][,gw6=<GatewayIPv6>][,hwaddr=<XX:XX:XX:XX:XX:XX>][,ip6=<(IPv6/CIDR|auto|dhcp|manual)>][,mtu=<integer>][,rate=<mbps>][,tag=<integer>][,trunks=<vlanid[;vlanid...]>][,type=<veth>]\n:' opt1
       	;;
       	onboot)
       		read -p "选项<boolean>(default=0):" opt1
       	;;
       	ostype)
       		read -p $'选项<alpine|archlinux|centos|debian|fedora|gentoo|opensuse|ubuntu|unmanaged> \n:' opt1
       	;;
       	protection)
       		read -p "选项<boolean>(default=0):" opt1
       	;;
       	revert)
       		read -p "选项 <string>:" opt1
       	;;
       	rootfs)  
       		read -p $'选项[volume=]<volume>[,acl=<1|0>][,mountoptions=<opt[;opt...]>][,quota=<1|0>][,replicate=<1|0>][,ro=<1|0>][,shared=<1|0>][,size=<DiskSize>]\n:' opt1     					
       	;;
       	searchdomain)
       		read -p "主机名<string>:" hostname
       		read -p "域名 <string>:" opt1
       	;;
       	startup)
       		read -p $'选项 `[[order=]\d+][,up=\d+] [,down=\d+]` \n:' opt1
       	;;
       	swap)
       		read -p "选项 <integer> (0-N)(default=512):" opt1
       	;;
       	tags)
       		read -p "选项 <string>:" opt1
       	;;
       	template)
       		read -p "选项<boolean>(default=0):" opt1
       	;;
       	tty)
       		read -p "选项<integer>(0-6)(default=2):" opt1
       	;;
        *)
                read -p "选项:" opt1
        ;;
       	esac
        ;;
      4)
        read -p $'\n命令 <config|df|delsnapshot|destroy|exec|fsck|fstrim|listsnapshot|migrate|mount|move_volume|pending|pull|push|reboot|resize|restore|resume|rollback|set|shutdown|snapshot|start|status|stop|suspend|template|unlock|unmount>\n:' bcmd
        case "$bcmd" in
         config)
           read -p $'选项:\n--current <boolean>(default=0)\n--snapshot <string>\n:' bop
         ;;
         delsnapshot)
           read -p $'选项:\n<snapname>\n--force <boolean>\n:' bop
         ;;
         destroy)
           read -p $'选项:\n--force <boolean>(default=0)\n--purge <boolean>(default=0)\n:' bop
         ;;
         exec)
           read -p $'选项:\n-- <command>\n:' bop
         ;;
         fsck)
           read -p $'选项:\n--device <mp0|..|mp99|rootfs>\n--force <boolean>(default=0)\n:' bop
         ;;
         migrate)
           read -p $'选项:\n<target>\n--bwlimit <number>(0-N)\n--force <boolean>\n--online <boolean>\n--restart <boolean>\n--timeout <integer>(default=180)\n:' bop                
         ;;
         move_volume)
           read -p $'选项:\n<mp0|..|mp99|rootfs> <storage>\n--bwlimit <number>(0-N)\n--delete <boolean>(default=0)\n--digest <string>\n:' bop                
         ;;
         pull)
           read -p $'选项:\n<path> <destination>\n--group <string>\n--perms <string>\n--user <string>\n:' bop                
         ;;
         push)
           read -p $'选项:\n<file> <destination> \n--group <string>\n--perms <string>\n--user <string>\n:' bop                
         ;;
         reboot)
           read -p $'选项:\n--timeout <integer>(0-N)>\n:' bop
         ;;
         resize)
           read -p $'选项:\n<mp0|..|mp99|rootfs> <size>(\+?\d+(\.\d+)?[KMGT]?)\n--digest <string> \n:' bop
         ;;
         restore)
          read -p $'选项:\n<ostemplate>\n--arch <amd64|arm64|armhf|i386>(default=amd64)\n--bwlimit <number>(0-N)\n--cmode <console|shell|tty>(default=tty)\n--console <boolean>(default=1)\n--cores <integer>(1-128)\n--cpulimit <number>(0-128)(default=0)\n--cpuunits <integer>(0-500000)(default=1024)\n--description <string>\n--features [force_rw_sys=<1|0>][,fuse=<1|0>][,keyctl=<1|0>][,mknod=<1|0>][,mount=<fstype;fstype;...>][,nesting=<1|0>]\n--force <boolean>\n--hookscript <string>\n--hostname <string>\n--ignore-unpack-errors <boolean>\n--lock <backup|create|destroyed|disk|fstrim|migrate|mounted|rollback|snapshot|snapshot-delete>\n--memory <integer>(16-N)(default=512)\n--mp[n] [volume=]<volume>,mp=<Path>[,acl=<1|0>][,backup=<1|0>][,mountoptions=<opt[;opt...]>][,quota=<1|0>][,replicate=<1|0>][,ro=<1|0>][,shared=<1|0>][,size=<DiskSize>]\n--nameserver <string>\n--net[n] name=<string>[,bridge=<bridge>][,firewall=<1|0>][,gw=<GatewayIPv4>][,gw6=<GatewayIPv6>][,hwaddr=<XX:XX:XX:XX:XX:XX>][,ip=<(IPv4/CIDR|dhcp|manual)>][,ip6=<(IPv6/CIDR|auto|dhcp|manual)>][,mtu=<integer>][,rate=<mbps>][,tag=<integer>][,trunks=<vlanid[;vlanid...]>][,type=<veth>]\n--onboot <boolean>(default=0)\n--ostype <alpine|archlinux|centos|debian|fedora|gentoo|opensuse|ubuntu|unmanaged>\n--password <password>\n--pool <string>\n--protection <boolean>(default=0)\n--rootfs [volume=]<volume>[,acl=<1|0>][,mountoptions=<opt[;opt...]>][,quota=<1|0>][,replicate=<1|0>][,ro=<1|0>][,shared=<1|0>][,size=<DiskSize>]\n--searchdomain <string>\n--ssh-public-keys <filepath>\n--start <boolean>(default=0)\n--startup `[[order=]\d+][,up=\d+][,down=\d+] `\n--storage <string> (default=local)\n--swap <integer>(0-N)(default=512)\n--tags <string>\n--template <boolean>(default=0)\n--tty <integer>(0-6)(default=2)\n--unique <boolean>\n--unprivileged <boolean>(default=0)\n--unused[n] [volume=]<volume>\n:' bop
         ;;
         rollback)
          read -p $'选项:\n<snapname>:' bop
         ;;
         set)
          read -p $'选项:\n--arch <amd64|arm64|armhf|i386>(default=amd64)\n--cmode <console|shell|tty>(default=tty)\n--cores <integer>(1-128)\n--console <boolean>(default=1)\n--cpulimit <number>(0-128)(default=0)\n--cpuunits <integer>(0-500000)(default=1024)\n--delete <string>\n--description <string>\n--digest <string>\n--features [force_rw_sys=<1|0>][,fuse=<1|0>][,keyctl=<1|0>][,mknod=<1|0>][,mount=<fstype;fstype;...>][,nesting=<1|0>]\n--hookscript <string>\n--lock <backup|create|destroyed|disk|fstrim|migrate|mounted|rollback|snapshot|snapshot-delete>\n--memory <integer>(16-N)(default=512)\n--mp[n] [volume=]<volume>,mp=<Path>[,acl=<1|0>][,backup=<1|0>][,mountoptions=<opt[;opt...]>][,quota=<1|0>][,replicate=<1|0>][,ro=<1|0>][,shared=<1|0>][,size=<DiskSize>]\n--nameserver <string>\n--net[n] name=<string>[,bridge=<bridge>][,firewall=<1|0>][,gw=<GatewayIPv4>][,gw6=<GatewayIPv6>][,hwaddr=<XX:XX:XX:XX:XX:XX>][,ip=<(IPv4/CIDR|dhcp|manual)>][,ip6=<(IPv6/CIDR|auto|dhcp|manual)>][,mtu=<integer>][,rate=<mbps>][,tag=<integer>][,trunks=<vlanid[;vlanid...]>][,type=<veth>]\n--onboot <boolean>(default=0)\n--ostype <alpine|archlinux|centos|debian|fedora|gentoo|opensuse|ubuntu|unmanaged>\n--protection <boolean> (default=0)\n--revert <string>\n--rootfs [volume=]<volume>[,acl=<1|0>][,mountoptions=<opt[;opt...]>][,quota=<1|0>][,replicate=<1|0>][,ro=<1|0>][,shared=<1|0>][,size=<DiskSize>]\n--searchdomain <string>\n--startup  `[[order=]\d+] [,up=\d+] [,down=\d+] `\n--swap <integer> (0 - N) (default = 512)\n--tags <string>\n--template <boolean> (default = 0)\n--tty <integer>(0-6)(default=2)\n:' bop
         ;;
         shutdown)
          read -p $'选项:\n--<forceStop <boolean>\n--timeout <integer>\n:' bop
         ;;
         snapshot)
           read -p $'选项:\n--description <string> :' bop
         ;;                
         start)
           read -p $'选项:\n--skiplock <boolean> \n:' bop
         ;;
         status)
           read -p $'选项:\n--verbose <boolean> \n:' bop
         ;;                
         stop)
           read -p $'选项:\n--skiplock <boolean> \n:' bop
         ;;
         *)
           read -p "选项:" bop
         ;;
         esac
         ;;
        5)
       	read -p $'\n进程名\n:' scmd
        ;;
        esac

        read -n1 -p $'1 批量\n2 全部\n' command1
        case "$command1" in
        1)
                read -p $'\n'"起始id:" svid
                read -p "数量:" nct
                for((i=1;i<=$nct;i++));
                do
                  if [ -f /etc/pve/lxc/$svid.conf ] ; then
                        case "$command" in
                        1)
                                echo "pct set $svid --mp$mpid $path1,mp=$cpath1 "
                                pct set $svid --mp$mpid $path1,mp=$cpath1 
                                 ;;
                        2)
                                echo "pct exec $svid -- $cmdline "
                                pct exec $svid -- $cmdline 
                                if [ $nsecond ] ; then
                                sleep $nsecond
                                fi
                                ;;
                        3)
                  		case "$para1" in
                       		net*)
                        	if [[ "$ip"!="dhcp" ]] ; then
					netstr=" bridge=$bridge,name=$nname,ip=$ip/$cidr,gw=$gw$opt1"
					ip=${ip%.*}.$(expr 1 + ${ip##*.} ) 
				else
					netstr="ip=dhcp,bridge=$bridge,name=$nname$opt1"
				fi
                        	echo "pct set $svid --$para1 $netstr"
                        	pct set $svid --$para1 $netstr
                        	;;
                        	hostname)
                                echo "pct set $svid --$para1 $opt1$i"
                                pct set $svid --$para1 $opt1$i
                        	;;
                        	searchdomain)
                                echo "pct set $svid --$para1 $hostname$i.$opt1"
                                pct set $svid --$para1 $hostname.$opt1
                        	;;
                        	*)
                                echo "pct set $svid --$para1 $opt1"
                                pct set $svid --$para1 $opt1
                                ;;
                                esac
                                ;;
                        4)
                                echo "pct $bcmd $svid $bop"
                                pct $bcmd $svid $bop
                                ;;
                        5)
                        	pid=`pct exec $svid -- pidof $scmd`
                        	presult=`pct exec $svid -- kill -9 $pid`
                        	echo $scmd $presult"Killed"
                        	;;
                        
                        esac
                  else
                        echo "$svid 不存在!"
                  fi
                  svid=$(expr 1 + $svid )
                done
                ;;
        2)
                vid=`ls -l /etc/pve/lxc/ | awk 'NR>1{print $9}'`
                i=1
                for svid in $vid
                do        
                        case "$command" in
                        1)
                                echo "pct set ${svid%.*} --mp$mpid $path1,mp=$cpath1 "
                                pct set ${svid%.*} --mp$mpid $path1,mp=$cpath1 
                                ;;
                        2)
                                echo "pct exec ${svid%.*} -- $cmdline" 
                                pct exec ${svid%.*} -- $cmdline 
                                if [ $nsecond ] ; then
                                sleep $nsecond
                                fi
                                ;;
                        3)
                  		case "$para1" in
	               		net*)
	               		if [[ "$ip"!="dhcp" ]] ; then
					netstr=" bridge=$bridge,name=$nname,ip=$ip/$cidr,gw=$gw$opt1"
					ip=${ip%.*}.$(expr 1 + ${ip##*.} )
				else
					netstr="ip=dhcp,bridge=$bridge,name=$nname$opt1"
				fi
				echo "pct set ${svid%.*} --$para1 $netstr$opt1"
				pct set ${svid%.*} --$para1 $netstr$opt1
	               		;;
	               		hostname)
	               			echo "pct set ${svid%.*} --$para1 $opt1$i"
	                               	pct set ${svid%.*} --$para1 $opt1$i
	               		;;
	               		searchdomain)
	               			echo "pct set ${svid%.*} --$para1 $hostname$i.$opt1"
	                              	pct set ${svid%.*} --$para1 $hostname$i.$opt1
	               		;;
	               		*)
	                               	echo "pct set ${svid%.*} --$para1 $opt1"
	                               	pct set ${svid%.*} --$para1 $opt1
	                     	;;
                                esac
                                ;;
                        4)
                                echo "pct $bcmd ${svid%.*} $bop"
                                pct $bcmd ${svid%.*} $bop
                                ;;
                        5)
                                pid=`pct exec ${svid%.*} -- pidof $scmd`
                       		presult=`pct exec ${svid%.*} -- kill -9 $pid`
                       		echo $scmd $presult"Killed"
                       		;;
                        esac
                   i=$(expr 1 + $i)
                done
                ;;
        esac
        ;;
        
3)
        read -n1 -p $'\n1 增加配置\n2 删除配置\n3 修改配置\n:' command
      	read -n1 -p $'\n1 批量\n2 全部\n' command1
	      nfile=`ls -l /etc/pve/lxc/ | awk 'NR>1{print $9}'`
        case "$command" in 
        1)
	      	case "$command1" in
	      	1)
	        read -p $'\n'"起始id:" svid
	        read -p "数量:" nct
	        for((i=1;i<=$nct;i++));
	        do
              if [ -f /etc/pve/lxc/$svid.conf ] ; then
              wconfig /etc/pve/lxc/$svid.conf
              else
              echo "$svid不存在!"
              fi
              svid=$(expr 1 + $svid )
	        done
	        ;;
	      	2)
	        for slxc in $nfile
	        do
	             wconfig /etc/pve/lxc/$slxc
	        done
	        ;;
      		esac
      	;;
	2)
	      case "$command1" in
	      1)
	        read -p $'\n'"起始id:" svid
	        read -p "数量:" nct
	        for((i=1;i<=$nct;i++));
	        do
             	 if [ -f /etc/pve/lxc/$svid.conf ] ; then
              		 sedfile /etc/pve/lxc/$svid.conf
                 else
              		echo "$svid不存在!"
              	 fi
              	 svid=$(expr 1 + $svid )
	        done
	        ;;
	      2)
	        for slxc in $nfile
	        do
              		sedfile /etc/pve/lxc/$slxc
	        done
	        ;;
	      esac      
	      ;;
	      3)
	      read -p $'\n'"要被替换的字符串"$'\n:' strbre
	      read -p "替换的字符串"$'\n:' strre
	      case "$command1" in
	      1)
	        read -p $'\n'"起始id:" svid
	        read -p "数量:" nct
	        for((i=1;i<=$nct;i++));
	        do
              if [ -f /etc/pve/lxc/$svid.conf ] ; then
              replaceconf $strbre $strre /etc/pve/lxc/$svid.conf
              else
              echo "$svid不存在!"
              fi
              svid=$(expr 1 + $svid )
	        done
	        ;;
	      2)
	        for slxc in $nfile
	        do
              replaceconf $strbre $strre /etc/pve/lxc/$slxc
	        done
	        ;;
	      esac      
	      ;;
	   esac   
;;
esac
