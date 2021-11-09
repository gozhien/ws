#!/bin/bash
country=ID
state=Bandung
locality=JawaBarat
organization=fas
organizationalunit=fas
commonname=faried
email=admin@fas.com

cd

# set time GMT +7 jakarta
ln -fs /usr/share/zoneinfo/Asia/Jakarta /etc/localtime

apt update

wget -P /usr/bin https://raw.githubusercontent.com/gozhien/ws/main/new && chmod +x /usr/bin/new
wget -P /usr/bin https://raw.githubusercontent.com/gozhien/ws/main/list && chmod +x /usr/bin/list
wget -P /usr/bin https://raw.githubusercontent.com/gozhien/ws/main/trial && chmod +x /usr/bin/trial
wget -P /usr/bin https://raw.githubusercontent.com/gozhien/ws/main/hapus && chmod +x /usr/bin/hapus
wget -P /usr/bin https://raw.githubusercontent.com/gozhien/ws/main/cek && chmod +x /usr/bin/cek

echo "=============== INSTALL STUNNEL4 ==============="
apt-get install stunnel4 -y
rm /etc/stunnel/stunnel.conf
cat > /etc/stunnel/stunnel.conf <<-END
pid = /var/run/stunnel.pid
cert = /etc/stunnel/stunnel.pem
client = no
socket = a:SO_REUSEADDR=1
socket = l:TCP_NODELAY=1
socket = r:TCP_NODELAY=1
foreground = yes
[https]
accept = :::443
connect = 127.0.0.1:9999

END

echo "=============== INSTALL SERTIFIKAT ==============="
rm /etc/stunnel/stunnel.pem
openssl genrsa -out key.pem 2048
openssl req -new -x509 -key key.pem -out cert.pem -days 1095 \
	-subj "/C=$country/ST=$state/L=$locality/O=$organization/OU=$organizationalunit/CN=$commonname/emailAddress=$email"
cat key.pem cert.pem >> /etc/stunnel/stunnel.pem

echo "=============== INSTALL DROPBEAR ==============="
apt-get install dropbear -y
rm /etc/default/dropbear
cat > /etc/default/dropbear <<-END
# disabled because OpenSSH is installed
# change to NO_START=0 to enable Dropbear
NO_START=0
# the TCP port that Dropbear listens on
DROPBEAR_PORT=2222

# any additional arguments for Dropbear
DROPBEAR_EXTRA_ARGS=

# specify an optional banner file containing a message to be
# sent to clients before they connect, such as "/etc/issue.net"
DROPBEAR_BANNER="/root/fas.net"

# RSA hostkey file (default: /etc/dropbear/dropbear_rsa_host_key)
#DROPBEAR_RSAKEY="/etc/dropbear/dropbear_rsa_host_key"

# DSS hostkey file (default: /etc/dropbear/dropbear_dss_host_key)
#DROPBEAR_DSSKEY="/etc/dropbear/dropbear_dss_host_key"

# ECDSA hostkey file (default: /etc/dropbear/dropbear_ecdsa_host_key)
#DROPBEAR_ECDSAKEY="/etc/dropbear/dropbear_ecdsa_host_key"

# Receive window size - this is a tradeoff between memory and
# network performance
DROPBEAR_RECEIVE_WINDOW=65536
END
echo "/bin/false" >> /etc/shells
echo "/usr/sbin/nologin" >> /etc/shells
wget https://raw.githubusercontent.com/gozhien/ws/main/fas.net

echo "=============== SETTING AUTO ==============="
echo "5 * * * *  sync; echo 3 > /proc/sys/vm/drop_caches" >> /etc/cron.d/cache
echo "0 0 * * * /sbin/shutdown -r now" >> /etc/cron.d/reboot
echo " " >> /etc/rc.local
echo "runuser -l root -c 'screen -dmS pydong python pd.py'" >> /etc/rc.local

echo "=============== INSTALL BADVPN ==============="
apt -y install unzip && apt -y install cmake && apt -y install make && apt -y install screen
wget https://github.com/ambrop72/badvpn/archive/master.zip && unzip master.zip && cd badvpn-master && mkdir build && cd build && cmake .. -DBUILD_NOTHING_BY_DEFAULT=1 -DBUILD_UDPGW=1 && make install

wget -O /etc/systemd/system/badvpn.service https://gitlab.com/PANCHO7532/scripts-and-random-code/-/raw/master/nfree/badvpn.service && chmod +x /etc/systemd/system/badvpn.service
systemctl enable badvpn
systemctl start badvpn

echo "=============== INSTALL WS ==============="
apt -y install python

wget https://raw.githubusercontent.com/gozhien/ws/main/pd.py

echo "=============== MENJALANKAN SEMUA ==============="
rm -rf badvpn-master key.pem cert.pem install.sh master.zip

screen -dmS pydong python pd.py

/etc/init.d/dropbear restart

/etc/init.d/stunnel4 restart

clear
