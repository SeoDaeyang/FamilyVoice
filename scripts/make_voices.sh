#!/bin/bash
# 맥의 한국어 음성(Yuna)으로 차가 할 말을 음성 파일로 만든다.
# 실행: 프로젝트 폴더에서  bash scripts/make_voices.sh
set -e
OUT="app/src/main/res/raw"
mkdir -p "$OUT"

if ! say -v '?' | grep -qi '^Yuna'; then
  echo "❌ 한국어 음성 Yuna가 없어요."
  echo "   시스템 설정 → 손쉬운 사용 → 읽기 및 말하기 → 시스템 음성 → 음성 관리 → 한국어 Yuna 다운로드 후 다시 실행하세요."
  exit 1
fi

# 어떤 문장으로 만들었는지 적어 두는 파일. 문장을 고치면 그 파일만 알아서 다시 만든다 (지울 필요 없음)
STAMP="scripts/.voice_stamps"
touch "$STAMP"

make() {  # make 파일이름 "문장"   (같은 문장으로 이미 만든 파일은 건너뜀. 전부 다시 만들려면: FORCE=1 bash scripts/make_voices.sh)
  if [ -f "$OUT/$1.m4a" ] && [ -z "$FORCE" ] && grep -Fxq "$1|$2" "$STAMP"; then echo "⏭  $1.m4a (그대로)"; return; fi
  say -v Yuna -r 175 -o "/tmp/fv_$1.aiff" "$2"
  afconvert -f m4af -d aac "/tmp/fv_$1.aiff" "$OUT/$1.m4a"
  rm -f "/tmp/fv_$1.aiff"
  grep -v "^$1|" "$STAMP" > "$STAMP.tmp" || true
  echo "$1|$2" >> "$STAMP.tmp" && mv "$STAMP.tmp" "$STAMP"
  echo "✅ $1.m4a  ←  $2"
}

make v_ask_after_stop  "방금 들른 곳, 누구랑 뭐 했는지 한마디 남겨 주세요. 삐 소리가 나면 말해 주세요."
make v_saved           "좋아요. 이 장소에 잘 남겨둘게요."
make v_revisit_intro   "예전에 여기 오셨을 때, 이런 말을 남기셨어요."
make v_revisit_stop    "들렀다 갈까요?"
make v_capsule_ask     "다음에 여기 다시 오면 들려줄 말을 남겨주세요."
make v_capsule_saved   "타임캡슐에 담았어요. 다음에 여기 오면 들려드릴게요."
make v_capsule_intro   "이곳에 다시 오면 들려달라고 남긴 목소리가 있어요."
make v_same_place      "같은 곳에서 남긴 목소리를, 해마다 이어서 들려드릴게요."
make v_rain            "그날은 비가 오고 있었어요."
make v_ask_trip         "여행 중이신 것 같아요. 이번 여행, 기록해 둘까요?"
make v_trip_on          "좋아요. 이번 여행은 제가 차곡차곡 기록해 둘게요."
make v_welcome_home    "잘 다녀오셨어요. 이번 여행도 차곡차곡 남겨 뒀어요."
# 상황별 질문 (10/28 추가)
make v_q_revisit     "예전에도 여기 왔었죠. 그때랑 오늘, 뭐가 달라졌어요? 삐 소리가 나면 말해 주세요."
make v_q_rain        "비 오는 날 여행이네요. 지금 기분을 한마디로 남겨 주세요."
make v_q_long_drive  "한참 달려왔어요. 운전한 사람에게 한마디 해 주세요."
make v_q_night       "벌써 밤이에요. 오늘 하루 중 제일 좋았던 순간은요?"
make v_q_family      "다 같이 탔네요. 뒷자리에서도 한마디씩 남겨 주세요."
make v_q_first       "오늘 여행의 첫 쉼표예요. 여기 오는 길에 무슨 얘기 했어요?"
# 녹음·재생 규칙 (11/6 추가) — 지금은 VoiceRules 스위치가 꺼져 있어서 안 쓰지만, 켤 때를 위해 만들어 둔다
make v_same_trip_intro "아까 여기서, 이런 이야기를 하셨어요."
make v_not_heard       "잘 안 들렸어요. 다음에 다시 여쭤볼게요."
make v_q_best          "여기서 제일 좋았던 거, 하나만 말해 주세요."
make v_q_next          "다음에 여기 또 오면, 뭐 하고 싶어요?"

# 11/11 STT·TTS 방식: 시연에서 Pleos TTS 대신 쓰는 "차가 읽어 주는 문장" (DemoSpeech.LAST_YEAR_SENTENCE 와 글자까지 같아야 함)
make v_tts_last_year   "작년 10월, 여기 오셨을 때 이런 이야기를 남기셨어요. 호두과자 진짜 맛있다! 내년에 또 와서 사 먹자"
# 천안삼거리휴게소 3km 앞: 차가 먼저 제안 (DemoSpeech.SUGGEST_LINE / STOP_ADDED / STOP_SKIP 과 글자 하나까지 같아야 함)
make v_tts_suggest_cheonan "곧 천안삼거리휴게소예요. 작년에 여기서 호두과자가 진짜 맛있다고, 내년에 또 사 먹자고 하셨죠. 들렀다 갈까요?"
make v_stop_added "좋아요. 천안삼거리휴게소를 경유지로 넣었어요."
make v_stop_skip "알겠어요. 그냥 지나갈게요."

# 예시 장소·시연 대답을 차가 읽어 주는 소리 (scripts/demo_tts_lines.txt 한 줄 = 파일 하나)
while IFS='|' read -r n t; do
  case "$n" in ''|'#'*) continue ;; esac
  make "$n" "$t" < /dev/null
done < scripts/demo_tts_lines.txt

# 녹음 시작 신호음 (짧은 삐 소리)
python3 - "$OUT/v_beep.wav" <<'PY'
import math, struct, sys, wave
rate, sec, freq = 16000, 0.25, 1000
with wave.open(sys.argv[1], "w") as w:
    w.setnchannels(1); w.setsampwidth(2); w.setframerate(rate)
    for i in range(int(rate * sec)):
        fade = min(1.0, i / 400, (rate * sec - i) / 400)
        w.writeframes(struct.pack("<h", int(12000 * fade * math.sin(2 * math.pi * freq * i / rate))))
PY
echo "✅ v_beep.wav  ←  삐 소리"
echo "완료! Android Studio에서 ▶ 다시 실행하면 앱에 들어가요."

