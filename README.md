# Linux_root_Monitoring
Ubuntu를 이용해 root 계정과 sudo 권한 접근을 탐지하고, Slack에 알림 전송과 해당 IP 차단 기능을 구현한 레포지토리 입니다!
<br>
<br>

# 0. Getting Started
   
### 요구사항

- Ubuntu 22.04+ / 24.04+
- curl, ufw(또는 iptables), systemd-journald 사용 환경
- Slack Incoming Webhook URL 1개
<br>

# 1. Project Overview (프로젝트 개요)
- 프로젝트 이름: Ubuntu로 구현한 root계정, 일반 유저의 sudo 권한 탈취 모니터링 시스템
- 프로젝트 설명:
    - root 계정에 대한 비정상 로그인 시도 탐지
    - 일반 사용자(user)의 sudo/su 사용(성공/실패) 이벤트 감지
    - Slack으로 알림 전송
    - 비인가 원격 IP 자동 차단( ufw 또는 iptables )

<br/>
<br/>

# 2. Team Members (팀원 및 팀 소개)
| 박여명 | 신준수 |
|:------:|:------:|
| <img src="https://avatars.githubusercontent.com/u/166470537?v=4" alt="박여명" width="150"> | <img src="https://avatars.githubusercontent.com/u/137847336?v=4" alt="신준수" width="150"> |
| [GitHub](https://github.com/yeomyeoung) | [GitHub](https://github.com/shinjunsuuu) |

<br/>
<br/>

# 3. Key Features (주요 기능)

- **허용되지 않은 IP에서 지속적으로 root 계정에 접근 시도시 해당 IP 차단**:
  - 3회 이상 계정 접근 시도시 iptable 방화벽을 사용해 해당 ip 차단

- **root 로그인 실패/시도 감지**:
  - journalctl -t sshd 에서 Failed password for root 등 패턴 추출
  - **허용 IP(화이트리스트)** 면 알림만, 그 외는 자동 차단 + 알림(옵션)

- **sudo 사용/시도 감지**:
  - journalctl SYSLOG_IDENTIFIER=sudo 분석
  - user NOT in sudoers, authentication failure(실패), COMMAND=…(성공) 구분

- **su 사용/시도 감지**:
  - journalctl -t su 분석
  - authentication failure(실패), session opened for user …(성공) 구분

- **Slack 알림**:
  - 호스트명/시간/사용자/명령/원본 로그 조각 전송
  - 특수문자 JSON 이스케이프 처리

<br/>
<br/>

# 5. Technology Stack (기술 스택)
|  |  |
|-----------------|-----------------|
| Ubuntu    |<img src="https://github.com/user-attachments/assets/2e122e74-a28b-4ce7-aff6-382959216d31" alt="HTML5" width="100">| 
| MobaXterm    |   <img src="https://github.com/user-attachments/assets/c531b03d-55a3-40bf-9195-9ff8c4688f13" alt="CSS3" width="100">|
| 더 쓴게 있나    |  <img src="https://github.com/user-attachments/assets/4a7d7074-8c71-48b4-8652-7431477669d1" alt="Javascript" width="100"> | 

<br/>

## 5.2 Cooperation
|  |  |
|-----------------|-----------------|
| Git    |  <img src="https://github.com/user-attachments/assets/483abc38-ed4d-487c-b43a-3963b33430e6" alt="git" width="100">    |
| Notion    |  <img src="https://github.com/user-attachments/assets/34141eb9-deca-416a-a83f-ff9543cc2f9a" alt="Notion" width="100">    |
| Slack    |   <img src="" alt="Slack" width="100">   |

<br/>

# 6. Project Structure (프로젝트 구조)
```plaintext
systemd-journald  ──┐
  (sshd/sudo/su)   │  journalctl (최근 N분)
                   ├── 패턴 필터링 (awk/grep/sed)
                   │
                   ├── Slack Webhook 알림 (curl)
                   │
                   └── (옵션) 비인가 IP 자동 차단 (ufw/iptables)

```

<br/>
<br/>

# 7. 구성 파일

<br/>

```
Linux_Root-Monitoring/
├── scripts/
│   ├── monitor.sh       # root 로그인 시도 감지 + (옵션) IP 차단 + Slack 알림
│   └── watch_sudo.sh    # sudo/su 사용(성공/실패) 감지 + Slack 알림
├── allow_ips.txt        # 허용(화이트리스트) IP (선택)
└── README.md
```


<br/>
<br/>

# 10. 결과 출력
<img width="100%" alt="root 계정 접근 알림 출력" src="">
<img width="100%" alt="root 계정 접근 비인가 IP 차단" src="">
<img width="100%" alt="일반 USER의 sudo 명령어 사용 감지" src="">
