#!/bin/bash
export LC_ALL=C
export UUID=${UUID:-'69e8b439-06be-4783-ad52-6357fc5e8743'} 
export NEZHA_SERVER=${NEZHA_SERVER:-''}      
export NEZHA_PORT=${NEZHA_PORT:-'5555'}             
export NEZHA_KEY=${NEZHA_KEY:-''}                
export PORT=${PORT:-'60000'} 
USERNAME=$(whoami)
HOSTNAME=$(hostname)

[[ "$HOSTNAME" == "s1.ct8.pl" ]] && WORKDIR="domains/${USERNAME}.ct8.pl/logs" || WORKDIR="domains/${USERNAME}.serv00.net/logs"
[ -d "$WORKDIR" ] || (mkdir -p "$WORKDIR" && chmod 777 "$WORKDIR" && cd "$WORKDIR")
ps aux | grep $(whoami) | grep -v "sshd\|bash\|grep" | awk '{print $2}' | xargs -r kill -9 > /dev/null 2>&1

# Download Dependency Files
clear
echo -e "\e[1;35m正在安装中,请稍等...\e[0m"
ARCH=$(uname -m) && DOWNLOAD_DIR="." && mkdir -p "$DOWNLOAD_DIR" && FILE_INFO=()
if [ "$ARCH" == "arm" ] || [ "$ARCH" == "arm64" ] || [ "$ARCH" == "aarch64" ]; then
    FILE_INFO=("https://download.hysteria.network/app/latest/hysteria-freebsd-arm64 web" "https://github.com/eooce/test/releases/download/ARM/swith npm")
elif [ "$ARCH" == "amd64" ] || [ "$ARCH" == "x86_64" ] || [ "$ARCH" == "x86" ]; then
    FILE_INFO=("https://download.hysteria.network/app/latest/hysteria-freebsd-amd64 web" "https://github.com/eooce/test/releases/download/freebsd/npm npm")
else
    echo "Unsupported architecture: $ARCH"
    exit 1
fi
declare -A FILE_MAP
generate_random_name() {
    local chars=abcdefghijklmnopqrstuvwxyz1234567890
    local name=""
    for i in {1..6}; do
        name="$name${chars:RANDOM%${#chars}:1}"
    done
    echo "$name"
}
download_file() {
    local URL=$1
    local NEW_FILENAME=$2

    if command -v curl >/dev/null 2>&1; then
        curl -L -sS -o "$NEW_FILENAME" "$URL"
        echo -e "\e[1;32mDownloaded $NEW_FILENAME by curl\e[0m"
    elif command -v wget >/dev/null 2>&1; then
        wget -q -O "$NEW_FILENAME" "$URL"
        echo -e "\e[1;32mDownloaded $NEW_FILENAME by wget\e[0m"
    else
        echo -e "\e[1;33mNeither curl nor wget is available for downloading\e[0m"
        exit 1
    fi
}
for entry in "${FILE_INFO[@]}"; do
    URL=$(echo "$entry" | cut -d ' ' -f 1)
    RANDOM_NAME=$(generate_random_name)
    NEW_FILENAME="$DOWNLOAD_DIR/$RANDOM_NAME"
    
    download_file "$URL" "$NEW_FILENAME"
    
    chmod +x "$NEW_FILENAME"
    FILE_MAP[$(echo "$entry" | cut -d ' ' -f 2)]="$NEW_FILENAME"
done
wait

# Generate cert
openssl req -x509 -nodes -newkey ec:<(openssl ecparam -name prime256v1) -keyout "$WORKDIR/server.key" -out "$WORKDIR/server.crt" -subj "/CN=bing.com" -days 36500

