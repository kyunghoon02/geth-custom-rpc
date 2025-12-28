# WindowsReservedPort.md

## 해결 방법 (선택 완료: 포트 번호 변경)

포트 예약 문제를 우회하기 위해, 현재 프로젝트 설정을 **Windows가 잘 예약하지 않는 높은 번호의 포트**로 변경했습니다. 이제 매번 시스템 설정을 건드리지 않고도 실행이 가능합니다.

- **기존**: 8545(HTTP), 8551(Auth)
- **변경됨**: **18545(HTTP), 18551(Auth)**

따라서 이제 추가적인 Windows 설정 없이 바로 `./start_geth.sh`를 실행하시면 됩니다.

### 변경 적용 범위
- `start_geth.sh`: Geth 실행 포트 수정 완료
- `demo.py`: 테스트 스크립트의 접속 주소 수정 완료
- `README.md`: 문서 내 예제 명령어 수정 완료

---


## 가장 추천하는 "매번 안 해도 되는" 방법

매번 `winnat`을 끄고 켜거나 포트 충돌로 고생하지 않으려면, **방법 3(포트 수동 예약)**이 가장 깔끔합니다. 

### [추천] 방법 3: 특정 포트 예약 방지 (영구적)
Windows가 8545와 8551 포트를 "제멋대로" 예약 범위에 포함시키지 못하도록 딱 박아두는 방법입니다.

1. **관리자 권한**으로 PowerShell을 엽니다.
2. 아래 명령어를 순서대로 실행합니다:
   ```powershell
   # 1. 일단 현재 잠겨있는 포트를 풀기 위해 서비스 중지
   net stop winnat

   # 2. 8545와 8551을 '예약 제외'로 등록 (영구적)
   netsh int ipv4 add excludedportrange protocol=tcp startport=8545 numberofports=1 store=persistent
   netsh int ipv4 add excludedportrange protocol=tcp startport=8551 numberofports=1 store=persistent

   # 3. 서비스 다시 시작
   net start winnat
   ```
이제 컴퓨터를 껐다 켜도 Windows가 이 두 포트는 건드리지 않게 됩니다.

---

## 대안: 포트 번호 아예 바꾸기

만약 위 방법이 번거롭다면, `start_geth.sh`에서 포트를 **아예 다른 대역**으로 옮기는 것도 방법입니다. (예: 18545, 18551 등)
하지만 이 경우 **Consensus Client (Lighthouse 등)** 설정에서도 RPC 주소를 같이 바꿔줘야 작동합니다.

### Geth 설정 변경 예시 (`start_geth.sh`)
```bash
  --http.port 18545 \
  --authrpc.port 18551 \
```

---

## [참고] 포트 낭비 걱정은 안 하셔도 됩니다!
TCP 포트는 총 **65,535개**나 있습니다. 그중 딱 2개를 제외하는 것이라 시스템 성능이나 다른 프로그램 사용에 지장을 줄 확률은 거의 제로에 가깝습니다.

하지만 나중에 이 프로젝트를 아예 안 하게 되어 **원상복구(Clean up)**하고 싶다면, 아래 명령어로 언제든 제외 설정을 삭제할 수 있습니다.

### 제외 설정 삭제 방법 (복구)
관리자 권한 PowerShell에서:
```powershell
netsh int ipv4 delete excludedportrange protocol=tcp startport=8545 numberofports=1 store=persistent
netsh int ipv4 delete excludedportrange protocol=tcp startport=8551 numberofports=1 store=persistent
```

---

## [참고] 왜 이런 일이 생기나요?
Windows의 `TCP Dynamic Port Range` 설정 때문입니다. 특히 Hyper-V나 WSL2를 쓰면 Windows가 부팅될 때마다 랜덤하게 포트들을 '자기가 쓸 용도'로 찜해버리는데, 하필 Geth가 관례적으로 쓰는 8545 근처가 자주 걸립니다.

