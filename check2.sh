cat > /home/$(whoami)/check2.sh << 'EOF' 
#!/bin/bash 
# 端口号 
export PORT=${PORT:-'5678'}
# 检查端口是否在监听
if sockstat -l | grep -q ":$PORT"; then
echo "Port $PORT is already in use. No action needed." 
else 
echo "Port $PORT is not in use. Starting Hysteria2..." 
PORT=$PORT bash <(curl -Ls https://raw.githubusercontent.com/jackssu/danxieyi-hy2-tuic/main/2.sh) 
fi 
EOF
