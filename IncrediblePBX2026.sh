#!/bin/bash
# IncrediblePBX Installer - Copyright (C) 2026, Tom Ray / Blaze Studios, tom.ray@blazestudios.com
# This is a heavy rewrite of the original IncrediblePBX installer. Many portions have been removed/replaced.
# All previous copyrights intact.

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

clear
MyPick=22
astVersion=22
fpbxVersion=17
temp=true
while $temp; do
   # Prompt the user for input
   read -p "Asterisk 22 LTS is installed by default. Would you prefer Asterisk 23? (y/n): " choice

        # Handle the response using a case statement
        case "$choice" in
            [Yy]* )
                temp=false
		        astVersion=23
                ;;
            [Nn]* )
                temp=false
		        astVersion=22
                ;;
            * )
                echo "Invalid input. Please enter 'y' for yes or 'n' for no."
                ;;
        esac
done
clear

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

install_build_tools
install_asterisk_dependencies
install_media_packages
install_web_stack
install_php_stack
install_security_tools
install_pbx_utilities
install_python
install_database_utilities
install_messaging_packages
install_utility_packages
install_apache_extras 
install_media_packages
install_nodejs_packages

install_webmin_packages
install_vpn_packages







systemctl restart apache2


### Set up VIM for root user ###
echo "
set hlsearch
set mouse=r" > /root/.vimrc

cd /usr/src

# Install Asterisk 
install_setup_asterisk

install -m 644 files/odbc/odbcinst.ini /etc/odbcinst.ini
install -m 644 files/odbc/odbc.ini /etc/odbc.ini


systemctl restart asterisk

setup_apache
# Install and setup FreePBX
install_setup_freepbx

mysql -u root -e "ALTER USER 'root'@'localhost' IDENTIFIED VIA unix_socket;"
mysql -u root -e "FLUSH PRIVILEGES;"

install -m 644 files/apache/httpdconf/incrediblepbx.conf /etc/apache2/conf-available/incrediblepbx.conf
echo "
<Directory /var/www/html/admin/licenses>
	Options Indexes FollowSymLinks
	AllowOverride All
	Require all granted
</Directory>
" >> /etc/apache2/apache2.conf
systemctl restart apache2


