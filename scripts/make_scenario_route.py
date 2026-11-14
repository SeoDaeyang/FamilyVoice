# -*- coding: utf-8 -*-
"""
시연 경로(서울역 → 천안삼거리휴게소 → 대전 성심당 → 충주호 → 집)의
실제 도로 경로를 받아 app/src/main/assets/trip_routes.json 에 "scenario" 로 넣는다.

쓰는 법 (프로젝트 폴더에서, 윈도우/맥 둘 다 됨):
    python scripts/make_scenario_route.py

- 기존 여행 경로 8개는 그대로 두고 "scenario" 키만 추가·갱신한다
- 400m마다 한 점씩 [위도, 경도] 로 저장 (앱이 읽는 형식 그대로)
- 다 되면 Android Studio 에서 Run
"""
import json, math, os, sys, urllib.request

# 경도,위도 순서 (OSRM 규칙). 가는 길은 경부선, 돌아오는 길은 충주 → 중부내륙 → 영동
HOME = "126.9707,37.5547"          # 서울역 = 집
WAYPOINTS = [
    HOME,
    "127.16290,36.79470",          # 천안삼거리휴게소 (경부고속도로 위)
    "127.42740,36.32770",          # 대전 성심당
    "128.00100,36.98800",          # 충주호
    "127.58000,37.29000",          # 돌아오는 길 (중부내륙 → 영동) 한 점 — 갔던 길로 안 돌아오게
    HOME,
]
URL = ("https://router.project-osrm.org/route/v1/driving/"
       + ";".join(WAYPOINTS) + "?overview=full&geometries=geojson")

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "app", "src", "main", "assets", "trip_routes.json")


def meters(a, b):
    x = math.radians(b[0] - a[0]) * math.cos(math.radians((a[1] + b[1]) / 2))
    y = math.radians(b[1] - a[1])
    return math.hypot(x, y) * 6371000


def main():
    print("① 실제 도로 경로 받는 중…")
    try:
        with urllib.request.urlopen(URL, timeout=60) as r:
            data = json.load(r)
    except Exception as e:
        print("   실패:", e)
        print("   인터넷이 막혀 있으면 잠시 뒤 다시 해 보세요 (공용 서버라 가끔 느려요).")
        sys.exit(1)
    if data.get("code") != "Ok":
        print("   실패:", data.get("code"), data.get("message", ""))
        sys.exit(1)

    coords = data["routes"][0]["geometry"]["coordinates"]        # [경도, 위도]
    km = sum(meters(coords[i - 1], coords[i]) for i in range(1, len(coords))) / 1000

    pts, last = [], None
    for p in coords:                                             # 400m마다 한 점
        if last is None or meters(last, p) >= 400:
            pts.append([round(p[1], 5), round(p[0], 5)])         # [위도, 경도]
            last = p
    e = coords[-1]
    pts.append([round(e[1], 5), round(e[0], 5)])

    out = {}
    if os.path.exists(OUT):
        with open(OUT, encoding="utf-8") as f:
            out = json.load(f)
    out["scenario"] = pts
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, "w", encoding="utf-8") as f:
        json.dump(out, f, ensure_ascii=False, separators=(",", ":"))

    print(f"② 저장했어요: {os.path.normpath(OUT)}")
    print(f"   scenario  {round(km)}km  {len(pts)}점  (다른 여행 {len(out) - 1}개는 그대로)")
    print("③ Android Studio 에서 Run 하면 실제 도로를 따라 그려져요.")


if __name__ == "__main__":
    main()
