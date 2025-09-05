# 리눅스 Root권한 실시간 모니터링 & 자동화 차단 시스템
Linux(Ubuntu) 서버에서 root 계정 및 sudo 권한 접근 로그를 감시하여 **침입 탐지, Slack 보안 알림, iptables 기반 자동 차단** 기능을 Crontab 설정으로 자동화한 시스템입니다.


<br>

# 0. Getting Started
   
### 수행 환경
- 운영 환경: Ubuntu 24.04+
- 필수 패키지: curl, iptables, systemd-journald
- 외부 연동: Slack Incoming Webhook URL 1개
- 구현 방식: Shell Programming 기반 자동화 스크립트

<br>

# 1. Project Overview (프로젝트 개요)

- **프로젝트 이름**: Ubuntu 기반 root 계정 & sudo 권한 탈취 모니터링 시스템
- **프로젝트 설명**:
  - root 계정에 대한 비정상 로그인 시도 탐지
  - 일반 사용자(user)의 `sudo`/`su` 사용 실패 이벤트 감지
  - Slack으로 실시간 알림 전송
  - 비인가 원격 IP 자동 차단 (iptables 기반)
<br>

# 2. Technology Stack (기술 스택)

## 2.1 OS & Tools
| Ubuntu | MobaXterm |
|--------|-----------|
| <img width="70" height="70" alt="image" src="https://github.com/user-attachments/assets/2c24dfc4-6692-4250-bb00-3f1b6decbeac" > | <img width="70" height="70" alt="image" src="https://github.com/user-attachments/assets/b9ae3f4a-9b01-4e12-9806-12dc33bdbe8e" > |

## 2.2 Cooperation
| Git | Notion | Slack |
|-----|--------|-------|
| <img src="https://github.com/user-attachments/assets/483abc38-ed4d-487c-b43a-3963b33430e6" alt="git" width="70"> | <img src="https://github.com/user-attachments/assets/34141eb9-deca-416a-a83f-ff9543cc2f9a" alt="Notion" width="70"> | <img src="https://cdn.simpleicons.org/slack" alt="Slack" width="70"> |


<br>

# 3. Team Members (팀원 및 팀 소개)

