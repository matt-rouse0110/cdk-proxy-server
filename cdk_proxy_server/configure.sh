#!/bin/sh
sudo useradd matthewr
sudo mkdir /home/matthewr/.ssh
sudo echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC/gzZ9sBHB/xdMd7cAfUkwE7PaMPBqfIxMXGSHqnQGQrJCM+WLA1R5fWyKu2EhiA7DF3iqB2FwtBWZ2/dU8PlwhvpC8iAluPfFSiSD4sEserW8UQUlR2JqMfFAMHoGamag6I4ZKq62AkPaOzlLuz1wXi88Ced6iqzTJbTOEC22YdGqMW5r4VISr0e+GLSJOUm5WUX5RkCtCaHet4d7jfq0uJJzOpLO91pyk+eF2ZGbqvpmAoK8ht17iCeLHHNVkffKvnGDLiXjmdrR2Z/yVx2A6OeZQSlqgDIOYDplptkY3HPYZ25eSfw142wqDAcBAAn27+K6rZgpJxclZmBXLgrZ" >> /home/matthewr/.ssh/authorized_keys
sudo chmod 700 /home/matthewr/.ssh
sudo chown matthewr /home/matthewr/.ssh
sudo chmod 600 /home/matthewr/.ssh/authorized_keys
sudo chown matthewr /home/matthewr/.ssh/authorized_keys
sudo usermod -aG wheel matthewr
sudo yum install -y openvpn
sudo modprobe iptable_nat
echo 1 | sudo tee /proc/sys/net/ipv4/ip_forward
sudo iptables -t nat -A POSTROUTING -s 10.4.0.1/2 -o eth0 -j MASQUERADE
sudo iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE
sudo yum install easy-rsa -y --enablerepo=epel
sudo mkdir /etc/openvpn/easy-rsa
sudo cp -Rv /usr/share/easy-rsa/3.0.8/* /etc/openvpn/easy-rsa/
sudo /etc/openvpn/easy-rsa/easyrsa --pki-dir=/etc/openvpn/easy-rsa/pki/ init-pki
sudo /etc/openvpn/easy-rsa/easyrsa --pki-dir=/etc/openvpn/easy-rsa/pki/ --batch build-ca nopass
sudo /etc/openvpn/easy-rsa/easyrsa --pki-dir=/etc/openvpn/easy-rsa/pki/ --batch gen-dh
sudo /etc/openvpn/easy-rsa/easyrsa --pki-dir=/etc/openvpn/easy-rsa/pki/ --batch gen-req server nopass
sudo /etc/openvpn/easy-rsa/easyrsa --pki-dir=/etc/openvpn/easy-rsa/pki/ --batch sign-req server server
sudo /etc/openvpn/easy-rsa/easyrsa --pki-dir=/etc/openvpn/easy-rsa/pki/ --batch gen-req client nopass
sudo /etc/openvpn/easy-rsa/easyrsa --pki-dir=/etc/openvpn/easy-rsa/pki/ --batch sign-req client client
sudo openvpn --genkey --secret /etc/openvpn/pfs.key
echo -e 'port 1194\nproto udp\ndev tun\nca /etc/openvpn/easy-rsa/pki/ca.crt\ncert /etc/openvpn/easy-rsa/pki/issued/server.crt\nkey /etc/openvpn/easy-rsa/pki/private/server.key\ndh /etc/openvpn/easy-rsa/pki/dh.pem\ncipher AES-256-CBC\nauth SHA512\nserver 10.8.0.0 255.255.255.0\npush "redirect-gateway def1 bypass-dhcp"\npush "dhcp-option DNS 8.8.8.8"\npush "dhcp-option DNS 8.8.4.4"\nifconfig-pool-persist ipp.txt\nkeepalive 10 120\ncomp-lzo\npersist-key\npersist-tun\nstatus openvpn-status.log\nlog-append openvpn.log\nverb 3\ntls-server\ntls-auth /etc/openvpn/pfs.key' >> /etc/openvpn/server.conf
sudo service openvpn start
sudo aws s3 cp /etc/openvpn/pfs.key s3://cdk-server-keys/keys/
sudo aws s3 cp /etc/openvpn/easy-rsa/pki/dh.pem s3://cdk-server-keys/keys/
sudo aws s3 cp /etc/openvpn/easy-rsa/pki/ca.crt s3://cdk-server-keys/keys/
sudo aws s3 cp /etc/openvpn/easy-rsa/pki/private/ca.key s3://cdk-server-keys/keys/
sudo aws s3 cp /etc/openvpn/easy-rsa/pki/private/client.key s3://cdk-server-keys/keys/
sudo aws s3 cp /etc/openvpn/easy-rsa/pki/issued/client.crt s3://cdk-server-keys/keys/
sudo echo "%wheel ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers