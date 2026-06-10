#!/bin/bash
# Incredible PBX Copyright (C) 2005-2025, Ward Mundy & Associates LLC.
# This program installs Asterisk, Incredible PBX and GUI, and utilities.
# All programs copyrighted and licensed by their respective companies.
#
# Portions Copyright (C) 1999-2022, Digium, Inc.
# Portions Copyright (C) 2005-2025, Sangoma Technologies, Inc.
# Portions Copyright (C) 2005-2025, Ward Mundy & Associates LLC
# Portions Copyright (C) 2014-2016, Eric Teeter teetere@charter.net
# Portions Copyright (C) 2020-2025, Joe McConnaughey, @kenn10
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.
# After install, licenses can be found at /var/www/html/admin/licenses.
#

exec > >(tee -i /root/incrediblepbx-install-log.txt)
exec 2>&1

PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
export PATH

sed -i 's|rm -i|rm -f|' /root/.bashrc
sed -i 's|cp -i|cp -f|' /root/.bashrc
sed -i 's|mv -i|mv -f|' /root/.bashrc

sysctl -w net.ipv6.conf.all.disable_ipv6=1
sysctl -w net.ipv6.conf.default.disable_ipv6=1
sysctl -w net.ipv6.conf.lo.disable_ipv6=1

echo "nameserver 8.8.8.8" > /etc/resolv.conf
echo "nameserver 1.1.1.1" >> /etc/resolv.conf
echo "nameserver 4.4.4.4" >> /etc/resolv.conf

clear
temp=true
while $temp; do
   # Prompt the user for input
   read -p "Asterisk 22 LTS is installed by default. Would you prefer Asterisk 23? (y/n): " choice

        # Handle the response using a case statement
        case "$choice" in
            [Yy]* )
                temp=false
		MyPick=23
                ;;
            [Nn]* )
                temp=false
		MyPick=22
                ;;
            * )
                echo "Invalid input. Please enter 'y' for yes or 'n' for no."
                ;;
        esac
done
clear
MyPick=22
echo "FreePBX does not yet support Asterisk 23. Asterisk $MyPick will be installed..."




apt-get update -y
apt-get upgrade -y

apt-get -y install sudo ca-certificates curl gnupg lsb-release debian-archive-keyring

# new pieces for Debian 13
install -d -m 0755 /usr/share/keyrings
. /etc/os-release
CODENAME="$VERSION_CODENAME"


## New deb822 format for Debian 13 and forward
cat > /etc/apt/sources.list.d/debian.sources <<EOF
Types: deb
URIs: https://deb.debian.org/debian
Suites: ${CODENAME} ${CODENAME}-updates
Components: main contrib non-free non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg

Types: deb
URIs: https://security.debian.org/debian-security
Suites: ${CODENAME}-security
Components: main contrib non-free non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg
EOF

### Sury PHP Repo ###
curl -fsSL https://packages.sury.org/php/apt.gpg \
    | gpg --dearmor -o /usr/share/keyrings/sury-php.gpg

cat > /etc/apt/sources.list.d/sury-php.list <<EOF
deb [signed-by=/usr/share/keyrings/sury-php.gpg] https://packages.sury.org/php/ ${CODENAME} main
EOF

### Webmin Repo ###
curl -fsSL https://download.webmin.com/jcameron-key.asc \
    | gpg --dearmor -o /usr/share/keyrings/webmin.gpg

cat > /etc/apt/sources.list.d/webmin.list <<EOF
deb [signed-by=/usr/share/keyrings/webmin.gpg] https://download.webmin.com/download/repository sarge contrib
EOF

### NodeJS Repo ###
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key \
  | gpg --dearmor -o /usr/share/keyrings/nodesource.gpg