rm /tmp/*

# Setup Firewall - iptables
setup_firewall


#IPtables Setup
cd /root
echo iptables-persistent iptables-persistent/autosave_v4 boolean true | debconf-set-selections
echo iptables-persistent iptables-persistent/autosave_v6 boolean true | debconf-set-selections


# Local server IP (outbound interface)
serverip=$(ip route get 1.1.1.1 | awk '{for(i=1;i<=NF;i++) if ($i=="src") {print $(i+1); exit}}')
# SSH client IP
userip=${SSH_CLIENT%% *}
# Public IP (fallback chain)
publicip=$(
  curl -4 -s https://api.ipify.org ||
  curl -4 -s https://ifconfig.me ||
  curl -4 -s https://checkip.amazonaws.com
)
ipset add trusted_hosts "$serverip" -exist
ipset add trusted_hosts "$userip" -exist
ipset add trusted_hosts "$publicip" -exist
# WhiteList all of them by replacing 8.8.4.4 and 8.8.8.8 and 74.86.213.25 entries
cp /etc/iptables/rules.v4 /etc/iptables/rules.v4.orig
cd /etc/iptables
cp /etc/iptables/rules.v4 /etc/iptables/rules.v4.orig


mv openssl.cnf /etc/ssl
cp rules.v4.tm4 rules.v4


badline=`grep -n "\-s  \-p" /etc/iptables/rules.v4 | cut -f1 -d: | tail -1`
while [[ "$badline" != "" ]]; do
sed -i "${badline}d" /etc/iptables/rules.v4
badline=`grep -n "\-s  \-p" /etc/iptables/rules.v4 | cut -f1 -d: | tail -1`
done
sed -i 's|-A INPUT -s  -j|#-A INPUT -s  -j|g' /etc/iptables/rules.v4

/usr/local/sbin/iptables-custom
systemctl restart iptables
/usr/local/sbin/iptables-custom








systemctl enable fail2ban
systemctl start fail2ban





# CentOS-like color scheme for ls
echo "export LS_OPTIONS='--color=auto'
eval \"\`dircolors\`\"
alias ls='ls \$LS_OPTIONS'
alias ll='ls -l \$LS_OPTIONS'" >> /etc/bash.bashrc




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

mysql -u root asterisk -e 'UPDATE freepbx_settings SET `value` = "Latest-17" WHERE `keyword` = "MIRROR_BRAND_VERSION" LIMIT 1'

systemctl restart mysqld
fwconsole chown
fwconsole reload
fwconsole restart




# Watson STT fix
sed -i 's|/usr/local/sbin/we-dont-have-tech-support.wav|/var/lib/asterisk/sounds/en/we-dont-have-tech-support.gsm|' /usr/local/sbin/watson-test
clear

# pbxstatus history fix
sed -i 's|clear|clear -x|' /usr/local/sbin/pbxstatus
cd /usr/local/sbin
wget https://filedn.com/lBgbGypMOdDm8PWOoOiBR7j/IncrediblePBX2027-Debian11/pbxstatus-2027
mv pbxstatus-2027 pbxstatus
chmod +x pbxstatus

cd /var/www/html/admin
wget https://filedn.com/lBgbGypMOdDm8PWOoOiBR7j/Debian12/iPBX-licenses.tar.gz
tar zxvf iPBX-licenses.tar.gz
rm iPBX-licenses.tar.gz
 
 systemctl restart apache2
 systemctl restart mysqld
 sed -i 's|Bullseye|Bookworm|' /usr/local/sbin/pbxstatus
# sed -i 's|lastupdateDEB|lastupdate2020|' /root/update-IncrediblePBX



systemctl enable sendmail
systemctl start sendmail

### Install knockd ###






sed -i 's|; max_input_vars = 1000|max_input_vars = 5000|' /etc/php/8.2/apache2/php.ini
# systemctl restart apache2.service

rm -f /root/ucp-*
rm -f /root/switch-to-php*
rm -f /root/*.deb
rm -f /root/*.rpm

# gTTS update
apt-get update
install_gtts

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


HOSTNAME="noreply.incrediblepbx.com"

hostnamectl set-hostname "$HOSTNAME"

if grep -q '^127\.0\.1\.1' /etc/hosts; then
    sed -i "s/^127\.0\.1\.1.*/127.0.1.1\t$HOSTNAME ${HOSTNAME%%.*}/" /etc/hosts
else
    echo -e "127.0.1.1\t$HOSTNAME ${HOSTNAME%%.*}" >> /etc/hosts
fi

sed -i '/^\[custom-fax/,/^$/d' /etc/asterisk/extensions_custom.conf


###  Add the update checker program  ###



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








/root/admin-pw-change




apt-get update
fwconsole reload

# new bug fixes for Debian 13

fwconsole reload --verbose






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

mysql -u root asterisk -e "DELETE FROM modules WHERE modulename = 'restart';"
mysql -u root asterisk -e "DELETE FROM module_xml WHERE id = 'restart';"
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


install_packages() {
    apt-get install -y "$@"
}

remove_packages() {
    apt-get purge -y "$@"
}

enable_services() {
    systemctl enable "$@"
}

restart_services() {
    for svc in "$@"; do
        systemctl restart "$svc"
    done
}

install_base_packages() {
    log "Installing base packages"
    
    install_packages \
        sudo \
        curl \
        wget \
        ca-certificates \
        gnupg \
        lsb-release
}

install_build_tools() {
    log "Installing build tools"

    install_packages \
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
}

install_asterisk_dependencies() {
    log "Installing Asterisk dependencies"

    install_packages \
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
        odbc-mariadb
}

install_asterisk_build_packages() {
    install_packages \
        libnewt-dev \
        libncurses5-dev \
        libncurses-dev \
        libxml2-dev \
        default-libmysqlclient-dev \
        libedit-dev \
        unixodbc
}

install_media_packages() {
    log "Installing media packages"

    install_packages \
        ffmpeg \
        lame \
        mpg123 \
        sox \
        libasound2-dev \
        libogg-dev \
        libvorbis-dev
}