| 박여명 | 신준수 |
|:------:|:------:|
| <img src="https://avatars.githubusercontent.com/u/166470537?v=4" alt="박여명" width="150"> | <img src="https://avatars.githubusercontent.com/u/137847336?v=4" alt="신준수" width="150"> |
| [GitHub](https://github.com/yeomyeoung) | [GitHub](https://github.com/shinjunsuuu) |

<br>

# 4. Key Features (주요 기능)
| 구분 | 기능 설명 | 탐지 방법 | 추가 동작 |
|------|-----------|-----------|-----------|
| **Root 접근 시도** | 허용되지 않은 IP의 root 접근 시도 탐지 및 차단 | `journalctl -u sshd` → `Accepted`, `Failed password` 패턴 분석 | 3회 이상 실패 시 자동 차단 / 허용 IP(화이트리스트)는 알림만 전송 |
| **Root 로그인 이벤트** | root 로그인 성공/실패 이벤트 감지 | `journalctl -u sshd` 분석 | Slack 알림 전송 |
| **Sudo 사용/시도** | sudo 권한 사용/시도 감지 | `journalctl SYSLOG_IDENTIFIER=sudo` 분석 → `user NOT in sudoers`, `authentication failure`, `COMMAND=...` 구분 | Slack 알림 전송 |
| **Su 사용/시도** | su 권한 전환 감지 | `journalctl -t su` 분석 → `authentication failure`, `session opened` 구분 | Slack 알림 전송 |
| **Slack 알림** | 호스트명, 시간, 사용자, 명령, 원본 로그 조각 전달 | JSON 이스케이프 처리 적용 | 안정적인 메시지 전송 |

<br>

<br>

# 5. Project Structure (프로젝트 구조)
```
plaintext
systemd-journald  ──┐
  (sshd/sudo/su)   │  journalctl (최근 N분)
                   ├── 패턴 필터링 (awk/grep/sed)
                   │
                   ├── Slack Webhook 알림 (curl)
                   │
                   └── 비인가 IP 자동 차단 (iptables)
```
<br>

# 6. 구성 파일
```
Linux_Root-Monitoring/
├── scripts/
│   ├── monitor.sh       # root 로그인 시도 감지 +  IP 차단 + Slack 알림
│   └── watch_sudo.sh    # sudo/su 사용 실패 감지 + Slack 알림
└── allow_ips.txt        # 허용(화이트리스트) IP 
```
<br>

# 7. 실행 방법 (Usage)

### 7.1 수동 실행
```
bash scripts/monitor.sh
bash scripts/watch_sudo.sh
```

### 7-2 Crontab 활용 자동화
```
crontab -e
```

아래 내용 추가:
```
cron
* * * * * /usr/bin/bash /home/ubuntu/Linux_Root-Monitoring/scripts/monitor.sh
* * * * * /usr/bin/bash /home/ubuntu/Linux_Root-Monitoring/scripts/watch_sudo.sh
```
<br>
<br>

# 8. Slack 알림을 통한 결과 출력

### 비인가 IP root 접근 알림
<img width="570" alt="비인가 IP root 계정 접근 알림 출력" src="https://github.com/user-attachments/assets/4d8c5a4a-631f-4712-b97a-0e466dab53a3" />
<br>
<br>

### 비인가 IP 3회 이상 접근 시 차단
<img width="570" alt="비인가 IP 3회 이상 접근 시 차단" src="https://github.com/user-attachments/assets/a7d90397-89da-43f8-9bd0-f209afea9f81" />
<br>
<br>

### 해당 IP 차단 확인
<img width="480" alt="iptables DROP 규칙 확인" src="https://github.com/user-attachments/assets/6fb18d87-116a-40f3-b577-382ee437b16f" />
<br>
<br>

### 일반 USER sudo 명령어 감지
<img width="570" alt="sudo 명령 감지" src="https://github.com/user-attachments/assets/96e86acb-a855-49ee-aa3c-200a36bf94cc" />
<br>
<br>

### 일반 USER 3회 이상 sudo 명령어 실패 시 계정 차단
<img width="560" alt="sudo 3회 실패 계정 차단" src="https://github.com/user-attachments/assets/31dd9cb1-cd4f-47a6-aa7d-59035b44fa4b" />

<br>
<br>

# 9. Troubleshooting

<details>
<summary><h3> 1. root 권한 변경 적용 문제</h3></summary>
<br>
시스템 설정 파일에서 root 권한을 부여했음에도 즉시 적용되지 않아 root 계정 접근이 불가능한 문제가 발생. 
<br>
분석 결과, 서비스 단순 재시작만으로는 반영되지 않는 경우가 있었으며, 최종적으로 시스템 재부팅(restart) 으로 권한 변경 사항이 정상 적용됨을 확인.  

👉 권한 및 보안 설정 변경 시 즉각적인 반영 여부를 점검하고, 필요 시 재부팅까지 고려해야 함.
</details>

<details>
<summary><h3> 2. 내 IP가 차단된 경우</h3></summary>
<br>
테스트 중 본인의 IP가 `iptables` 또는 `ufw`에 의해 차단되어 접속 불가 상황이 발생.  
아래 명령어로 확인 가능:
bash
sudo iptables -L INPUT -n --line-numbers
sudo ufw status numbered

차단 해제:
bash
sudo iptables -D INPUT <번호>
sudo ufw delete <번호>
sudo netfilter-persistent save

👉 운영 시 관리자 본인 IP는 반드시 화이트리스트(`allow_ips.txt`)에 미리 추가하는 것이 안전.
</details>

<details>
<summary><h3> 3. Slack 알림이 전송되지 않는 경우</h3></summary>
<br>
Slack Webhook URL 설정 오류, 네트워크 차단, JSON 이스케이프 문제로 인해 알림 전송이 실패할 수 있음.  

- Webhook URL 유효성 재확인  
- `curl` 명령으로 직접 테스트:
bash
curl -X POST -H 'Content-type: application/json' --data '{"text":"테스트 메시지"}' https://hooks.slack.com/services/XXX/YYY/ZZZ

- 메시지 본문에 따옴표(`"`)나 백슬래시(`\`)가 포함될 경우 JSON escape 필수
</details>

<details>
<summary><h3> 4. sshd_config 변경 후 접속 불가</h3></summary>
<br>
`sshd_config` 또는 `/etc/ssh/sshd_config.d/*.conf` 설정 오류 시 SSH 연결이 차단될 수 있음.  

대응 방법:
- 변경 전 반드시 문법 검사:
bash
sudo sshd -t
- 문제가 생겼을 때는 콘솔 접속(클라우드 VM이라면 웹 콘솔) 후 설정 복구  
- 필요 시 `PermitRootLogin yes` 와 `AllowUsers` 설정을 최소화하여 임시 접속 허용
</details>

<details>
<summary><h3> 5. cron 실행이 안 되는 경우</h3></summary>
<br>
스크립트가 수동 실행은 잘 되지만 `cron` 등록 후 실행되지 않는 문제가 발생할 수 있음.  

원인:
- `cron` 환경에서는 PATH, 환경변수 부족
- `journalctl` 명령어 실행 시 `sudo` 권한 문제

해결:
- `cron`에서 절대 경로 지정:
cron
* * * * * /usr/bin/bash /home/ubuntu/Linux_Root-Monitoring/scripts/monitor.sh
- 스크립트 내부에서 `sudo` 사용 시, `visudo` 로 `NOPASSWD` 권한 부여
</details>

<details>
<summary><h3> 6. systemd 서비스 로그 확인</h3></summary>
<br>
systemd 서비스 등록 후 실행이 안 될 경우 로그 확인이 필요:
bash
sudo systemctl status root-monitor
journalctl -u root-monitor -f

👉 로그를 통해 Slack 전송 실패, iptables 권한 문제 등 원인을 빠르게 파악할 수 있음.
</details>
