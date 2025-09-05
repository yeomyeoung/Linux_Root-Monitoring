#!/bin/bash
set -Eeuo pipefail

# ===== 설정 =====
WEBHOOK_URL="https://hooks.slack.com/services/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"
ALLOW_FILE="/home/ubuntu/allow_ips.txt"
TIME_WINDOW_MIN=1
THRESHOLD=3
HOSTNAME=$(hostname)

# 화이트리스트 읽기 (주석/빈 줄 제거)
ALLOW_LIST=()
if [[ -f "$ALLOW_FILE" ]]; then
  while IFS= read -r line; do
    ip=$(echo "$line" | sed -E 's/#.*$//' | xargs)
    [[ -n "$ip" ]] && ALLOW_LIST+=("$ip")
  done < "$ALLOW_FILE"
fi

# 최근 N분간 root 로그인 실패 IP 카운트
COUNTS=$(
  LC_ALL=C sudo journalctl -u ssh --since "${TIME_WINDOW_MIN} minutes ago" --no-pager \
    | awk '/Failed password for (invalid user )?root/ {for(i=1;i<=NF;i++) if($i=="from") print $(i+1)}' \
    | sort | uniq -c
)

# 각 라인 처리 "<count> <ip>"
while read -r line; do
  [[ -z "$line" ]] && continue
  count=$(awk '{print $1}' <<< "$line")
  ip=$(awk '{print $2}' <<< "$line")
  [[ -z "$ip" ]] && continue

  # 화이트리스트 검사
  is_allowed=false
  for w in "${ALLOW_LIST[@]}"; do
    if [[ "$ip" == "$w" ]]; then
      is_allowed=true
      break
    fi
  done

  if $is_allowed; then
    curl -s -X POST -H 'Content-type: application/json' \
      --data "{\"text\":\"⚠️ [$HOSTNAME] 허용된 IP $ip 에서 root 로그인 실패 ${count}회 (차단 안 함)\"}" \
      "$WEBHOOK_URL" >/dev/null 2>&1
    continue
  fi

  # 차단 조건
  if [[ "$count" -ge "$THRESHOLD" ]]; then
    if sudo iptables -C INPUT -s "$ip" -j DROP 2>/dev/null; then
      curl -s -X POST -H 'Content-type: application/json' \
        --data "{\"text\":\"⛔ [$HOSTNAME] 이미 차단된 IP $ip, 실패 누적 ${count}회\"}" \
        "$WEBHOOK_URL" >/dev/null 2>&1
    else
      sudo iptables -I INPUT -s "$ip" -j DROP
      sudo netfilter-persistent save   # 🔥 추가된 부분 (영속 저장)
      curl -s -X POST -H 'Content-type: application/json' \
        --data "{\"text\":\"⛔ [$HOSTNAME] 차단 적용 & 저장: IP $ip (root 로그인 실패 ${count}회)\"}" \
        "$WEBHOOK_URL" >/dev/null 2>&1
    fi
  else
    curl -s -X POST -H 'Content-type: application/json' \
      --data "{\"text\":\"🚨 [$HOSTNAME] root 로그인 실패 ${count}회 / 임계치 ${THRESHOLD}, IP: $ip\"}" \
      "$WEBHOOK_URL" >/dev/null 2>&1
  fi
done <<< "$COUNTS"
