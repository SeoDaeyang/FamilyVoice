#!/bin/bash
# 에뮬레이터 '가상 운전': 실제 도로 경로(OpenStreetMap/OSRM)를 받아 위치를 차례로 옮긴다.
# 사용법: bash scripts/drive_route.sh            (기본: 서울시청 → 덕평휴게소 근처)
#         bash scripts/drive_route.sh 0.2        (숫자가 작을수록 빨리 달림, 기본 0.4초 간격)
ADB=~/Library/Android/sdk/platform-tools/adb
FROM="126.9707,37.5547"   # 서울역 = 우리 집 (경도,위도)
TO="127.3780,37.2390"     # 덕평휴게소 근처 (경도,위도)
DELAY=${1:-0.4}
TMP=$(mktemp -d)

echo "① 실제 도로 경로 받는 중..."
curl -s "https://router.project-osrm.org/route/v1/driving/$FROM;$TO?overview=full&geometries=geojson" -o "$TMP/route.json"
if ! grep -q '"Ok"' "$TMP/route.json"; then echo "경로를 받지 못했어요. 인터넷 연결을 확인해 주세요."; exit 1; fi

# 맥 기본 JavaScript(osascript)로 약 150m마다 한 점씩 뽑기
osascript -l JavaScript -e "
ObjC.import('Foundation');
var s = \$.NSString.stringWithContentsOfFileEncodingError('$TMP/route.json', \$.NSUTF8StringEncoding, null).js;
var c = JSON.parse(s).routes[0].geometry.coordinates;
function d(a,b){var x=(b[0]-a[0])*Math.PI/180*Math.cos((a[1]+b[1])/2*Math.PI/180), y=(b[1]-a[1])*Math.PI/180; return Math.sqrt(x*x+y*y)*6371000;}
var out=[], last=null;
c.forEach(function(p){ if(!last || d(last,p) >= 150){ out.push(p[0]+' '+p[1]); last=p; } });
var e=c[c.length-1]; out.push(e[0]+' '+e[1]);
out.join('\n');" > "$TMP/points.txt"

N=$(wc -l < "$TMP/points.txt" | tr -d ' ')
echo "② 출발! 점 ${N}개를 ${DELAY}초 간격으로 이동해요 (멈추려면 Ctrl + C)"
i=0
while read -r lng lat; do
  "$ADB" emu geo fix "$lng" "$lat" < /dev/null > /dev/null
  i=$((i+1))
  if [ $((i % 20)) -eq 0 ]; then echo "   $i / $N"; fi
  sleep "$DELAY"
done < "$TMP/points.txt"
echo "③ 도착했어요!"
