cat > /home/$(whoami)/checkvmess0.sh << 'EOF'
#!/bin/bash
# 端口号
export PORT=${PORT:-'5678'}
# 检查端口是否在监听
PORT_IN_USE=$(sockstat -l | grep -q ":$PORT"; echo $?)
# 检查Argo进程是否在运行（通过检查 COMMAND 列是否包含 tunnel）
Argo_RUNNING=$(ps aux | grep "[t]unnel" ; echo $?)
# 如果端口不在使用或Argo不在运行，则执行安装脚本
if [ $PORT_IN_USE -ne 0 ] || [ $Argo_RUNNING -ne 0 ]; then
echo "Port $PORT is not in use or Argo is not running. Starting Vmess..."
# 设置TCP端口、ARGO_AUTH、ARGO_DOMAIN并启动老王Vmess脚本
PORT=$PORT ARGO_DOMAIN=xxxx.su66.us.kg ARGO_AUTH='{"AccountTag":"8d945af823269e01b43332a209955402","TunnelSecret":"zAKRuJ3y6l/41jWQ9BruzpzRyQTsTl7MXR9MYmJvOZg=","TunnelID":"3270a406-0696-4a42-b361-41a5ea998669"}' bash <(curl -Ls https://raw.githubusercontent.com/jackssu/danxieyi-hy2-tuic/main/vmess.sh)
else
echo "Port $PORT is in use and Argo is already running. No action needed."
fi
EOF
