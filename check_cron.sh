cat > /home/$(whoami)/check_cron.sh << 'EOF' 
#!/bin/bash 
# 端口号 
export PORT=${PORT:-'5678'}
# 检查端口是否在监听
if sockstat -l | grep -q ":$PORT"; then
echo "Port $PORT is already in use. No action needed." 
else 
echo "Port $PORT is not in use. Starting Hysteria2..." 
PORT=$PORT bash <(curl -s https://raw.githubusercontent.com/jackbrownsu/s9-qisu11-20/main/check_cron.sh) 
fi 
EOF