install_web_stack() {
    log "Installing Apache and MariaDB"

    install_packages \
        apache2 \
        mariadb-server \
        mariadb-client \
        openssh-server
}
install_php_stack() {
    log "Installing PHP"
    remove_packages php8.1 php8.3
    rm -rf /etc/php/8.1 /etc/php/8.3

    install_packages \
        php8.2 \
        php8.2-cli \
        php8.2-common \
        php8.2-fpm \
        php8.2-curl \
        php8.2-mysql \
        php8.2-gd \
        php8.2-mbstring \
        php8.2-intl \
        php8.2-xml \
        php8.2-zip \
        php8.2-soap \
        php8.2-bcmath \
        php8.2-opcache \
        php8.2-imagick \
        php8.2-redis \
        php8.2-memcached \
        php-pear
    
    install -m 644 files/php/php-fpm/www.conf /etc/php/8.2/fpm/pool.d/www.conf
    install -m 644 files/php/php-fpm/override.conf /etc/systemd/system/php8.2-fpm.service.d/override.conf
    
    systemctl daemon-reload
    
    a2enmod proxy_fcgi setenvif
    a2enconf php8.2-fpm
    update-alternatives --set php /usr/bin/php8.2

    sed -i 's/^memory_limit *= *.*/memory_limit = 256M/' /etc/php/8.2/fpm/php.ini
    sed -i 's/^upload_max_filesize *= *.*/upload_max_filesize = 20M/' /etc/php/8.2/fpm/php.ini
    
    sed -i 's/^memory_limit *= *.*/memory_limit = 256M/' /etc/php/8.2/cli/php.ini
    sed -i 's/^upload_max_filesize *= *.*/upload_max_filesize = 20M/' /etc/php/8.2/cli/php.ini
    
    systemctl enable --now php8.2-fpm

    systemctl restart apache2
    
}
install_security_tools() {
    log "Installing security tools"

    install_packages \
        fail2ban \
        iptables \
        iptables-persistent \
        ipset \
        knockd \
        dnsmasq
}

install_pbx_utilities() {
    log "Installing PBX utilities"

    install_packages \
        htop \
        sngrep \
        vim \
        nano \
        expect \
        dialog \
        net-tools
}
install_python() {
    log "Installing Python"

    install_packages \
        python3 \
        python3-pip \
        pipx \
        python-dev-is-python3
}
install_vpn_packages() {
    install_packages openvpn
}
install_redis_packages() {
    install_packages \
        redis-server \
        redis-tools
}
install_database_utilities() {
    install_packages \
        sqlite3 \
        uuid
}
install_messaging_packages() {
    install_packages \
        postfix \
        mailutils
}
install_utility_packages() {
    install_packages \
        jq \
        cron 
}
install_apache_extras() {
    install_packages \
        libapache2-mod-fcgid
}
install_media_packages() {
    install_packages \
        ghostscript \
        libtiff-tools \
        libsox-fmt-all
}
install_webmin_packages() {
    install_packages webmin
    sed -i 's|10000|9001|g' /etc/webmin/miniserv.conf
    systemctl restart webmin
}
install_nodejs_packages() {
    install_packages nodejs
}



# Install Selected Asterisk Version
install_setup_asterisk() {
    cd /usr/src
    if [[ "$astVersion" == "" ]]; then
        astVersion=22
    fi
    wget "https://downloads.asterisk.org/pub/telephony/asterisk/asterisk-$astVersion-current.tar.gz"
    tar xvf "asterisk-$astVersion-current.tar.gz"
    cd "asterisk-$astVersion"*/
    
    contrib/scripts/get_mp3_source.sh
    contrib/scripts/install_prereq install

    wget http://incrediblepbx.com/menuselect-incredible2025.tar.gz
    tar zxvf menuselect-incredible*
    rm -rf menuselect-incredible*

    export CFLAGS='-DENABLE_SRTP_AES_256 -DENABLE_SRTP_AES_GCM' 
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


    sed -i 's|#AST_USER|AST_USER|' /etc/default/asterisk
    sed -i 's|#AST_GROUP|AST_GROUP|' /etc/default/asterisk
    sed -i 's|;runuser|runuser|' /etc/asterisk/asterisk.conf
    sed -i 's|;rungroup|rungroup|' /etc/asterisk/asterisk.conf
    ldconfig
    systemctl stop asterisk
    systemctl disable asterisk
    killall asterisk
    touch cdr.conf
}

