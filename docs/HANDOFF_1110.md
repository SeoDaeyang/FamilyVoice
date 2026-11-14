# 11/10(화) 대양 쪽 변경 · 공유

11/9 작업(`290a2b0`) 받은 뒤 고친 것. **코드 변경 4개**, 나머지는 정해진 것·확인한 것.
촬영 대본: https://claude.ai/artifact/281pKu5ayiPxrU93bWvbba

---

## 1. 코드 변경

| 파일 | 내용 |
|---|---|
| `TripScenario.kt` | 시연 주행 **1.5배 느리게** (100km/h 기준): `LEG1_MS` 10→**15초**, `LEG2_MS` 10→**15초**, `LEG3_MS` 10→**15초**, `LEG_HOME_MS` 8→**12초**. `LEG1_SLOW_MS`(작년 목소리 21초)는 **그대로** |
| `MainActivity.kt` | **촬영 신호 `cue()`** 추가 — 화면엔 안 나오고 `adb logcat -s FV_CUE` 에만 찍힘. ① 구간 남은 거리 5→1km (`driveAlong` tick, 바뀔 때만) ② `arriveLeg()` → `✅ ○○ 도착 — 이제 속도 0 → P` ③ `playLastYearVoice()` 시작 → `🔊 작년 목소리 시작` ④ `v_saved` 끝(마이크·시연 녹음 둘 다) → `💾 저장 끝 — 이제 가속`. `SHOW_STATUS=false` 로 찍어도 언제 속도 0·P 넣을지 알 수 있게 |
| `MainActivity.kt` | `checkPastSpot()` (돌아오는 길 3km 안 예전 장소) 에서 **`v_revisit_intro` 소리 제거** — 이 카드엔 들려줄 목소리가 없어서 "이런 말을 남기셨어요." 뒤가 비었음. 카드(`pastSpot`)는 그대로 |
| `HomeScreen.kt` | 지도 오른쪽 맨 아래에 출처 글자 **`© OpenFreeMap · © OpenMapTiles · © OpenStreetMap contributors`** 항상 표시 (OpenStreetMap 사용 조건). 왼쪽 패널에 가려지던 MapLibre 기본 ⓘ 버튼은 끔(`isAttributionEnabled = false`). **지우지 말 것** |

---

## 2. 정해진 것

- **대학생 부문 2인 팀으로 참가** → 팀명 정해야 함 (메일 제목 `[차량용 앱 개발 공모전] 팀명_대표자명`, APK 이름 `팀명_차곡차곡_release.apk`)
- 동의서 **각자 서명**, 제출 메일에 팀원 **CC** (수정제출 때도 매번)
- Pleos Playground 프로젝트(family-voice)에 **Developer로 초대 예정** → 메일 오면 수락
- 시연 영상 녹화 **AI 목소리 그대로** 진행
- 영상 순서: ① 여행 탭 → **경주 여행**(천안삼거리휴게소 호두과자 핀 = 뒤 클라이맥스 복선, 목소리는 안 누름) → ② 음식점·휴게소 탭 → ③ 여행 시작·**사진 QR** → ④ 여행 과정 → ⑤ 집 도착

---

## 3. 확인한 것

**주최 측 답장 (3번 받음)** — 새로 확정된 건 거의 없음
- 개인정보 없는 짧은 글 → 외부 LLM(HTTPS) **OK**
- Android Normal·Dangerous 권한 API **OK** → 녹음(`RECORD_AUDIO`)도 사실상 OK. MediaRecorder 개별 확인만 남음
- 에뮬 기어는 Virtual Console로 변경 가능
- 서버 정적 JSON 받기는 인터넷 권한 따로 필요 없음 (사진 QR처럼 서버에 요청 보내는 건 미정)
- 추가 문의 보낼 것: 포그라운드 서비스(백그라운드 위치) / Apps Script 요청 / **현재 차 속도 읽는 법** / 녹음 우선 확인 / 2인 팀 변경

**TTS·STT** — Playground 콘솔에서 아직 **Coming Soon**, LLM은 목록에도 없음. SERVER는 401(권한 미오픈), ON_DEVICE는 에뮬에 엔진 없음 → **미리 녹음한 음성 유지가 맞음**. 코드는 이미 "되면 TTS, 안 되면 파일"

**공모전 규칙 (사이트 전부 확인)**
- GitHub: APK는 **`apk/` 폴더**, **release 버전**(서명), README에 앱 이름·한 줄 소개 / 실행 방법 / 테스트 환경·설정 / APK 위치
- 마감 11/15 (**시각 안 적혀 있음** → 일찍 제출). 마지막 제출본이 최종
- 1차 결과 11/23 → 2차 오프라인 PT 12/3~4 (20팀, **실제 동작 시연**) → 최종 12/18. **11/15 이후에도 PT 전까지 고도화 가능**
- 심사 4개: 차량특화성 · 창의성 · **기술 활용성(Pleos SDK를 핵심 기능에)** · 사업성(타깃·MAU·리텐션·확장)
- **제3자 권리(저작권·초상권) 침해 금지**, 서류 내용이 사실과 다르면 취소 → 사진·목소리가 AI라 README/영상에 **"시연용 사진·목소리는 AI 생성"** 한 줄 넣기. 기획서엔 안 되는 기능(TTS 등)을 된다고 쓰지 말고 "향후"로

**운전 방해 가이드라인** (`document.pleos.ai/.../driver-distraction-guideline`)
- `CarUxRestrictions` 확인해서 주행 중 기능 줄이기 — 지금은 `distractionOptimized=true`만 있음
- 꾸미는 움직임 줄이기 → (선택) 주행 중 핀 튕기는 애니메이션 끄기

---

## 4. 제안 (아직 안 함, 의견 줘)

1. **시연 모드를 앱 안 스위치로** — 지금 `VoiceRules`의 `DEMO_*`·`SIM_SPEED`·`SHOW_STATUS`가 `const`라 APK에 고정됨. 기본은 실제 모드, 테스트 화면(제목 길게 누르기)에서 "시연 모드 켜기" → APK 하나로 심사위원도 시연 재생 가능
2. 천안 도착 카드 문장을 **하드코딩 대신 데이터로 조립** ("작년 10월 경주 여행 때 들렀던 곳 · 메모: 호두과자…") → 영상 = 실제 기능
3. 사진 QR 실제로 뜨는지 녹화 전에 확인 (네 할 일 목록에 있던 것)
