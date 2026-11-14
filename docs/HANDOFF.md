# FamilyVoice 인수인계 문서 (다른 Claude용)

> 이 문서 하나만 읽으면 이어서 작업할 수 있게 정리했어요. 작성: 2026-11-04
> Claude Code에서 쓸 거면 이 파일을 프로젝트 맨 위에 `CLAUDE.md`로 복사하면 자동으로 읽어요.

---

## 0. 꼭 지킬 규칙 (사용자: 대양)

1. **답변은 무조건 한국어.** 영어로 답하면 화를 냄. 설명은 쉽게, 짧게.
2. 대양은 안드로이드/코틀린 경험이 거의 없음. **코드는 Claude가 짜고, 대양은 Run 눌러서 테스트**하는 방식.
   - "어디를 누르세요"처럼 Android Studio 화면 기준으로 안내할 것.
3. **비밀키 절대 노출 금지**
   - `local.properties` 안의 `pleos.clientId`, `pleos.clientSecret` 값은 채팅에 쓰지도, 출력하지도, 커밋하지도 말 것.
   - `local.properties`는 `.gitignore`에 들어가 있음 (확인 완료).
4. **실명 금지**: 공모전 제출물(기획서, GitHub, README, 커밋)에 실명이 들어가면 안 됨.
5. 에뮬레이터에서 **Wipe Data, Android Studio의 Reset Settings는 누르지 말 것.**
6. 하루 작업 시간이 적음(사회복무요원). 한 번에 하나씩, 확인 가능한 단위로 진행.

---

## 1. 무슨 앱인가

- **공모전**: 현대자동차그룹 차량용 앱 개발 공모전 (Pleos Playground, Android Automotive)
- **컨셉**: "달리는 타임캡슐" — **차가 묻고, 차가 기억하고, 차가 들려준다**
  - 가족 여행 중 정차할 때 차가 상황에 맞는 질문 → 가족 목소리 녹음 → 그 장소(위치)에 저장
  - 나중에 그 근처를 다시 지나가면 그때 목소리를 다시 들려줌
  - 차별점: "사진에는 도착한 곳만 남는다. 우리는 **가는 길**을 남긴다." 손 안 쓰고(핸즈프리), 차가 타이밍을 앎, 가족이 함께
- **앱 이름 후보**: 차곡(1순위 추천, 차 + 차곡차곡), 길소리, 다시 이 길 … **아직 미정**. 코드상 이름은 `FamilyVoice`
- **팀**: 대양(맥) + 친구(윈도우, GitHub 협업자 `icheonold1-alt`)

---

## 2. 경로·환경

| 항목 | 값 |
|---|---|
| 프로젝트 폴더 (대양 맥) | `/Users/daeyangs/AndroidStudioProjects/FamilyVoice` |
| 패키지 / applicationId | `com.familyvoice.app` |
| 소스 폴더 | `app/src/main/java/com/familyvoice/app/` |
| GitHub | https://github.com/SeoDaeyang/FamilyVoice (비공개, 브랜치 `main`) |
| 최근 커밋 | `6e9ba50` (그 전 `b2402ae`) — 둘 다 메시지가 장난이라 제출 전 정리 필요 |
| 맥 adb | `~/Library/Android/sdk/platform-tools/adb` |
| 에뮬레이터 | Pleos Connect v2.1.0, API 34, arm64 (Device Manager에서 실행) |
| 윈도우용 이미지 주소 | `https://nexus-playground.pleos.ai/repository/raw-releases/connect-avd/2.x/crp-sys-img.xml` |
| Pleos maven | `https://nexus-playground.pleos.ai/repository/maven-releases/` (settings.gradle.kts에 등록됨) |

**빌드 설정**: AGP 9.4.1, Kotlin 2.2.10, Compose BOM 2026.02.01, compileSdk/targetSdk 37, minSdk 28, Java 11