install_setup_freepbx() {


    cd /usr/src/

    wget "https://mirror.freepbx.org/modules/packages/freepbx/freepbx-$fpbxVersion.0-latest.tgz"
    tar zxvf "freepbx-$fpbxVersion.0-latest.tgz"
    cd /usr/src/freepbx/
    ./start_asterisk start
    ./install -n
    fwconsole ma installall
    fwconsole ma enablerepo standard extended unsupported
    fwconsole ma downloadinstall superfecta queueprio miscdests miscapps outcnam dynroute extensionsettings disa allowlist
    fwconsole ma remove firewall synologyabb

    
fwconsole reload
fwconsole restart
install -m 644 files/systemd/freepbx.service /etc/systemd/system/freepbx.service
    
systemctl daemon-reload
systemctl enable freepbx
fwconsole setting HTTPTLSBINDADDRESS 127.0.0.1
fwconsole setting HTTPBINDADDRESS 127.0.0.1

ARI_USER=$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c 16)
ARI_PASS=$(openssl rand -base64 32)

fwconsole setting FPBX_ARI_USER "$ARI_USER"
fwconsole setting FPBX_ARI_PASSWORD "$ARI_PASS"
asterisk -rx "database put blacklist dest app-blackhole,no-service,1"
}


install_incrediblepbx() {

wget https://filedn.com/lBgbGypMOdDm8PWOoOiBR7j/Debian12/incrediblepbx-17.0.0.tgz
    #fwconsole ma install incrediblepbx

echo "Now downloading and restoring FreePBX backup of core IncrediblePBX system."
cd /tmp
wget https://filedn.com/lBgbGypMOdDm8PWOoOiBR7j/Debian12/20240725-153553-1721936153-17.0.17.1-791763876.tar.gz
fwconsole backup --restore /tmp/20240725-153553-1721936153-17.0.17.1-791763876.tar.gz
rm 20240725-153553-1721936153-17.0.17.1-791763876.tar.gz

mysql -u root -ppassw0rd asterisk -e "update freepbx_settings SET value = '1' where keyword='CDR_BATCH_ENABLE';"
mysql -u root -ppassw0rd asterisk -e "update admin SET value = 'true' where variable='need_reload';"

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


mysql -u root asterisk -e 'update freepbx_settings set value = "Incredible PBX 2026" where keyword = "DASHBOARD_FREEPBX_BRAND"'
echo "2025" > /etc/pbx/.version
fwconsole reload
cd /
wget http://incrediblepbx.com/ipbx2024.tar.gz
tar zxvf ipbx2024.tar.gz
wget https://filedn.com/lBgbGypMOdDm8PWOoOiBR7j/Debian12/iPBX-custom.tar.gz
tar zxvf iPBX-custom.tar.gz
sed -i 's|2025|2026|' /etc/pbx/.version
}
setup_apache()
{
    sed -i 's/^\(User\|Group\).*/\1 asterisk/' /etc/apache2/apache2.conf
    sed -i 's/AllowOverride None/AllowOverride All/' /etc/apache2/apache2.conf
    a2enmod rewrite
    systemctl restart apache2
    rm /var/www/html/index.html
}

install_gTTS() {
echo "Installing gTTS..."
    export PIPX_HOME=/opt/pipx
    export PIPX_BIN_DIR=/usr/local/bin

    if ! pipx install gTTS; then
        echo "ERROR: Failed to install gTTS via pipx" >&2
        exit 1
    fi

    if ! pipx list | grep -q gTTS; then
        echo "ERROR: gTTS installation verification failed" >&2
        exit 1
    fi

echo "gTTS installed successfully — gtts-cli available at /usr/local/bin/gtts-cli"

}


setup_rootfiles() {
cd /
wget http://incrediblepbx.com/rootfiles-debian10.tar.gz
tar zxvf rootfiles-debian10.tar.gz
rm rootfiles-debian10.tar.gz
chattr -i /root/up*

cd /root
wget https://filedn.com/lBgbGypMOdDm8PWOoOiBR7j/Debian12/root-folder-update.tar.gz
tar zxvf root-folder-update.tar.gz
rm -f root-folder-update.tar.gz
}

