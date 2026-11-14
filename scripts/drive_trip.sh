#!/bin/bash
# 에뮬레이터 '가상 여행' (맥 전용) — 시연 영상용 경주 여행 (11/7 대본 v2)
#   서울역(집) → [김천휴게소] → 경주 황리단길(점심) → 대릉원·첨성대 → (영천·상주 거쳐) → 서울역(집)
# 김천휴게소는 작년 경주 여행 때 목소리를 남긴 곳 → 1km 앞에서 그 목소리가 나온다 (핵심 장면).
# 돌아오는 길은 중부내륙(영천·상주)으로 올라와 김천을 다시 지나지 않는다.
# 대릉원 쪽 정차는 첨성대 근처로: 황리단길에서 300m 안이면 "이미 녹음한 곳"이라 질문을 안 하기 때문.
# 예전에 멈춘 곳 1.5km 안에서는 천천히 달린다 (앱이 1초마다 위치를 보니까, 그래야 지나칠 때 놓치지 않음).
# 실제 도로 경로(OpenStreetMap/OSRM)를 받아 에뮬레이터 위치를 차례로 옮기고,
# 들르는 곳마다 멈춰서 기다린다. 그때 가상 콘솔에서 기어를 P → D 로 바꾸고 Enter.
#
# 아무것도 없는 구간은 점을 건너뛰어 빨리 지나가고, 예전에 들른 곳 1.5km 안에서는 300m마다 천천히 간다.
# → 서울역에서 김천휴게소(작년 목소리)까지 약 15초.
#
# 사용법: bash scripts/drive_trip.sh              빠르게 (테스트용, 기본)
#         bash scripts/drive_trip.sh 0.15 1       천천히·촘촘하게 (영상 찍을 때. 지도 선이 예쁘게 이어짐)
#         bash scripts/drive_trip.sh <점당 초> <건너뛸 점 수>
# 가상 콘솔(기어 바꾸기): adb forward tcp:8088 tcp:8088 → 브라우저 http://127.0.0.1:8088/
ADB=~/Library/Android/sdk/platform-tools/adb
DELAY=${1:-0.05}     # 아무것도 없는 구간에서 점 하나에 머무는 시간(초)
FAR_SKIP=${2:-6}     # 아무것도 없는 구간은 점 이만큼에 하나만 찍는다 (300m × 6 = 1.8km). 1이면 다 찍음
SPACING=300          # 점 간격(m). 재방문 판단 범위(300m)보다 촘촘하게
SLOW=1.2             # 예전에 멈춘 곳 1.5km 안에서는 점 하나에 이만큼(초) 머문다 (앱이 놓치지 않게)

# 장소 (경도,위도)
HOME_PT="126.9707,37.5547"      # 서울역 = 우리 집
HWANG="129.2100,35.8370"        # 경주 황리단길 (점심) — 작년 쌈밥집(e2) 자리
CHEOM="129.2185,35.8350"        # 경주 대릉원·첨성대 (황리단길에서 약 800m)
# 휴게소: 경로 위에서 가장 가까운 지점에 멈춘다.
# 좌표는 Journal.kt 의 e1(작년 경주 여행 김천휴게소)과 같아야 작년 목소리가 나온다.
GIMCHEON="128.2589,36.1614"     # 경부고속도로 김천휴게소
# 돌아올 때 거쳐 갈 곳 (안 멈춤). 김천을 피해 중부내륙으로 올라온다
YEONGCHEON="128.9386,35.9733"   # 영천
SANGJU="128.1590,36.4109"       # 상주

# 구간: 출발|도착|중간에 들를 휴게소 이름|휴게소 좌표|도착지 이름|거쳐 갈 곳(안 멈춤, 여러 개면 ;로)
LEGS=(
  "$HOME_PT|$HWANG|김천휴게소|$GIMCHEON|경주 황리단길|"
  "$HWANG|$CHEOM|||대릉원·첨성대|"
  "$CHEOM|$HOME_PT|||서울역 (우리 집)|$YEONGCHEON;$SANGJU"
)

TMP=$(mktemp -d)
cat > "$TMP/pts.js" <<'JS'
ObjC.import('Foundation');
function d(a, b) {
  var x = (b[0] - a[0]) * Math.PI / 180 * Math.cos((a[1] + b[1]) / 2 * Math.PI / 180), y = (b[1] - a[1]) * Math.PI / 180;
  return Math.sqrt(x * x + y * y) * 6371000;
}
function run(argv) {
  var file = argv[0], spacing = parseFloat(argv[1]), midName = argv[2], midPt = argv[3], endName = argv[4];
  var seen = (argv[5] || '').split(';').filter(function (x) { return x; }).map(function (x) { return x.split(',').map(parseFloat); });
  var s = $.NSString.stringWithContentsOfFileEncodingError(file, $.NSUTF8StringEncoding, null).js;
  var c = JSON.parse(s).routes[0].geometry.coordinates;
  var km = 0; for (var i = 1; i < c.length; i++) km += d(c[i - 1], c[i]);
  var pts = [], last = null;
  c.forEach(function (p) { if (!last || d(last, p) >= spacing) { pts.push(p); last = p; } });
  var e = c[c.length - 1]; if (pts[pts.length - 1] !== e) pts.push(e);
  var stopAt = -1, stopDist = 0;
  if (midName) {
    var m = midPt.split(',').map(parseFloat), best = 1e18;
    pts.forEach(function (p, i) { var dd = d(p, m); if (dd < best) { best = dd; stopAt = i; } });
    stopDist = best;
  }
  var out = ['K|' + Math.round(km / 1000) + '|' + pts.length];
  pts.forEach(function (p, i) {
    var slow = seen.some(function (q) { return d(p, q) <= 1500; });
    out.push((slow ? 'Q ' : 'P ') + p[0] + ' ' + p[1]);
    if (i === stopAt) out.push('S|' + midName + '|' + (stopDist / 1000).toFixed(1) + '|' + p[0] + ',' + p[1]);
  });
  out.push('S|' + endName + '|0|' + e[0] + ',' + e[1]);
  return out.join('\n');
}
JS