**의존성** (`gradle/libs.versions.toml`)
- Pleos: Vehicle 2.3.2, TextToSpeech / SpeechToText / NaviHelper / FusedLocation / LLM / placesense (모두 `+`)
  - 받아진 버전(참고): TTS 3.3.1, STT 3.3.1, NaviHelper 3.0.5, FusedLocation 1.1.3, LLM 2.1.3.2
  - placesense는 실제로 받아지는 AAR이 없음 (빼도 됨)
- 지도: MapLibre `org.maplibre.gl:android-sdk:11.+` + OpenFreeMap positron 스타일 (`https://tiles.openfreemap.org/styles/positron`)

**local.properties** (깃에 안 올라감, 각자 만들어야 함)
```
sdk.dir=...
pleos.clientId=(Playground 프로젝트 화면의 Client ID)
pleos.clientSecret=(Client Secret)
```
→ `app/build.gradle.kts`가 읽어서 `BuildConfig.PLEOS_CLIENT_ID / PLEOS_CLIENT_SECRET`으로 넣음.

---

## 3. 파일 지도 (무슨 파일이 뭘 하나)

### 코드 (`app/src/main/java/com/familyvoice/app/`)

| 파일 | 줄 수 | 역할 |
|---|---|---|
| `MainActivity.kt` | ~574 | **앱의 두뇌.** Vehicle SDK 연결(기어·주행거리·주행시간·와이퍼·좌석), 위치 받기, 정차→질문→녹음 흐름, 재방문 재생, 여행 기록 여부 묻기, 테스트(디버그) 화면 |
| `HomeScreen.kt` | ~944 | **메인 화면.** 지도(MapLibre), 왼쪽 패널, 위쪽 칩(전체·여행·음식점·관광지·휴게소), 폴라로이드 핀, 지나온 길 그리기, 녹음/재방문 오버레이 |
| `JournalUi.kt` | ~325 | 칩 탭(여행·음식점·관광지·휴게소) 화면: 여행 타임라인, 여행 상세(날씨·거리·운전시간·인원·들른 곳), 장소 카드, 떨어지는 핀 애니메이션 |
| `Journal.kt` | ~104 | **시연용 예시 데이터** (가상 가족): 여행 3개(부산 2026-09-03, 강릉 2025-08-14, 창원 2025-08-04), 장소 12곳 |
| `TripPolicy.kt` | ~78 | "오늘 기록할지" 판단: 집 위치, 특별한 여행 신호(집에서 30km↑, 처음 온 곳, 2명↑ 탑승, 주말), 오늘 대답 저장 |
| `MemoryStore.kt` | ~56 | 목소리 기억 저장: `filesDir/memories.json` + `filesDir/memory_<id>.m4a`. `Memory(id, fileName, rainy, peak, lat, lng, question)` |
| `RouteStore.kt` | ~76 | 지나온 길 저장: `filesDir/routes/yyyyMMdd.json`, 30m마다 한 점 |
| `LocationTracker.kt` | ~47 | 위치 받기 + `distanceM()` 거리 계산 |
| `VoiceTester.kt` | ~195 | 녹음(말 끝나면 자동 멈춤) / 재생 |
| `PromptPlayer.kt` | ~49 | `res/raw`의 안내 음성 파일들을 차례로 재생 |
| `PleosVoice.kt` | ~147 | Pleos TTS/STT 연결 코드 (**지금은 서버 권한 때문에 막힘**, 6장 참고) |
| `ui/theme/*` | | 기본 테마 (거의 안 씀) |