setup_dnsmasq() {
    systemctl disable --now systemd-resolved
    systemctl mask systemd-resolved
    rm -f /etc/resolv.conf
    echo "nameserver 127.0.0.1" > /etc/resolv.conf
    install -m 644 files/dnsmasq/00-dns.conf /etc/dnsmasq.d/00-dns.conf 
    systemctl enable dnsmasq
    systemctl restart dnsmasq
}

setup_knockd() {
    CONF="/etc/default/knockd"

    # Enable knockd
    sed -i 's/^START_KNOCKD=0/START_KNOCKD=1/' "$CONF"

    # Get first non-loopback interface that is UP
    devport=$(ip -o link show up | awk -F': ' '{print $2}' | grep -v lo | head -n 1)

    # Fallback safety
    if [ -z "$devport" ]; then
        echo "No active interface found, defaulting to eth0"
        devport="eth0"
    fi

    # Remove existing KNOCKD_OPTS line (avoid duplicates)
    sed -i '/^KNOCKD_OPTS=/d' "$CONF"

    # Add new config
    echo "KNOCKD_OPTS=\"-i $devport\"" >> "$CONF"

    install -m 640 files/knockd/knockd.conf /etc/knockd.conf
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
}

setup_firewall() {
    echo iptables-persistent iptables-persistent/autosave_v4 boolean true | debconf-set-selections
    echo iptables-persistent iptables-persistent/autosave_v6 boolean true | debconf-set-selections
    ipset create trusted_dyndns hash:ip timeout 3600
    ipset create restriced_dyndns hash:ip timeout 3600
    ipset create trusted_hosts hash:ip -exist
    ipset create restricted_hosts hash:ip -exist
    ipset create trusted_providers hash:ip -exist

    systemctl enable ipset-restore
    
}

setup_fail2ban() {
    install -m 644 files/fail2ban/fail2ban.local /etc/fail2ban/jail.d/fail2ban.local
    install -m 644 files/fail2ban/defaults.local /etc/fail2ban/jail.d/defaults.local
    install -m 644 files/fail2ban/sshd.local /etc/fail2ban/jail.d/sshd.local
    install -m 644 files/fail2ban/asterisk.local /etc/fail2ban/jail.d/asterisk.local
}

setup_openvpn() {
    install -m 644 files/systemd/openvpn2027.service /etc/systemd/system/openvpn2027.service
    cp -p /root/openvpn-start /etc/openvpn-start
    systemctl enable openvpn2027.service
    systemctl restart openvpn2027.service
}

post_install_asterisk() {
    chmod 755 /var/lib/asterisk/keys/stir_shaken
    rm -rf /etc/asterisk/integration
    mkdir -p /etc/asterisk/keys/integration
    hown -R asterisk:asterisk /etc/asterisk/keys
    chmod -R 775 /etc/asterisk/keys
}





configure_smarthost() {
    . /usr/local/lib/postfix-sasl.sh
    local smtphost smtpport smtpuser provider

    echo "Configure a smarthost for outbound mail? [y/N]"
    read -r use_smarthost
    [[ "${use_smarthost,,}" != "y" ]] && return 0

    echo "Select provider:"
    echo "  1) Gmail (smtp.gmail.com:587)"
    echo "  2) Custom"
    read -r provider

    case "$provider" in
        1)
            smtphost="smtp.gmail.com"
            smtpport="587"
            ;;
        2)
            while true; do
                echo "Host:"
                read -r smtphost
                _validate_host "$smtphost" && break
            done

            while true; do
                echo "Port [587]:"
                read -r smtpport
                smtpport="${smtpport:-587}"
                _validate_port "$smtpport" && break
            done
            ;;
        *)
            echo "Invalid selection." >&2
            return 1
            ;;
    esac

    while true; do
        echo "Username:"
        read -r smtpuser
        _validate_user "$smtpuser" && break
    done

    sasl_add "$smtphost" "$smtpuser" "$smtpport"
}

configure_smarthost