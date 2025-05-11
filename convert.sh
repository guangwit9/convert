#!/bin/bash

NODE_FILE="/etc/s-box-ag/jh.txt"
NODE_DIR=$(dirname "$NODE_FILE")
SING_BOX_CONFIG="$NODE_DIR/sing_box_client.json"
CLASH_CONFIG="$NODE_DIR/clash_meta_client.yaml"

# 使用sudo清空目标文件
sudo truncate -s 0 "$SING_BOX_CONFIG"
sudo truncate -s 0 "$CLASH_CONFIG"

NODE_NAME_1=$(sed -n '11p' "$NODE_FILE")
NODE_NAME_2=$(sed -n '12p' "$NODE_FILE")

# 使用sudo写入内容
echo "{" | sudo tee -a "$SING_BOX_CONFIG" > /dev/null
echo '  "outbounds": [' | sudo tee -a "$SING_BOX_CONFIG" > /dev/null
echo "proxies:" | sudo tee -a "$CLASH_CONFIG" > /dev/null

node_counter=0
while IFS= read -r line; do
  if [ "$node_counter" -eq 10 ] || [ "$node_counter" -eq 11 ]; then
    node_counter=$((node_counter + 1))
    continue
  fi

  if [[ "$line" =~ vmess:// ]]; then
    uuid=$(echo "$line" | base64 -d | jq -r '.id')
    server=$(echo "$line" | base64 -d | jq -r '.add')
    port=$(echo "$line" | base64 -d | jq -r '.port')
    tls=$(echo "$line" | base64 -d | jq -r '.tls')

    if [ "$node_counter" -gt 0 ]; then echo ',' | sudo tee -a "$SING_BOX_CONFIG" > /dev/null; fi
    echo "    {" | sudo tee -a "$SING_BOX_CONFIG" > /dev/null
    echo "      \"type\": \"vmess\"," | sudo tee -a "$SING_BOX_CONFIG" > /dev/null
    echo "      \"server\": \"$server\"," | sudo tee -a "$SING_BOX_CONFIG" > /dev/null
    echo "      \"server_port\": $port," | sudo tee -a "$SING_BOX_CONFIG" > /dev/null
    echo "      \"uuid\": \"$uuid\"," | sudo tee -a "$SING_BOX_CONFIG" > /dev/null
    echo "      \"tls\": {\"enabled\": $tls}" | sudo tee -a "$SING_BOX_CONFIG" > /dev/null
    echo "    }" | sudo tee -a "$SING_BOX_CONFIG" > /dev/null

    echo "  - name: \"$NODE_NAME_1\"" | sudo tee -a "$CLASH_CONFIG" > /dev/null
    echo "    type: vmess" | sudo tee -a "$CLASH_CONFIG" > /dev/null
    echo "    server: $server" | sudo tee -a "$CLASH_CONFIG" > /dev/null
    echo "    port: $port" | sudo tee -a "$CLASH_CONFIG" > /dev/null
    echo "    uuid: $uuid" | sudo tee -a "$CLASH_CONFIG" > /dev/null
    echo "    tls: $tls" | sudo tee -a "$CLASH_CONFIG" > /dev/null
    echo "    alterId: 0" | sudo tee -a "$CLASH_CONFIG" > /dev/null
    echo "    cipher: auto" | sudo tee -a "$CLASH_CONFIG" > /dev/null

  elif [[ "$line" =~ ss:// ]]; then
    server=$(echo "$line" | cut -d '@' -f2 | cut -d ':' -f1)
    port=$(echo "$line" | cut -d '@' -f2 | cut -d ':' -f2)
    password=$(echo "$line" | cut -d ':' -f2 | cut -d '@' -f1)
    method=$(echo "$line" | cut -d ':' -f1 | cut -d '/' -f3)

    if [ "$node_counter" -gt 0 ]; then echo ',' | sudo tee -a "$SING_BOX_CONFIG" > /dev/null; fi
    echo "    {" | sudo tee -a "$SING_BOX_CONFIG" > /dev/null
    echo "      \"type\": \"ss\"," | sudo tee -a "$SING_BOX_CONFIG" > /dev/null
    echo "      \"server\": \"$server\"," | sudo tee -a "$SING_BOX_CONFIG" > /dev/null
    echo "      \"server_port\": $port," | sudo tee -a "$SING_BOX_CONFIG" > /dev/null
    echo "      \"password\": \"$password\"," | sudo tee -a "$SING_BOX_CONFIG" > /dev/null
    echo "      \"method\": \"$method\"" | sudo tee -a "$SING_BOX_CONFIG" > /dev/null
    echo "    }" | sudo tee -a "$SING_BOX_CONFIG" > /dev/null

    echo "  - name: \"$NODE_NAME_2\"" | sudo tee -a "$CLASH_CONFIG" > /dev/null
    echo "    type: ss" | sudo tee -a "$CLASH_CONFIG" > /dev/null
    echo "    server: $server" | sudo tee -a "$CLASH_CONFIG" > /dev/null
    echo "    port: $port" | sudo tee -a "$CLASH_CONFIG" > /dev/null
    echo "    password: $password" | sudo tee -a "$CLASH_CONFIG" > /dev/null
    echo "    method: $method" | sudo tee -a "$CLASH_CONFIG" > /dev/null

  elif [[ "$line" =~ trojan:// ]]; then
    server=$(echo "$line" | cut -d '@' -f2 | cut -d ':' -f1)
    port=$(echo "$line" | cut -d '@' -f2 | cut -d ':' -f2)
    password=$(echo "$line" | cut -d '/' -f3)

    if [ "$node_counter" -gt 0 ]; then echo ',' | sudo tee -a "$SING_BOX_CONFIG" > /dev/null; fi
    echo "    {" | sudo tee -a "$SING_BOX_CONFIG" > /dev/null
    echo "      \"type\": \"trojan\"," | sudo tee -a "$SING_BOX_CONFIG" > /dev/null
    echo "      \"server\": \"$server\"," | sudo tee -a "$SING_BOX_CONFIG" > /dev/null
    echo "      \"server_port\": $port," | sudo tee -a "$SING_BOX_CONFIG" > /dev/null
    echo "      \"password\": \"$password\"" | sudo tee -a "$SING_BOX_CONFIG" > /dev/null
    echo "    }" | sudo tee -a "$SING_BOX_CONFIG" > /dev/null

    echo "  - name: \"$NODE_NAME_2\"" | sudo tee -a "$CLASH_CONFIG" > /dev/null
    echo "    type: trojan" | sudo tee -a "$CLASH_CONFIG" > /dev/null
    echo "    server: $server" | sudo tee -a "$CLASH_CONFIG" > /dev/null
    echo "    port: $port" | sudo tee -a "$CLASH_CONFIG" > /dev/null
    echo "    password: $password" | sudo tee -a "$CLASH_CONFIG" > /dev/null
  fi

  node_counter=$((node_counter + 1))
done < "$NODE_FILE"

# 完成配置文件
echo "  ]" | sudo tee -a "$SING_BOX_CONFIG" > /dev/null
echo "}" | sudo tee -a "$SING_BOX_CONFIG" > /dev/null

# 写入 Clash 配置
echo "proxy-groups:" | sudo tee -a "$CLASH_CONFIG" > /dev/null
echo "  - name: 自动选择" | sudo tee -a "$CLASH_CONFIG" > /dev/null
echo "    type: select" | sudo tee -a "$CLASH_CONFIG" > /dev/null
echo "    proxies:" | sudo tee -a "$CLASH_CONFIG" > /dev/null

# 提示输入 GitLab 信息
: "${TOKEN:=}"
: "${GIT_USER:=}"
: "${GIT_EMAIL:=}"
: "${PROJECT:=}"

[ -z "$TOKEN" ] && read -p "GitLab Token: " TOKEN
[ -z "$GIT_USER" ] && read -p "GitLab 用户名: " GIT_USER
[ -z "$GIT_EMAIL" ] && read -p "GitLab 邮箱: " GIT_EMAIL
[ -z "$PROJECT" ] && read -p "GitLab 项目名: " PROJECT

# 设置 Git 配置
TMP_DIR="/tmp/idx_upload"
FILES=(
  "$NODE_DIR/sing_box_client.json"
  "$NODE_DIR/clash_meta_client.yaml"
  "$NODE_DIR/jh.txt"
)

git config --global user.name "$GIT_USER"
git config --global user.email "$GIT_EMAIL"

# 检查文件是否存在
for FILE in "${FILES[@]}"; do
  if [ ! -f "$FILE" ]; then
    echo "缺少文件：$FILE"
    exit 1
  fi
done

# 上传到 GitLab
rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR"
cd "$TMP_DIR" || exit 1

git clone https://oauth2:$TOKEN@gitlab.com/$GIT_USER/$PROJECT.git
cd "$PROJECT" || exit 1

# 复制文件并提交
for FILE in "${FILES[@]}"; do
  BASENAME=$(basename "$FILE")
  cp "$FILE" "./$BASENAME"
  sed -i 's/ \{1,\}/ /g' "$BASENAME"
done

git add *.json *.yaml jh.txt
git commit -m "更新订阅文件 $(date '+%Y-%m-%d %H:%M:%S')" || echo "无变更"
git push origin main --force 2>/dev/null || git push origin master --force

echo "上传完成：$PROJECT 项目"