### 리소스 (`app/src/main/res/`)
- `raw/` : 차가 하는 말 (맥 Yuna 음성으로 만든 m4a). `v_ask_trip`, `v_ask_after_stop`, `v_q_revisit / rain / long_drive / night / family / first`, `v_revisit_intro / stop`, `v_saved`, `v_trip_on`, `v_beep.wav`, `v_capsule_*`(타임캡슐용, 아직 코드에서 안 씀), `v_welcome_home`(귀가 인사용, 아직 안 씀), `v_same_place`, `v_rain`
- `drawable-nodpi/` : 시연용 사진 7장 `demo_family, demo_rest, demo_kids, demo_beach, demo_rain, demo_sunset, demo_rest_grandma` (Gemini로 생성, 480×480)
- `font/` : Pretendard(기본 글꼴), Nanum Pen Script(손글씨), Gowun Batang(지금은 거의 안 씀)
- 앱 아이콘: `mipmap-anydpi/ic_launcher(_round).xml` = 배경 `@color/icon_bg`(#F4ECDC) + 전경 `mipmap-xxxhdpi/ic_launcher_art.png`(폴라로이드)

### 스크립트 (`scripts/`, 맥 전용)
- `make_voices.sh` : 맥 `say -v Yuna`로 `res/raw/*.m4a` 생성. 있는 파일은 건너뜀, 다 새로 만들려면 `FORCE=1 bash scripts/make_voices.sh`. 멈추면 `killall SpeechSynthesisServer`
- `drive_route.sh` : **가상 운전.** OSRM에서 실제 도로 경로(서울시청→덕평휴게소)를 받아 150m마다 `adb emu geo fix`. `bash scripts/drive_route.sh 0.2` (숫자 작을수록 빠름)
- `make_cover.py` : 폴라로이드 커버/아이콘 이미지 재생성 (PIL)

### 기타
- `docs/brand/` : `cover_polaroid_1024.png`, `app_icon_pin_1024.png`

---

## 4. 지금 앱이 도는 방식 (MainActivity 기준)

| 언제 | 감지 | 동작 |
|---|---|---|
| 앱을 켰을 때만 | — | 시동 연동 자동 실행은 아직 없음 |
| 위치가 바뀔 때 | 위치 | 오늘 "기록 안 함"이 아니면 길을 모음 (`RouteStore`) |
| 오늘 첫 P | 기어 + 위치 + 좌석 + 요일 | 특별한 여행이면 "오늘 기록할까요?" 카드 (하루 1번, `TripPolicy`) |
| P로 5초↑ 있다가 D | 기어 | `pickQuestion()` 상황별 질문 → 삐 → 자동 녹음 → 저장 |
| 예전 기억 300m 안 | 위치 | 그때 목소리 재생 (`v_revisit_intro` → 녹음 → `v_revisit_stop`), 40초 안전 타이머 |

- 질문 우선순위: 다시 온 곳 > 비(와이퍼) > 오래 운전 > 밤(19~5시) > 3명↑ 탑승 > 오늘 첫 정차 > 기본
- 시연용 숫자 (실제 서비스 값은 괄호): 정차 5초(몇 분), 장거리 2분(1시간 30분), 정차 판단 10초(15분), 집에서 30km
- 지도: 가장 최근 날 경로는 들른 곳마다 색이 바뀜(`LEG_COLORS`), 3km 넘게 순간이동한 구간은 끊어서 그림
- 지도 조작: +/− 버튼, **마우스 우클릭 = 축소**

### 🔶 아직 결정 안 된 것 (대양에게 물어본 상태, 답 없음)
하루 흐름을 5단계로 정리하자고 제안함:
① 대기(시동 ON → 앱 자동 실행, 길만 모음) → ② 여행 시작(집에서 30km↑ / 하이패스 진입 / 버튼) → ③ 쉬는 곳(P + 정차 후 **문이 다 닫히면** 출발 전에 질문·녹음) → ④ 달리는 중(속도>0이면 **소리만**, 작은 배너, "들렀다 갈까요?" 제안) → ⑤ 도착·귀가(집 근처 + P → 인사 + 여행 마감 → 타임라인 추가)

대양이 정할 것 3가지 (각각 A가 추천):
1. 질문 타이밍: (A) 다시 타서 문 다 닫혔을 때 / (B) 주차 직후 / (C) 지금처럼 D 넣을 때
2. 여행 시작: (A) 자동 감지 + 수동 버튼 / (B) 버튼만
3. 여행 끝: (A) 집 도착 시 자동 마감 / (B) 날짜 바뀌면 마감

---

## 5. 에뮬레이터 테스트 방법

- **실행**: Android Studio 위쪽 기기 선택 `Pleos Connect v2.1.0` → ▶ Run
- **가상 콘솔(기어·속도·와이퍼·하이패스 등 바꾸기)**:
  ```
  adb forward tcp:8088 tcp:8088
  ```
  → 브라우저에서 http://127.0.0.1:8088/
- **위치 한 번 옮기기**: `adb emu geo fix <경도> <위도>` (경도 먼저!)
- **가상 운전**: `bash scripts/drive_route.sh` (에뮬레이터 Routes 기능은 한국 경로를 못 찾아서 "Route Not Found" 뜸 → 이 스크립트 사용)
- **앱 데이터 초기화**: `adb shell pm clear --user current com.familyvoice.app`
- **상황별 질문 테스트**: 가상 콘솔에서 P → 5초 기다림 → D
- **재방문 테스트**: 녹음한 곳에서 멀어졌다가 다시 300m 안으로 위치 이동
- 경로가 안 그려지면: "오늘은 괜찮아요"를 눌러서 기록 안 하는 날이 된 경우 → 데이터 초기화 또는 [오늘 여행 기록하기] 버튼
- 오른쪽 위 **테스트 화면** 버튼 → SDK 상태, 하루 코스, Pleos 음성 테스트 버튼

---

## 6. Pleos SDK 상태

| SDK | 상태 | 우리 사용 |
|---|---|---|
| Vehicle (상태 읽기) | ✅ 사용 가능 | 기어, 주행거리, 주행시간, 와이퍼, 좌석 착석 |
| NaviHelper | ✅ 사용 가능 | 라이브러리만 넣음, **아직 안 씀** (addWaypoint, requestRoute, onWayPointArrived, onDestinationArrived 등) |
| TextToSpeech / SpeechToText | ⛔ 준비 중 | 코드 완성(`PleosVoice.kt`), 서버가 `HTTP 401 Unauthorized` |
| FusedLocation, 차량 제어 | ⛔ 준비 중 | 안 씀 |

**TTS/STT 막힌 이유 (확인 완료, 우리 코드 문제 아님)**
- 순서: `TextToSpeech(ctx, Mode)` → `initialize` → 성공 후 `addEventListener`, `setLocale` → `registerApp(clientId, clientSecret, …)` → `speak(text, true)`
- registerApp까지는 됨. speak/request 시 서버 `checkTokenValidity`에서 401 → 프로젝트에 TTS/STT 권한이 아직 안 열림
- 서버 실패 후 SDK가 on-device로 재시도하지만 에뮬레이터엔 엔진이 없어서 `ON_DEVICE_ENGINE_ERROR` → **ON_DEVICE 모드로 바꿔도 소리 안 남**
- 대신 차 목소리는 `res/raw`의 Yuna 녹음 파일로 나오고 있어서 시연엔 문제없음
- 할 일: Playground(https://pleos.ai/playground) → My Project → 프로젝트 → 왼쪽 SDK에서 TTS/STT/LLM 상태 확인

**공식 안내 요약**: 주행 중 화면 제한(`CarUxRestrictions`) 지켜야 함, 차종별 지원이 달라서 `checkXXXCapabilities`/`isSupported`로 확인 권장.
문서: https://document.pleos.ai/en/api-reference/connect-sdk-pleos/

---

## 7. 디자인 규칙

- 1280 폭 기준으로 설계, `HomeScreen`이 화면 폭에 맞게 Density를 조정
- 색 (`object Fv` in HomeScreen.kt): Ink `#22303C`, Blue `#2F5D8A`, Dusty `#6E8FA8`, Sand `#B09A74`, 지도 땅 `#ECE8DF`, 물 `#D5E0E8`
- 구간 색 `LEG_COLORS`: `#2F5D8A, #C9853A, #4E8C7A, #8A6FB0, #C2604F`
- 장소 종류 색: 음식점 `#C9853A`, 관광지 `#4E8C7A`, 휴게소 `#2F5D8A`
- 느낌: 흐린 실제 지도 + 필름/폴라로이드 앨범, 푸른 계열, CarPlay 같은 산세리프(Pretendard)

---

## 8. 남은 일 (우선순위)

**공모전 일정**: 1차 마감 **11/15(일) 23:59** (목표 11/13) → 11/23 발표 → 12/3~4 PT(UX Studio Seoul, 에뮬레이터 시연) → 12/18 최종

### 필수 (1차 심사)
- [ ] 앱 이름·팀명 결정
- [ ] 기획서(공식 DOCX 양식) — 익명, 실명·연락처·소속 금지. 심사 기준: 차량특화성 / 창의성 / 기술 활용성(Pleos SDK) / 사업성
- [ ] 팀원 각자 서명한 동의서 (CC로 대체 불가)
- [ ] 메일 `appdevchallenge@hyundai-partners.com`, 제목 `[차량용 앱 개발 공모전] 팀명_대표자명`. 재제출은 제목 앞 `[수정제출]`

### 앱
- [ ] 카테고리/여행 화면(`Journal*.kt`) Run 확인 — **아직 빌드 테스트 안 함**
- [ ] 상황별 질문 실제 테스트
- [ ] 4장의 5단계 흐름 확정 후 코드 정리
- [ ] SDK 더 쓰기 (추천 순서): ① 속도 + 주행 중 화면 단순화 ② 연료/배터리 + NaviHelper `addWaypoint` "들렀다 갈까요?" ③ NaviHelper 경유지 도착 → 장소 자동 기록 ④ 목적지 도착 + 문 → 도착 인사·여행 마감 ⑤ 바깥 온도·와이퍼·전조등으로 여행 날씨 자동 채우기 ⑥ 좌석으로 인원 ⑦ 하이패스 진입으로 여행 시작 감지
  - 정확한 메서드 이름은 받아진 AAR에서 확인 후 작성할 것 (문서엔 영역 이름만 있음)
- [ ] 타임캡슐 ("1년 뒤 여기 오면 들려줘" — 날짜가 아니라 **장소 도착**이 조건), 음성 파일 `v_capsule_*` 준비돼 있음
- [ ] 음식점 사진 3장(국밥·순두부·아구찜) Gemini로 만들어 `drawable-nodpi`에 추가 후 `Journal.kt`의 `photo`에 연결

### 가산점
- [ ] 시연 영상 (가상 주행 → 질문 → 녹음 → 재방문 재생 → 여행 타임라인)
- [ ] GitHub: README(앱 이름, 한 줄 소개, 실행 방법, 테스트 환경, APK 위치), release APK를 `apk/팀명_앱이름_release.apk`로, 실명 없는 계정으로 이전 + 심사용 계정 초대, 커밋 메시지 정리
- [ ] PT 대비 "코드 지도" 문서 (AI 사용 허용, 대신 팀이 코드 구조를 설명할 수 있어야 함)

---

## 9. 알려진 문제·주의

- Android Studio 시작 시 "Start Failed" NPE → `pkill -f "Android Studio"` 후 다시 켜기 (Reset Settings 누르지 말 것)
- `say`가 중간에 멈추면 `killall SpeechSynthesisServer`
- 커밋 창에서 **Unversioned Files도 체크**해야 새 파일이 올라감 (안 하면 친구 쪽 빌드 깨짐)
- "21 warnings"는 노란 경고일 뿐 에러 아님
- 윈도우(친구): 줄바꿈 CRLF 경고 나올 수 있음. 스크립트(`.sh`)는 맥 전용
