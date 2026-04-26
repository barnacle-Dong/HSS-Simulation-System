# SKT BPFdoor Incident Simulation: HSS Production Clone

본 프로젝트는 2025년 발생한 **SKT BPFdoor 해킹 사건**을 모티브로 하여, 실제 통신사 **HSS(Home Subscriber Server)** 운영 환경을 고도로 클론 코딩한 모의해킹 실습용 타겟 서버입니다.

이 환경은 단순히 취약점을 찾는 실습이 아니라, **강력하게 보안 설정된 서버에서 APT 공격자가 어떻게 은닉하고 데이터를 유출하는지** 연구하기 위해 설계되었습니다.

## 🎯 실습 목표 (Learning Objectives)
1. **실무 보안 설정 분석**: KISA/GSMA 가이드라인이 적용된 서버의 방화벽 및 커널 설정을 분석합니다.
2. **권한 상승 후 사후 활동(Post-Exploitation)**: 이미 관리자 권한을 획득했다는 가정 하에, 시스템 내에서 흔적을 남기지 않고 데이터를 탈취하는 시나리오를 설계합니다.
3. **은닉형 백도어 원리 이해**: `iptables` 방화벽을 우회하기 위해 BPF(Berkeley Packet Filter)와 같은 커널 기술이 왜 필요한지 실습을 통해 체득합니다.
4. **침해사고 분석(Forensics)**: 관리자 입장에서 `ss -raw`, `bpftool`, `journalctl` 등을 사용하여 은닉된 공격 징후를 탐지해 봅니다.

## 🏗 시스템 구조
- **API**: `systemd` 데몬으로 관리되는 Python 기반 HSS Core 서비스.
- **Database**: 3GPP 규격을 따른 5만 건의 가입자 정보 및 인증 벡터(SQLite).
- **Security**: `iptables` 화이트리스트 및 `sysctl` 커널 하드닝(SYN Cookie, ICMP 차단 등).

## 🚀 시작하기 (Deployment Guide)

### 1. 사전 준비
이 환경은 시스템 설정을 변경하므로 **Ubuntu Linux** 환경을 권장합니다.

```bash
git clone https://github.com/your-username/skt-hss-clone.git
cd skt-hss-clone
```

### 2. 가입자 데이터베이스 생성 (필수)
저작권 및 보안상의 이유로 실제 데이터베이스 파일은 포함되어 있지 않습니다. 아래 스크립트를 실행하여 5만 건의 실습용 데이터를 로컬에서 직접 생성해야 합니다.

```bash
python3 real_hss_system/db/init_db.py
```

### 3. 서버 환경 배포 (Root 권한 필요)
아래 스크립트를 실행하면 API 서비스 등록, 커널 보안 정책 적용, 방화벽 설정이 한 번에 완료됩니다.

```bash
sudo bash deploy_production.sh
```

## 🔍 관리자 체크리스트 (탐지 가이드)
공격자가 은닉형 백도어를 심었다면, 다음 명령어를 통해 징후를 포착할 수 있습니다.
- `sudo ss -raw -a`: 방화벽을 우회하는 **Raw Socket** 프로세스 확인.
- `journalctl -u hss_core -f`: HSS 서비스의 실시간 비정상 로그 모니터링.
- `sudo bpftool prog`: 커널에 로드된 의심스러운 BPF 프로그램 확인.

## 서비스 제어 및 확인 방법
이제 사용자는 실제 서버 관리자처럼 다음 명령어들을 사용하여 시스템을 제어할 수 있습니다.
- 서비스 상태 확인  `systemctl status hss_core`
- 실시간 로그 확인  `journalctl -u hss_core -f`
- 서비스 재시작  `sudo systemctl restart hss_core`
- 서비스 종료 `sudo systemctl stop hss_core`

## ⚠️ 면책 조항 (Disclaimer)
본 프로젝트는 교육 및 연구 목적으로만 제공됩니다. 허가받지 않은 시스템에서의 악용은 법적 책임을 질 수 있습니다.
