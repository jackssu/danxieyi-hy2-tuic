cat > /home/$(whoami)/checkvmess.sh << 'EOF' 
#!/bin/bash 
# 端口号 
export PORT=${PORT:-'5678'}
# 检查端口是否在监听
if sockstat -l | grep -q ":$PORT"; then
echo "Port $PORT is already in use. No action needed." 
else 
echo "Port $PORT is not in use. Starting VEMSS..." 
PORT=$PORT ARGO_DOMAIN=argo.xxxx.us.kg ARGO_AUTH='{"AccountTag":"8d945af823269e01b45555a209955402","TunnelSecret":"JIbgnIcbf2Zwfw816B1+tdb+Ithln0WirbpdvlONXS0=","TunnelID":"e196e042-4fd4-4886-b254-12d1b4e226ec"}' bash <(curl -Ls https://raw.githubusercontent.com/jackssu/danxieyi-hy2-tuic/main/vmess.sh) 
fi 
EOF
