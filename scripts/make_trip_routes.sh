#!/bin/bash
# 예시 여행 8개의 "실제 고속도로 경로"를 받아 앱 안에 저장한다 (맥 전용, 한 번만 돌리면 됨)
#   → app/src/main/assets/trip_routes.json
# 앱은 이 파일이 있으면 직선 대신 이 경로를 그린다. 다 받은 뒤 Android Studio 에서 Run.
# 사용법: bash scripts/make_trip_routes.sh
cd "$(dirname "$0")/.." || exit 1
OUT=app/src/main/assets/trip_routes.json
TMP=$(mktemp -d)

# 여행 id | 거쳐 갈 곳 (경도,위도;…)
# 집 → 들른 곳 전부(방문 순서) → 돌아오는 길 고속도로 위 한 점 → 집
#  - 들른 곳을 다 거쳐서, 지도에서 선이 핀을 정확히 지나간다
#  - 휴게소·돌아오는 길 점은 고속도로 위 좌표라 시내로 빠졌다 U턴하지 않는다
#  - 돌아오는 길 점 덕분에 가는 길과 다른 고속도로로 돌아온다
HOME_PT="126.9707,37.5547"   # 서울역 = 우리 집
TRIPS=(
  # 부산: 집 → (경부고속도로 하행선 한 점) → 칠곡휴게소 → 해운대 해수욕장 → 돼지국밥집 → 감천문화마을 → 광안대교 야경 드라이브 → (돌아오는 길 고속도로 한 점) → 집
  "busan|$HOME_PT;127.76547,36.26781;128.42839,35.98465;129.16040,35.15870;129.04080,35.11530;129.01060,35.09750;129.11870,35.15320;128.22138,36.32557;$HOME_PT"
  # 강릉: 집 → 덕평휴게소 → 안목해변 → 초당순두부 → (돌아오는 길 고속도로 한 점) → 집
  "gangneung|$HOME_PT;127.37440,37.24050;128.94720,37.77240;128.91500,37.79100;128.05275,37.75397;$HOME_PT"
  # 창원: 집 → 문경휴게소 → 마산 아구찜 골목 → 용지호수공원 → 진해 경화역 → (돌아오는 길 고속도로 한 점) → 집
  "changwon|$HOME_PT;128.11129,36.70097;128.57800,35.21200;128.68400,35.22600;128.69200,35.15300;127.72602,36.27450;$HOME_PT"
  # 가평: 집 → 가평휴게소 → 남이섬 → 가평 잣두부집 → (돌아오는 길 고속도로 한 점) → 집
  "gapyeong|$HOME_PT;127.42994,37.64943;127.52500,37.79100;127.51000,37.82500;127.17215,37.54650;$HOME_PT"
  # 전주: 집 → 정안알밤휴게소 → 전주 한옥마을 → 전주 비빔밥집 → (돌아오는 길 고속도로 한 점) → 집
  "jeonju|$HOME_PT;127.11401,36.57357;127.15300,35.81500;127.14600,35.81800;127.39740,37.27229;$HOME_PT"
  # 속초: 집 → 내린천휴게소 → 속초해수욕장 → 속초 중앙시장 닭강정 → (돌아오는 길 고속도로 한 점) → 집
  "sokcho|$HOME_PT;128.33156,37.93989;128.60000,38.19000;128.59000,38.20400;128.05503,37.44837;$HOME_PT"
  # 경주: 집 → 김천휴게소 → 황리단길 쌈밥집 → 동궁과 월지 → 불국사 → (돌아오는 길 고속도로 한 점) → 집
  "gyeongju|$HOME_PT;128.25892,36.16137;129.21000,35.83700;129.22700,35.83400;129.33200,35.79000;128.53561,36.84813;$HOME_PT"
  # 태안: 집 → 행담도휴게소 → 만리포해수욕장 → 태안 꽃게탕집 → (돌아오는 길 고속도로 한 점) → 집
  "taean|$HOME_PT;126.78989,36.94233;126.14300,36.78700;126.29800,36.75200;127.18333,36.95393;$HOME_PT"
)

echo "① 실제 도로 경로 받는 중..."
IDS=""
for t in "${TRIPS[@]}"; do
  ID="${t%%|*}"; PTS="${t#*|}"
  curl -s "https://router.project-osrm.org/route/v1/driving/$PTS?overview=full&geometries=geojson" -o "$TMP/$ID.json"
  if grep -q '"Ok"' "$TMP/$ID.json"; then echo "   $ID ✓"; IDS="$IDS $ID"; else echo "   $ID ✗ (건너뜀)"; fi
  sleep 1   # 공용 서버라 너무 빨리 연달아 부르지 않기
done

cat > "$TMP/build.js" <<'JS'
ObjC.import('Foundation');
function d(a, b) {
  var x = (b[0] - a[0]) * Math.PI / 180 * Math.cos((a[1] + b[1]) / 2 * Math.PI / 180), y = (b[1] - a[1]) * Math.PI / 180;
  return Math.sqrt(x * x + y * y) * 6371000;
}
function read(f) { return $.NSString.stringWithContentsOfFileEncodingError(f, $.NSUTF8StringEncoding, null).js; }
function run(argv) {
  var dir = argv[0], ids = argv.slice(1), out = {}, info = [];
  ids.forEach(function (id) {
    var c = JSON.parse(read(dir + '/' + id + '.json')).routes[0].geometry.coordinates;
    var pts = [], last = null, km = 0;
    for (var i = 1; i < c.length; i++) km += d(c[i - 1], c[i]);
    c.forEach(function (p) { if (!last || d(last, p) >= 400) { pts.push([+p[1].toFixed(5), +p[0].toFixed(5)]); last = p; } });  // 400m마다 [위도, 경도]
    var e = c[c.length - 1]; pts.push([+e[1].toFixed(5), +e[0].toFixed(5)]);
    out[id] = pts;
    info.push(id + ' ' + Math.round(km / 1000) + 'km ' + pts.length + '점');
  });
  return JSON.stringify(out) + '\n#INFO ' + info.join(' | ');
}
JS

mkdir -p "$(dirname "$OUT")"
# shellcheck disable=SC2086
RES=$(osascript -l JavaScript "$TMP/build.js" "$TMP" $IDS)
echo "$RES" | grep -v '^#INFO' > "$OUT"
echo "② 저장했어요: $OUT"
echo "$RES" | grep '^#INFO' | sed 's/^#INFO //' | tr '|' '\n' | sed 's/^ */   /'
echo "③ 이제 Android Studio 에서 Run 하면 실제 경로로 그려져요."
