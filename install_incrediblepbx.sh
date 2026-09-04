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

# Set the default hostname
DEFAULT_HOSTNAME="noreply.incrediblepbx.com"

# Set base installation directory
INSTALL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# set PATH
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
export PATH

# source the logger functions
source "$INSTALL_DIR"/installlibs/common-logger.sh
source "$INSTALL_DIR"/installlibs/common-lib.sh



# source all the needed install, configuration and setup functions
for f in "$INSTALL_DIR"/installlibs/{install,setup,configure}-*.sh; do
    [[ -f "$f" ]] && source "$f"
done


### Set up VIM for root user ###
cat <<'EOF' >> /root/.vimrc
set hlsearch
set mouse=r
EOF

# CentOS-like color scheme for ls
alias ls='ls --color=auto'
alias ll='ls -alF'
eval "$(dircolors -b)"

sed -i 's|rm -i|rm -f|' /root/.bashrc
sed -i 's|cp -i|cp -f|' /root/.bashrc
sed -i 's|mv -i|mv -f|' /root/.bashrc




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



check_configure_ipv6

configure_hostname


## run install packages functions
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
install_media_packages
install_webmin_packages
install_vpn_packages


# Install Asterisk 
install_setup_asterisk "$astVersion"

# install ODBC configs
install -m 644 "$INSTALL_DIR"/files/etc/odbcinst.ini /etc/odbcinst.ini
install -m 644 "$INSTALL_DIR"/files/etc/odbc.ini /etc/odbc.ini

# Setup Apache
setup_apache

setup_php

# Install and setup FreePBX
install_setup_freepbx "$astVersion"



mysql -u root -e "ALTER USER 'root'@'localhost' IDENTIFIED VIA unix_socket;"
mysql -u root -e "FLUSH PRIVILEGES;"
# Install Incredible PBX
install_incrediblepbx

# Setup dnsmasq
setup_dnsmasq

# Setup Firewall - iptables
setup_firewall
setup_fail2ban


setup_webmin
setup_knockd
setup_openvpn


if [ -e "/usr/sbin/fwconsole" ]; then
    echo " "
else
    ln -s /var/lib/asterisk/bin/fwconsole /usr/sbin/fwconsole
fi






echo "# .bash_profile
# Get the aliases and functions
if [ -f ~/.bashrc ]; then
	. ~/.bashrc
fi
# User specific environment and startup programs
PATH=$PATH:$HOME/bin
export PATH
pbxstatus -p" > /root/.bash_profile




 
#setup smarthost
configure_smarthost

/root/admin-pw-change



systemctl restart apache2

# new bug fixes for Debian 13

fwconsole reload --verbose



fwconsole chown
fwconsole reload
fwconsole certificates --delete 1
fwconsole certificates --delete 0

read -p "Press Enter to reboot or Ctrl-C to exit..."
/usr/local/sbin/reboot