get_ip() {
  HOSTNAME=$(hostname)
  ip=$(curl -s --max-time 1.5 ipv4.ip.sb)
  if [ -z "$ip" ]; then
    ip=$( [[ "$HOSTNAME" =~ ^s([0-9]|[1-2][0-9]|30)\.serv00\.com$ ]] && echo "cache${BASH_REMATCH[1]}.serv00.com" || echo "$HOSTNAME" )
  else
    url="https://www.toolsdaquan.com/toolapi/public/ipchecking/$ip/22"
    response=$(curl -s --location --max-time 3 --request GET "$url" --header 'Referer: https://www.toolsdaquan.com/ipcheck')
    if [ -z "$response" ] || ! echo "$response" | grep -q '"icmp":"success"'; then
        accessible=false
    else
        accessible=true
    fi
    if [ "$accessible" = false ]; then
        ip=$( [[ "$HOSTNAME" =~ ^s([0-9]|[1-2][0-9]|30)\.serv00\.com$ ]] && echo "cache${BASH_REMATCH[1]}.serv00.com" || echo "$ip" )
    fi
  fi
  echo "$ip"
}
if [[ "$(get_ip)" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    HOST_IP=$(get_ip)
else
    HOST_IP=$(host "$(get_ip)" | grep "has address" | awk '{print $4}')
fi

# Generate configuration file
cat << EOF > config.yaml
listen: $HOST_IP:$PORT

tls:
  cert: "$WORKDIR/server.crt"
  key: "$WORKDIR/server.key"

auth:
  type: password
  password: "$UUID"

fastOpen: true

masquerade:
  type: proxy
  proxy:
    url: https://bing.com
    rewriteHost: true

transport:
  udp:
    hopInterval: 30s
EOF

run() {
  if [ -e "$(basename ${FILE_MAP[npm]})" ]; then
    tlsPorts=("443" "8443" "2096" "2087" "2083" "2053")
    if [[ "${tlsPorts[*]}" =~ "${NEZHA_PORT}" ]]; then
      NEZHA_TLS="--tls"
    else
      NEZHA_TLS=""
    fi
    if [ -n "$NEZHA_SERVER" ] && [ -n "$NEZHA_PORT" ] && [ -n "$NEZHA_KEY" ]; then
      export TMPDIR=$(pwd)
      nohup ./"$(basename ${FILE_MAP[npm]})" -s ${NEZHA_SERVER}:${NEZHA_PORT} -p ${NEZHA_KEY} ${NEZHA_TLS} >/dev/null 2>&1 &
      sleep 1
      pgrep -x "$(basename ${FILE_MAP[npm]})" > /dev/null && echo -e "\e[1;32m$(basename ${FILE_MAP[npm]}) is running\e[0m" || { echo -e "\e[1;35m$(basename ${FILE_MAP[npm]}) is not running, restarting...\e[0m"; pkill -f "$(basename ${FILE_MAP[npm]})" && nohup ./"$(basename ${FILE_MAP[npm]})" -s ${NEZHA_SERVER}:${NEZHA_PORT} -p ${NEZHA_KEY} ${NEZHA_TLS} >/dev/null 2>&1 & sleep 2; echo -e "\e[1;32m"$(basename ${FILE_MAP[npm]})" restarted\e[0m"; }
    else
      echo -e "\e[1;35mNEZHA variable is empty, skipping running\e[0m"
    fi
  fi

  if [ -e "$(basename ${FILE_MAP[web]})" ]; then
    nohup ./"$(basename ${FILE_MAP[web]})" server config.yaml >/dev/null 2>&1 &
    sleep 1
    pgrep -x "$(basename ${FILE_MAP[web]})" > /dev/null && echo -e "\e[1;32m$(basename ${FILE_MAP[web]}) is running\e[0m" || { echo -e "\e[1;35m$(basename ${FILE_MAP[web]}) is not running, restarting...\e[0m"; pkill -f "$(basename ${FILE_MAP[web]})" && nohup ./"$(basename ${FILE_MAP[web]})" server config.yaml >/dev/null 2>&1 & sleep 2; echo -e "\e[1;32m$(basename ${FILE_MAP[web]}) restarted\e[0m"; }
  fi
rm -rf "$(basename ${FILE_MAP[web]})" "$(basename ${FILE_MAP[npm]})"
}
run

get_name() { if [ "$HOSTNAME" = "s1.ct8.pl" ]; then SERVER="CT8"; else SERVER=$(echo "$HOSTNAME" | cut -d '.' -f 1); fi; echo "$SERVER"; }
NAME="$(get_name)-hy2"

ISP=$(curl -s --max-time 2 https://speed.cloudflare.com/meta | awk -F\" '{print $26}' | sed -e 's/ /_/g' || echo "0")

echo -e "\e[1;32mHysteria2安装成功\033[0m\n"
echo -e "\e[1;32m本机IP：$HOST_IP\033[0m\n"
echo -e "\e[1;33mV2rayN 或 Nekobox、小火箭等直接导入,跳过证书验证需设置为true\033[0m\n"
echo -e "\e[1;32mhysteria2://$UUID@$HOST_IP:$PORT/?sni=www.bing.com&alpn=h3&insecure=1#$ISP-$NAME\033[0m\n"
echo -e "\e[1;33mSurge\033[0m"
echo -e "\e[1;32m$ISP-$NAME = hysteria2, $HOST_IP, $PORT, password = $UUID, skip-cert-verify=true, sni=www.bing.com\033[0m\n"
echo -e "\e[1;33mClash\033[0m"
cat << EOF
- name: $ISP-$NAME
  type: hysteria2
  server: $HOST_IP
  port: $PORT
  password: $UUID
  alpn:
    - h3
  sni: www.bing.com
  skip-cert-verify: true
  fast-open: true
EOF
rm -rf config.yaml fake_useragent_0.2.0.json
echo -e "\n\e[1;32mRuning done!\033[0m"
echo -e "\e[1;35m脚本地址：https://github.com/eooce/scripts\e[0m"
echo -e "\e[1;35m反馈论坛：https://bbs.vps8.me\e[0m"
echo -e "\e[1;35mTG反馈群组：https://t.me/vps888\e[0m"
echo -e "\e[1;35m转载请著名出处，请勿滥用\e[0m\n"
exit 0
