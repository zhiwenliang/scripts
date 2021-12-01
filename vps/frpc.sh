apt update
apt install -y iptables iptables-persistent
curl -LO https://github.com/fatedier/frp/releases/download/v0.38.0/frp_0.38.0_linux_amd64.tar.gz
tar -xvf frp_0.38.0_linux_amd64.tar.gz
iptables -I INPUT -p tcp --dport 6000 -j ACCEPT &&
iptables -I INPUT -p tcp --dport 7000 -j ACCEPT &&
iptables-save &&
netfilter-persistent save &&
netfilter-persistent reload && 
nohup ./frpc -c ./frpc.ini &