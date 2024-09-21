cat > /home/$(whoami)/checktu.sh << 'EOF' 
#!/bin/bash 
# 端口号 
export PORT=${PORT:-'5678'}
# 检查端口是否在监听
if sockstat -l | grep -q ":$PORT"; then
echo "Port $PORT is already in use. No action needed." 
else 
echo "Port $PORT is not in use. Starting TUIC..." 
PORT=$PORT bash <(curl -Ls https://raw.githubusercontent.com/jackssu/danxieyi-hy2-tuic/main/tu.sh)
fi 
EOF
