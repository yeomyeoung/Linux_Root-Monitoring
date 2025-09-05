#!/bin/sh

WEBHOOK_URL="https://hooks.slack.com/services/***"
LOGFILE="/var/log/sudo_fail_lock.log"

sudo journalctl --since "1 minutes ago" -t sudo | \
grep -E "authentication failure|NOT in sudoers" | \
awk '
/user=/ {
  match($0, /user=([^ ]*)/, m)
  if (m[1] != "") print m[1]
}
/NOT in sudoers/ {
  match($0, /^.*sudo.*: *([^ ]*)[[:space:]]*:/, m)
  if (m[1] != "") print m[1]
}' | sort | uniq -c | while read count user; do
  if [ "$user" != "ubuntu" ] && [ "$user" != "root" ]; then
    if [ "$count" -ge 3 ]; then
      MSG="🚨 sudo 실패 차단 → 사용자: $user, 실패 횟수: $count (계정 잠금)"
      echo "$(date '+%F %T') $MSG" | tee -a "$LOGFILE"
      sudo passwd -l "$user"
      curl -sS -X POST -H 'Content-type: application/json' \
        --data "{\"text\":\"$MSG\"}" "$WEBHOOK_URL" >/dev/null
    elif [ "$count" -ge 1 ]; then
      MSG="⚠️ sudo 실패 경고 → 사용자: $user, 실패 횟수: $count"
      echo "$(date '+%F %T') $MSG" | tee -a "$LOGFILE"
      curl -sS -X POST -H 'Content-type: application/json' \
        --data "{\"text\":\"$MSG\"}" "$WEBHOOK_URL" >/dev/null
    fi
  fi
done
