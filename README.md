# Linux_root_Monitoring
Ubuntu를 이용해 root 계정과 sudo 권한 접근을 탐지하고, Slack에 알림 전송과 해당 IP 차단 기능을 구현한 레포지토리 입니다!
<br>
<br>

# 0. Getting Started
   
### 수행 환경

- Ubuntu 24.04+
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

# 4. Technology Stack (기술 스택)
## 4.1 
|  |  |
|-----------------|-----------------|
| Ubuntu    |<img width="80" height="80" alt="image" src="https://github.com/user-attachments/assets/d0627fec-00c1-49d3-b447-aaebed8ab5c6" />| 
| MobaXterm    |<img width="80" height="80" alt="image" src="https://github.com/user-attachments/assets/810ce5c8-8789-458c-8593-d56e8b3ee617" />|


<br/>

## 4.2 Cooperation
|  |  |
|-----------------|-----------------|
| Git    |  <img src="https://github.com/user-attachments/assets/483abc38-ed4d-487c-b43a-3963b33430e6" alt="git" width="100">    |
| Notion    |  <img src="https://github.com/user-attachments/assets/34141eb9-deca-416a-a83f-ff9543cc2f9a" alt="Notion" width="100">    |
| Slack    |   <img src="https://cdn.simpleicons.org/slack" alt="Slack" width="100">   |

<br/>

# 5. Project Structure (프로젝트 구조)
```plaintext
systemd-journald  ──┐
  (sshd/sudo/su)   │  journalctl (최근 N분)
                   ├── 패턴 필터링 (awk/grep/sed)
                   │
                   ├── Slack Webhook 알림 (curl)
                   │
                   └── (옵션) 비인가 IP 자동 차단 (ufw/iptables)
```


# 6. 구성 파일

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

# 7. 결과 출력
## 비인가 IP의 root 계정 접근 알림 출력
<img width="570" height="80" alt="비인가 IP의 root 계정 접근 알림 출력" src="https://github.com/user-attachments/assets/4d8c5a4a-631f-4712-b97a-0e466dab53a3" />
<br><br>

## 비인가 IP가 3회 이상 접근 시도시 해당 IP 차단
<img width="570" height="80" alt="비인가 IP가 3회 이상 접근 시도시 해당 IP 차단" src="https://github.com/user-attachments/assets/a7d90397-89da-43f8-9bd0-f209afea9f81" />
<br><br>

## 해당 IP 차단 확인
<img width="480" height="134" alt="image" src="https://github.com/user-attachments/assets/6fb18d87-116a-40f3-b577-382ee437b16f" />
<br><br>

## 일반 USER의 sudo 명령어 사용 감지
<img width="570" height="80" alt="image" src="https://github.com/user-attachments/assets/96e86acb-a855-49ee-aa3c-200a36bf94cc" />
<br><br>

## 일반 USER가 3회 이상 sudo 명령어 입력시 계정 차단
<img width="560" height="180" alt="image" src="https://github.com/user-attachments/assets/31dd9cb1-cd4f-47a6-aa7d-59035b44fa4b" />


# 8. 트러블슈팅

<details>
<summary><h3> 1. restart 로 root 권한 변경 적용</h3></summary>
<br>
시스템 설정 파일에서 root 권한을 부여했음에도, 즉시 적용되지 않아 root 계정 접근이 불가능한 문제가 발생.  
원인 분석 과정에서 서비스 단순 재시작만으로는 반영되지 않는 경우가 있음을 확인하였고, 최종적으로 시스템을 재부팅(restart)하여 권한 변경 사항이 정상적으로 적용됨을 확인.  

**권한 및 보안 설정 변경 시 즉각적인 반영 여부를 점검하고, 필요 시 시스템 재시작을 고려해야 한다는 점**을 학습했습니다.  

</details>