echo "① 실제 도로 경로 받는 중..."
: > "$TMP/all.txt"
n=0
SEEN="128.2589,36.1614;"      # 지금까지 멈춘 곳들 (경도,위도;…). 김천휴게소(작년 경주 여행 목소리)는 처음부터 천천히
for leg in "${LEGS[@]}"; do
  IFS='|' read -r FROM TO MIDNAME MIDPT ENDNAME VIA <<< "$leg"
  n=$((n+1))
  PTS="$FROM;$TO"; [ -n "$VIA" ] && PTS="$FROM;$VIA;$TO"
  curl -s "https://router.project-osrm.org/route/v1/driving/$PTS?overview=full&geometries=geojson" -o "$TMP/leg$n.json"
  if ! grep -q '"Ok"' "$TMP/leg$n.json"; then echo "   $n구간 경로를 받지 못했어요. 인터넷 연결을 확인해 주세요."; exit 1; fi
  osascript -l JavaScript "$TMP/pts.js" "$TMP/leg$n.json" "$SPACING" "$MIDNAME" "$MIDPT" "$ENDNAME" "$SEEN" > "$TMP/leg$n.txt"
  cat "$TMP/leg$n.txt" >> "$TMP/all.txt"
  echo >> "$TMP/all.txt"
  SEEN="$SEEN$(grep '^S|' "$TMP/leg$n.txt" | cut -d'|' -f4 | tr '\n' ';')"
  sleep 1   # 공용 서버라 너무 빨리 연달아 부르지 않기
done

# 구간 요약
grep '^K|' "$TMP/all.txt" | awk -F'|' '{ printf "   %d구간: %s km\n", NR, $2; t += $2 } END { printf "   합계 약 %d km\n", t }'
grep '^S|' "$TMP/all.txt" | awk -F'|' '$3 > 2.0 { printf "   ⚠ %s: 경로에서 %s km 떨어져 있어서 가장 가까운 지점에 멈춰요\n", $2, $3 }'

# 출발 위치로
IFS=',' read -r HLNG HLAT <<< "$HOME_PT"
"$ADB" emu geo fix "$HLNG" "$HLAT" < /dev/null > /dev/null
echo
echo "② 지금 서울역(우리 집)이에요. 앱에서 할 거 하고(예: 여행 시작),"
read -r -p "   기어를 D로 바꾼 다음 Enter 를 누르면 출발해요 (멈추려면 Ctrl + C) " _ < /dev/tty

if [ "$FAR_SKIP" -gt 1 ]; then
  echo "⚡ 빠른 모드: 먼 구간은 점 ${FAR_SKIP}개에 하나만 찍어요 (지도 선이 듬성듬성해집니다)"
  echo "   영상 찍을 땐: bash scripts/drive_trip.sh 0.15 1"
  echo
fi

i=0
far=0
pending_pt=""
while IFS= read -r line; do
  case "$line" in
    P\ *)
      # 아무것도 없는 구간 → 몇 개에 하나만 찍는다 (건너뛴 점은 도착할 때 쓰려고 기억해 둔다)
      far=$((far+1))
      if [ "$FAR_SKIP" -gt 1 ] && [ $((far % FAR_SKIP)) -ne 0 ]; then pending_pt="$line"; continue; fi
      set -- $line
      "$ADB" emu geo fix "$2" "$3" < /dev/null > /dev/null
      pending_pt=""
      i=$((i+1)); slowing=0
      if [ $((i % 50)) -eq 0 ]; then echo "   … 달리는 중 ($i 점)"; fi
      sleep "$DELAY"
      ;;
    Q\ *)
      # 예전에 들른 곳 1.5km 안 → 하나도 안 건너뛰고 천천히 (여기서 작년 목소리가 나온다)
      far=0
      set -- $line
      "$ADB" emu geo fix "$2" "$3" < /dev/null > /dev/null
      pending_pt=""
      i=$((i+1))
      if [ "$slowing" != 1 ]; then echo "   🐢 예전에 들른 곳 근처라 천천히…"; slowing=1; fi
      sleep "$SLOW"
      ;;
    S\|*)
      # 건너뛴 점이 남아 있으면 도착 지점에 정확히 서도록 한 번 더 찍는다
      if [ -n "$pending_pt" ]; then
        set -- $pending_pt
        "$ADB" emu geo fix "$2" "$3" < /dev/null > /dev/null
        pending_pt=""
        sleep 0.5
      fi
      name=$(echo "$line" | cut -d'|' -f2)
      echo
      echo "📍 $name 도착"
      if [ "$name" = "서울역 (우리 집)" ]; then
        echo "   기어를 P로 바꾸면 여행이 마무리돼요. 끝!"
        break
      fi
      read -r -p "   기어를 P로 → (앱 확인) → 다시 D로 바꾼 다음 Enter " _ < /dev/tty
      ;;
  esac
done < "$TMP/all.txt"