cat > /etc/apt/sources.list.d/nodesource.list <<EOF
deb [signed-by=/usr/share/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x ${CODENAME} main
EOF

apt-get update -y 

apt-get install libapache2-mod-fcgid -y

apt-get install -y php8.2 php8.2-{fpm,common,cli,curl,mysql,gd,mbstring,xml,zip,intl,bcmath,opcache,imagick,redis,memcached,soap} -y

apt-get install -y \
    build-essential \
    git \
    subversion \
    autoconf \
    automake \
    libtool \
    libtool-bin \
    pkg-config \
    bison \
    flex 

apt-get install -y \
    libssl-dev \
        libxml2-dev \
        libsqlite3-dev \
        libjansson-dev \
        uuid-dev \
        libedit-dev \
        libcurl4-openssl-dev \
        libicu-dev \
        libsrtp2-dev \
        libspandsp-dev \
        libical-dev \
        libneon27-dev \
        unixodbc-dev \
        odbc-mariadb\

 apt-get install -y ffmpeg \
        lame \
        mpg123 \
        sox \
        libasound2-dev \
        libogg-dev \
        libvorbis-dev

apt-get install -y apache2 \
        mariadb-server \
        mariadb-client \
        openssh-server


apt-get install -y fail2ban \
        iptables \
        iptables-persistent \
        ipset \
        knockd

apt-get install -y htop \
        sngrep \
        vim \
        nano \
        expect \
        dialog \
        net-tools

apt-get install -ypython3 \
        python3-pip \
        python-dev-is-python3


 apt-get install -y libnewt-dev libncurses5-dev libxml2-dev default-libmysqlclient-dev  libedit-dev openvpn
apt-get install -y php-pear sqlite3 pkg-config automake libtool autoconf uuid
apt-get install -y   libtool-bin python-dev-is-python3 unixodbc nodejs npm 
 
apt-get install -y net-tools php-soap postfix 
apt-get install webmin -y

apt-get install cron -y

apt-get install -y sendmail mailutils
apt-get install redis-server redis-tools -y
apt-get install libtiff-tools -y
apt-get install ghostscript -y
apt-get -y install jq libsox-fmt-all


apt-get install ntp -y

a2enmod proxy_fcgi setenvif
a2enconf php8.2-fpm
systemctl enable --now php8.2-fpm
systemctl restart apache2

apt-get -y purge php8.1 php8.3
rm -rf /etc/php/8.1 /etc/php/8.3
a2enmod php8.2
update-alternatives --set php /usr/bin/php8.2
systemctl restart apache2

## Install Webmin ##
cd /root
wget -qO /usr/share/keyrings/debian-webmin-developers.gpg http://download.webmin.com/jcameron-key.asc
curl -o webmin-setup-repo.sh https://raw.githubusercontent.com/webmin/webmin/master/webmin-setup-repo.sh
sh webmin-setup-repo.sh -f
sed -i 's|deb http://download.webmin.com/download/repository sarge contrib|#deb http://download.webmin.com/download/repository sarge contrib|' /etc/apt/sources.list
apt-get update
apt-get install webmin -y
sed -i 's|10000|9001|g' /etc/webmin/miniserv.conf
systemctl restart webmin
systemctl restart apache2


### Set up VIM for root user ###
echo "
set hlsearch
set mouse=r" > /root/.vimrc

cd /usr/src
wget http://incrediblepbx.com/iksemel-1.4.tar.gz
tar zxvf iksemel-1.4.tar.gz
cd iksemel-1.4
./configure --prefix=/usr --with-libgnutls-prefix=/usr
make
make check
make install
echo "/usr/local/lib" > /etc/ld.so.conf.d/iksemel.conf
ldconfig
cd /usr/src
mv *.tar.gz /tmp

if [[ "$MyPick" == "22" ]]; then
 wget http://downloads.asterisk.org/pub/telephony/asterisk/asterisk-22-current.tar.gz
 tar xvf asterisk-22-current.tar.gz
 cd asterisk-22*/
else
 wget http://downloads.asterisk.org/pub/telephony/asterisk/asterisk-23-current.tar.gz
 tar xvf asterisk-23-current.tar.gz
 cd asterisk-23*/
fi
contrib/scripts/get_mp3_source.sh
contrib/scripts/install_prereq install
#wget http://incrediblepbx.com/menuselect-incredible18-debian10.tar.gz
wget http://incrediblepbx.com/menuselect-incredible2025.tar.gz
tar zxvf menuselect-incredible*
rm -rf menuselect-incredible*
CFLAGS='-DENABLE_SRTP_AES_256 -DENABLE_SRTP_AES_GCM' 
./configure --with-pjproject-bundled --with-jansson-bundled
make menuselect.makeopts
 menuselect/menuselect --enable-category MENUSELECT_ADDONS menuselect.makeopts
 menuselect/menuselect --enable-category MENUSELECT_CODECS menuselect.makeopts
 menuselect/menuselect --disable-category MENUSELECT_TESTS menuselect.makeopts
 menuselect/menuselect --enable codec_opus menuselect.makeopts
 menuselect/menuselect --enable codec_silk menuselect.makeopts
 menuselect/menuselect --enable codec_siren7 menuselect.makeopts
 menuselect/menuselect --enable codec_siren14 menuselect.makeopts
 menuselect/menuselect --enable codec_g729a menuselect.makeopts
make menuselect.makeopts
make
make install
make samples
make config
ldconfig

groupadd asterisk
useradd -r -d /var/lib/asterisk -g asterisk asterisk
usermod -aG audio,dialout asterisk
chown -R asterisk:asterisk /etc/asterisk
chown -R asterisk:asterisk /var/{lib,log,spool}/asterisk
chown -R asterisk:asterisk /usr/lib64/asterisk

sed -i 's|#AST_USER|AST_USER|' /etc/default/asterisk
sed -i 's|#AST_GROUP|AST_GROUP|' /etc/default/asterisk
sed -i 's|;runuser|runuser|' /etc/asterisk/asterisk.conf
sed -i 's|;rungroup|rungroup|' /etc/asterisk/asterisk.conf
ldconfig

systemctl restart asterisk

sed -i 's/\(^upload_max_filesize = \).*/\120M/' /etc/php/8.2/apache2/php.ini
sed -i 's/\(emory_limit = \).*/\1256M/' /etc/php/8.2/apache2/php.ini
sed -i 's/^\(User\|Group\).*/\1 asterisk/' /etc/apache2/apache2.conf
sed -i 's/AllowOverride None/AllowOverride All/' /etc/apache2/apache2.conf
a2enmod rewrite
systemctl restart apache2
rm /var/www/html/index.html

cat <<EOF > /etc/odbcinst.ini
[MySQL]
Description = ODBC for MySQL (MariaDB)
Driver = /usr/lib/x86_64-linux-gnu/odbc/libmaodbc.so
FileUsage = 1
EOF

cat <<EOF > /etc/odbc.ini
[MySQL-asteriskcdrdb]
Description = MySQL connection to 'asteriskcdrdb' database
Driver = MySQL
Server = localhost
Database = asteriskcdrdb
Port = 3306
Socket = /var/run/mysqld/mysqld.sock
Option = 3
EOF

systemctl stop asterisk
systemctl disable asterisk
killall asterisk
touch cdr.conf



cd /usr/src/

wget http://mirror.freepbx.org/modules/packages/freepbx/freepbx-17.0-latest.tgz
tar zxvf freepbx-17.0-latest.tgz
cd /usr/src/freepbx/
./start_asterisk start
./install -n
fwconsole ma installall
fwconsole ma enablerepo standard extended unsupported
fwconsole ma downloadinstall superfecta queueprio miscdests miscapps outcnam dynroute extensionsettings disa allowlist
fwconsole ma remove firewall synologyabb
wget https://filedn.com/lBgbGypMOdDm8PWOoOiBR7j/Debian12/incrediblepbx-17.0.0.tgz
#fwconsole ma install incrediblepbx

echo "Now downloading and restoring FreePBX backup of core IncrediblePBX system."
cd /tmp
wget https://filedn.com/lBgbGypMOdDm8PWOoOiBR7j/Debian12/20240725-153553-1721936153-17.0.17.1-791763876.tar.gz
fwconsole backup --restore /tmp/20240725-153553-1721936153-17.0.17.1-791763876.tar.gz
rm 20240725-153553-1721936153-17.0.17.1-791763876.tar.gz

fwconsole reload
fwconsole restart

cat <<EOF > /etc/systemd/system/freepbx.service
[Unit]
Description=FreePBX VoIP Server
After=mariadb.service
[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/sbin/fwconsole start -q
ExecStop=/usr/sbin/fwconsole stop -q
[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable freepbx

mysql -u root -e "ALTER USER 'root'@'localhost' IDENTIFIED BY 'passw0rd';"


echo "
<Directory /var/www/html/admin/licenses>
	Options Indexes FollowSymLinks
	AllowOverride All
	Require all granted
</Directory>
" >> /etc/apache2/apache2.conf
systemctl restart apache2

fwconsole setting HTTPTLSBINDADDRESS 127.0.0.1
fwconsole setting HTTPBINDADDRESS 127.0.0.1
A=$SRANDOM$SRANDOM$SRANDOM$SRANDOM
B=${A:1:15}
fwconsole setting FPBX_ARI_USER $B
A=$SRANDOM$SRANDOM$SRANDOM$SRANDOM
C=${A:0:30}
fwconsole setting FPBX_ARI_PASSWORD $C
rm /tmp/*

mysql -u root -ppassw0rd asterisk -e "update freepbx_settings SET value = '1' where keyword='CDR_BATCH_ENABLE';"
mysql -u root -ppassw0rd asterisk -e "update admin SET value = 'true' where variable='need_reload';"

chmod +x /usr/bin/python3.11
asterisk -rx "database put blacklist dest app-blackhole,no-service,1"
#IPtables Setup
cd /root
echo iptables-persistent iptables-persistent/autosave_v4 boolean true | debconf-set-selections
echo iptables-persistent iptables-persistent/autosave_v6 boolean true | debconf-set-selections
apt-get install -y iptables-persistent dialog
#cd /etc/init.d
wget http://incrediblepbx.com/iptables-persistent-U.tar.gz
tar zxvf iptables-persistent-U.tar.gz
rm iptables-persistent-U.tar.gz
cd /root

# server IP address is?
serverip=`ifconfig | grep "inet " | head -1 | cut -f 2 -d ":" | tr -s " " | cut -f 3 -d " "`
# user IP address while logged into SSH is?
userip=`echo $SSH_CONNECTION | cut -f 1 -d " "`
# public IP address in case we're on private LAN
#publicip=`curl -s -S --user-agent "Mozilla/4.0" http://myip.incrediblepbx.com | awk 'NR==2'`
publicip=`curl https://ipinfo.io/ip`
# WhiteList all of them by replacing 8.8.4.4 and 8.8.8.8 and 74.86.213.25 entries
cp /etc/iptables/rules.v4 /etc/iptables/rules.v4.orig
cd /etc/iptables
cp /etc/iptables/rules.v4 /etc/iptables/rules.v4.orig
wget http://incrediblepbx.com/iptables4-ubuntu18.04.2.tar.gz
tar zxvf iptables4-ubuntu18.04.2.tar.gz
rm iptables4-ubuntu18.04.2.tar.gz
mv iptables-custom /usr/local/sbin
mv openssl.cnf /etc/ssl
cp rules.v4.tm3 rules.v4
sed -i 's|8.8.4.4|'$serverip'|' /etc/iptables/rules.v4
sed -i 's|8.8.8.8|'$userip'|' /etc/iptables/rules.v4
sed -i 's|74.86.213.25|'$publicip'|' /etc/iptables/rules.v4

badline=`grep -n "\-s  \-p" /etc/iptables/rules.v4 | cut -f1 -d: | tail -1`
while [[ "$badline" != "" ]]; do
sed -i "${badline}d" /etc/iptables/rules.v4
badline=`grep -n "\-s  \-p" /etc/iptables/rules.v4 | cut -f1 -d: | tail -1`
done
sed -i 's|-A INPUT -s  -j|#-A INPUT -s  -j|g' /etc/iptables/rules.v4
#sed -i 's|#-A INPUT -p tcp -m tcp --dport 22|-A INPUT -p tcp -m tcp --dport 22|' rules.v4
ln -s /etc/init.d/iptables-persistent /etc/init.d/iptables
echo "/usr/sbin/iptables -A INPUT -s 100.64.0.0/10 -j ACCEPT" >> /usr/local/sbin/iptables-custom

sed -i 's|/usr/sbin/iptables -A INPUT -p udp -m udp -s sip1.v1voip|#/usr/sbin/iptables -A INPUT -p udp -m udp -s sip1.v1voip|' /usr/local/sbin/iptables-custom
sed -i 's|/usr/sbin/iptables -A INPUT -p udp -m udp -s sip2.v1voip|#/usr/sbin/iptables -A INPUT -p udp -m udp -s sip2.v1voip|' /usr/local/sbin/iptables-custom
sed -i 's|/usr/sbin/iptables -A INPUT -p udp -m udp -s sip.v1voip|#/usr/sbin/iptables -A INPUT -p udp -m udp -s sip.v1voip|' /usr/local/sbin/iptables-custom
sed -i 's|/usr/sbin/iptables -A INPUT -s sip.nexmo.com|#/usr/sbin/iptables -A INPUT -s sip.nexmo.com|' /usr/local/sbin/iptables-custom
sed -i 's|/usr/sbin/iptables -I INPUT -s api.nexmo.com|#/usr/sbin/iptables -I INPUT -s api.nexmo.com|' /usr/local/sbin/iptables-custom
sed -i 's|/usr/sbin/iptables -A INPUT -s sip.signalwire|#/usr/sbin/iptables -A INPUT -s sip.signalwire|' /usr/local/sbin/iptables-custom

/usr/local/sbin/iptables-custom
systemctl restart iptables
/usr/local/sbin/iptables-custom

cd /
wget http://incrediblepbx.com/rootfiles-debian10.tar.gz
tar zxvf rootfiles-debian10.tar.gz
rm rootfiles-debian10.tar.gz
chattr -i /root/up*

cd /usr/local/sbin
wget https://filedn.com/lBgbGypMOdDm8PWOoOiBR7j/images/pbxstatus-2027D
mv pbxstatus-2027D pbxstatus
chmod +x pbxstatus



# kill all the endless Fail2Ban alerts
sed -i 's|you@example.com|devnull@localhost|' /etc/fail2ban/jail.conf
sed -i 's|#allowipv6 = auto|allowipv6 = no|' /etc/fail2ban/fail2ban.conf
sed -i 's|sshd_log = %(syslog_authpriv)s|sshd_log = /var/log/sshd.log|' /etc/fail2ban/paths-common.conf
mkdir /var/log/sshd.log
sed -i 's|%(sshd_log)s|/var/log/sshd.log|' /etc/fail2ban/jail.conf
#echo "sshd_backend = systemd" >> /etc/fail2ban/paths-debian.conf
sed -i 's|fail2ban-client -x start|#fail2ban-client -x start|' /etc/fail2ban/paths-debian.conf

systemctl enable fail2ban
systemctl start fail2ban

# remove CentOS fax installer
rm -f /root/incrediblefax*

### Install Asteridex for FreePBX-17 ###
cd /
wget https://filedn.com/lBgbGypMOdDm8PWOoOiBR7j/Debian12/asteridex17.tar.gz -O asteridex17.tar.gz
tar zxvf asteridex17.tar.gz
rm -f asteridex17.tar.gz
cd /var/www/html/asteridex17/mysql
./loadmysql.sh
cd /var/www/html/admin/modules
wget https://filedn.com/lBgbGypMOdDm8PWOoOiBR7j/Debian12/incrediblepbx-17.0.0.tgz
tar zxvf incrediblepbx-17.0.0.tgz
cd /root
fwconsole ma install asteridex
fwconsole ma downloadinstall https://filedn.com/lBgbGypMOdDm8PWOoOiBR7j/IncrediblePBX-Branding-Module/incrediblepbx-17.0.0.tgz
./sig-fix
./sig-fix

# CentOS-like color scheme for ls
echo "export LS_OPTIONS='--color=auto'
eval \"\`dircolors\`\"
alias ls='ls \$LS_OPTIONS'
alias ll='ls -l \$LS_OPTIONS'" >> /etc/bash.bashrc

cd /var/www/html/admin
wget https://filedn.com/lBgbGypMOdDm8PWOoOiBR7j/Debian12/iPBX-licenses.tar.gz
tar zxvf iPBX-licenses.tar.gz
rm iPBX-licenses.tar.gz


# Checking for IPv6
#test=`ifconfig | grep inet6`
#if [ -z "$test" ]; then
# echo "IPv6 not enabled."
#else
 echo "Disabling IPv6..."
 echo "net.ipv6.conf.all.disable_ipv6 = 1" > /etc/sysctl.d/70-disable-ipv6.conf
 sysctl -p -f /etc/sysctl.d/70-disable-ipv6.conf
 echo "IPv6 has been disabled."
#fi

/usr/local/sbin/iptables-custom
iptables-save

if [ -e "/usr/sbin/fwconsole" ]; then
 echo " "
else
 ln -s /var/lib/asterisk/bin/fwconsole /usr/sbin/fwconsole
fi

rm -f /root/upgrade-asterisk16
rm -f /root/upgrade-asterisk18
sed -i 's|7.3|8.2|' /root/timezone-setup



echo "# .bash_profile
# Get the aliases and functions
if [ -f ~/.bashrc ]; then
	. ~/.bashrc
fi
# User specific environment and startup programs
PATH=$PATH:$HOME/bin
export PATH
pbxstatus -p" > /root/.bash_profile

mysql -u root -ppassw0rd asterisk -e 'UPDATE freepbx_settings SET `value` = "Latest-17" WHERE `keyword` = "MIRROR_BRAND_VERSION" LIMIT 1'

systemctl restart mysqld
fwconsole chown
fwconsole reload
fwconsole restart

echo '[Unit]
Description=openvpn2027
ConditionPathExists=/etc/openvpn-start
After=rclocal.service
[Service]
Type=forking
ExecStart=/etc/openvpn-start /etc/incrediblepbx2027.ovpn
TimeoutSec=0
StandardOutput=tty
RemainAfterExit=yes
PermissionsStartOnly=true
SysVStartPriority=99
[Install]
WantedBy=multi-user.target' > /etc/systemd/system/openvpn2027.service
chmod +x /etc/systemd/system/openvpn2027.service
cp -p /root/openvpn-start /etc/openvpn-start
systemctl enable openvpn2027.service
systemctl restart openvpn2027.service

# Watson STT fix
sed -i 's|/usr/local/sbin/we-dont-have-tech-support.wav|/var/lib/asterisk/sounds/en/we-dont-have-tech-support.gsm|' /usr/local/sbin/watson-test
clear

# pbxstatus history fix
sed -i 's|clear|clear -x|' /usr/local/sbin/pbxstatus
cd /usr/local/sbin
wget https://filedn.com/lBgbGypMOdDm8PWOoOiBR7j/IncrediblePBX2027-Debian11/pbxstatus-2027
mv pbxstatus-2027 pbxstatus
chmod +x pbxstatus

 mysql -u root -e "ALTER USER 'root'@'localhost' IDENTIFIED BY 'passw0rd';"
 sed -i 's|mysqld|mariadbd|' /usr/local/sbin/pbxstatus
 systemctl restart apache2
 systemctl restart mysqld
 sed -i 's|Bullseye|Bookworm|' /usr/local/sbin/pbxstatus
# sed -i 's|lastupdateDEB|lastupdate2020|' /root/update-IncrediblePBX



systemctl enable sendmail
systemctl start sendmail

### Install knockd ###


sed -i 's|START_KNOCKD=0|START_KNOCKD=1|' /etc/default/knockd
test=`ifconfig | grep eth0`
if [ -z "$test" ]; then
 test2=`ifconfig | grep wlan0`
 if [ -z "$test2" ]; then
  devport=`ifconfig | head -n 1 | cut -f 1 -d ":"`
  echo "KNOCKD_OPTS=\"-i $devport\"" >> /etc/default/knockd
 else
  echo 'KNOCKD_OPTS="-i wlan0"' >> /etc/default/knockd
 fi
fi

echo "[options]" > /etc/knockd.conf
echo "       logfile = /var/log/knockd.log" >> /etc/knockd.conf
echo "" >> /etc/knockd.conf
echo "[opencloseALL]" >> /etc/knockd.conf
echo "        sequence      = 7:udp,8:udp,9:udp" >> /etc/knockd.conf
echo "        seq_timeout   = 15" >> /etc/knockd.conf
echo "        tcpflags      = syn" >> /etc/knockd.conf
echo "        start_command = /usr/sbin/iptables -I INPUT -s %IP% -j ACCEPT" >> /etc/knockd.conf
echo "        cmd_timeout   = 3600" >> /etc/knockd.conf
echo "        stop_command  = /usr/sbin/iptables -D INPUT -s %IP% -j ACCEPT" >> /etc/knockd.conf
chmod 640 /etc/knockd.conf
# randomize ports here
lowest=6001
highest=9950
knock1=$[ ( $RANDOM % ( $[ $highest - $lowest ] + 1 ) ) + $lowest ]
knock2=$[ ( $RANDOM % ( $[ $highest - $lowest ] + 1 ) ) + $lowest ]
knock3=$[ ( $RANDOM % ( $[ $highest - $lowest ] + 1 ) ) + $lowest ]
sed -i 's|7:udp|'$knock1':tcp|' /etc/knockd.conf
sed -i 's|8:udp|'$knock2':tcp|' /etc/knockd.conf
sed -i 's|9:udp|'$knock3':tcp|' /etc/knockd.conf
systemctl restart knockd
systemctl enable knockd
echo " "
echo "Knock ports for access to $publicip set to TCP: $knock1 $knock2 $knock3" > /root/knock.FAQ
echo "UPnP activation attempted for UDP 5060 and your knock ports above." >> /root/knock.FAQ
echo "To enable knockd on your server, issue the following commands:" >> /root/knock.FAQ
echo "  chkconfig --level 2345 knockd on" >> /root/knock.FAQ
echo "  service knockd start" >> /root/knock.FAQ
echo "To enable remote access, issue these commands after yum -y install nmap:" >> /root/knock.FAQ
echo "nmap -p $knock1 --max-retries 0 $publicip && nmap -p $knock2 --max-retries 0 $publicip && nmap -p $knock3 --max-retries 0 $publicip" >> /root/knock.FAQ
echo "Or install iOS PortKnock or Android DroidKnocker on remote device." >> /root/knock.FAQ

echo "#!/bin/sh -e
service knockd start
sleep 5
/usr/local/sbin/iptables-restart
sleep 30
fwconsole restart
exit 0
" > /etc/rc.local
chattr +i /etc/rc.local

sed -i 's|; max_input_vars = 1000|max_input_vars = 5000|' /etc/php/8.2/apache2/php.ini
# systemctl restart apache2.service

rm -f /root/ucp-*
rm -f /root/switch-to-php*
rm -f /root/*.deb
rm -f /root/*.rpm

# gTTS update
apt-get update

pip install --upgrade pip
pip3 install --upgrade pip
ln -s /usr/bin/pip3 /usr/bin/pip
pip install gTTS
cd /var/lib/asterisk/agi-bin
wget http://incrediblepbx.com/today3.tar.gz
tar zxvf today3.tar.gz
rm -f today3.tar.gz
/var/lib/asterisk/agi-bin/nv-today.php
chown asterisk:asterisk /tmp/today.*
echo "08 01 * * * asterisk /var/lib/asterisk/agi-bin/nv-today.php" >> /etc/crontab
echo "*/10 5-22 * * * root /root/ipchecker > /dev/null 2>&1" >> /etc/crontab
crontab /etc/crontab

sed -i 's|127.0.0.1|127.0.0.1\tnoreply.incrediblepbx.com|' /etc/hosts
echo 'noreply.incrediblepbx.com' > /etc/hostname
hostname noreply.incrediblepbx.com

## Install Faxing Prep ##
apt-get update

sed -i '/^\[custom-fax/,/^$/d' /etc/asterisk/extensions_custom.conf
echo '
[ext-group](+)
exten => fax,1,Noop(Fax detected)
exten -> fax,2,Goto(custom-fax-iaxmodem,s,1)

[custom-fax-iaxmodem]
exten => s,1,Answer
exten => s,n,Wait(1)
exten => s,n,Verbose(3,Incoming Fax)
exten => s,n,Set(FAXEMAIL=)     ; fax email address of recipient
exten => s,n,Set(FAXDEST=/tmp)  ; folder where faxes will be stored
exten => s,n,Set(tempfax=${STRFTIME(,,%C%y%m%d%H%M)})
exten => s,n,ReceiveFax(${FAXDEST}/${tempfax}.tif)
exten => s,n,System(/usr/bin/tiff2pdf -o "${FAXDEST}/${tempfax}.pdf" "${FAXDEST}/${tempfax}.tif")
exten => s,n,System(/usr/bin/echo "Incoming fax is attached." | /usr/bin/mail -s "Incoming FAX  Received" -A "${FAXDEST}/${tempfax}.pdf" "${FAXEMAIL}")
exten => s,n,Hangup

' >> /etc/asterisk/extensions_custom.conf

###  Add the update checker program  ###

cd /root
wget https://filedn.com/lBgbGypMOdDm8PWOoOiBR7j/Debian12/root-folder-update.tar.gz
tar zxvf root-folder-update.tar.gz
rm -f root-folder-update.tar.gz

### Get rid of Sendmail and Add Postfix ###

cd /root 
wget https://filedn.com/lBgbGypMOdDm8PWOoOiBR7j/Debian12/enable-gmail-smarthost-with-postfix
rm -f enable-gmail-smarthost-for-sendmail
chmod +x enable-gmail-smarthost-with-postfix

/usr/local/sbin/iptables-custom
chattr -i /etc/rc.local
chmod +x /etc/rc.local
chattr +i /etc/rc.local

### Set up log rotation for Asterisk log files ###
touch /etc/logrotate.d/asterisk
echo "/var/log/asterisk/queue_log {
su asterisk asterisk
daily
missingok
rotate 30
notifempty
sharedscripts
create 0640 asterisk asterisk
}

/var/log/asterisk/freepbx_dbug{
su asterisk asterisk
size 500M
missingok
rotate 7
notifempty
sharedscripts
create 0640 asterisk asterisk
}

/var/log/asterisk/prosody_debug.log
/var/log/asterisk/prosody.log
/var/log/asterisk/ucp_err.log
/var/log/asterisk/ucp_forever.log
/var/log/asterisk/ucp_out.log
/var/log/asterisk/freepbx_debug
/var/log/asterisk/freepbx.log
/var/log/asterisk/freepbx_security.log {
su asterisk asterisk
size 100M
missingok
rotate 7
notifempty
sharedscripts
create 0640 asterisk asterisk
}

/var/spool/mail/asterisk
/var/log/asterisk/messages
/var/log/asterisk/event_log
/var/log/asterisk/full
/var/log/asterisk/dtmf
/var/log/asterisk/fail2ban {
su asterisk asterisk
daily
missingok
rotate 7
notifempty
sharedscripts
create 0640 asterisk asterisk
postrotate
/usr/sbin/asterisk -rx ‘logger reload’ > /dev/null 2> /dev/null
endscript
}
" > /etc/logrotate.d/asterisk


/root/admin-pw-change

mysql -u root -ppassw0rd asterisk -e 'update freepbx_settings set value = 1 where keyword = "USERESMWIBLF"'
mysql -u root -ppassw0rd asterisk -e 'update freepbx_settings set value = "Incredible PBX 2026" where keyword = "DASHBOARD_FREEPBX_BRAND"'
echo "2025" > /etc/pbx/.version
fwconsole reload



sed -i "s|deb http|deb [trusted=yes] http|" /etc/apt/sources.list

cd /
wget http://incrediblepbx.com/ipbx2024.tar.gz
tar zxvf ipbx2024.tar.gz
wget https://filedn.com/lBgbGypMOdDm8PWOoOiBR7j/Debian12/iPBX-custom.tar.gz
tar zxvf iPBX-custom.tar.gz
sed -i 's|bookworm|trixie|' /etc/apt/sources.list
apt-get update
fwconsole reload

# new bug fixes for Debian 13
sed -i 's|www-data|asterisk|' /etc/php/8.2/fpm/pool.d/www.conf
systemctl restart php8.2-fpm.service
fwconsole reload --verbose
sed -i 's|2025|2026|' /etc/pbx/.version
sed -i 's|SendMail| Postfix|' /usr/local/sbin/pbxstatus
chmod 755 /var/lib/asterisk/keys/stir_shaken
rm -rf /etc/asterisk/integration
mkdir -p /etc/asterisk/keys/integration
chown -R asterisk:asterisk /etc/asterisk/keys
chmod -R 775 /etc/asterisk/keys
apt-get update

systemctl start redis-server
systemctl enable redis-server
systemctl start redis.service
systemctl enable redis.service
cd /
chattr -i /etc/rc.local
wget https://filedn.com/lBgbGypMOdDm8PWOoOiBR7j/IncrediblePBX2026/PKCS-Debian13.tar.gz
tar zxvf PKCS-Debian13.tar.gz
rm -f PKCS-Debian13.tar.gz
chattr +i /etc/rc.local
systemctl restart apache2
fwconsole ma refreshsignatures
systemctl daemon-reload
sed -i 's|128M|256M|' /etc/php/8.2/fpm/php.ini
systemctl restart php8.2-fpm.service
systemctl enable php8.2-fpm.service
mysql -u root -ppassw0rd asterisk -e "DELETE FROM modules WHERE modulename = 'restart';"
mysql -u root -ppassw0rd asterisk -e "DELETE FROM module_xml WHERE id = 'restart';"
fwconsole chown
fwconsole reload
fwconsole certificates --delete 1
fwconsole certificates --delete 0
cd /root
wget https://filedn.com/lBgbGypMOdDm8PWOoOiBR7j/IncrediblePBX2026/upgrade-asterisk
chmod +x upgrade-asterisk

echo "upgrade-asterisk script added for easy Asterisk 23 upgrade, if desired."
read -p "Press Enter to reboot or Ctrl-C to exit..."
/usr/local/sbin/reboot
