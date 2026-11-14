#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
장소 사진 줄이기: 큰 사진(png/jpg/webp)을 480x480 정사각형 jpg, 200KB 이하로 만들어
app/src/main/res/drawable-nodpi/ 에 넣는다.

사용법 (프로젝트 폴더에서):
    python scripts/shrink_photos.py <원본 사진 폴더>
    예) python scripts/shrink_photos.py C:/Users/whkwo/Downloads/gemini

- 파일 이름은 원본 이름 그대로 (소문자, 확장자는 .jpg). 예: spot_b2.png → spot_b2.jpg
- 코드에서 안 쓰는 이름(예: image (1).png)은 건너뛴다
- 정사각형이 아니면 가운데를 잘라 정사각형으로 만든다
- 같은 이름이 이미 있으면 덮어쓴다
- 필요: Pillow  (없으면  pip install pillow)
"""
import io
import os
import sys

from PIL import Image, ImageOps

SIZE = 480
MAX_BYTES = 200 * 1024
EXTS = (".png", ".jpg", ".jpeg", ".webp")

# 코드에서 쓰는 이름 (Journal.kt + 시연용)
EXPECTED = {
    "spot_e0",
    "spot_b2", "spot_b3", "spot_b4", "spot_g3", "spot_c2", "spot_c4",
    "spot_k1", "spot_k2", "spot_k3", "spot_j1", "spot_j2", "spot_j3",
    "spot_s1", "spot_s2", "spot_s3", "spot_e1", "spot_e2", "spot_e3", "spot_e4",
    "spot_t1", "spot_t2", "spot_t3", "scn_munmak", "scn_yangtte", "scn_deokpyeong",
}

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "app", "src", "main", "res", "drawable-nodpi")


def shrink(src: str) -> bytes:
    im = Image.open(src)
    im = ImageOps.exif_transpose(im)                                    # 폰 사진 회전 바로잡기
    if im.mode != "RGB":                                                # 투명 배경(png) → 흰 바탕
        bg = Image.new("RGB", im.size, "white")
        rgba = im.convert("RGBA")
        bg.paste(rgba, mask=rgba.split()[3])
        im = bg
    im = ImageOps.fit(im, (SIZE, SIZE), Image.LANCZOS, centering=(0.5, 0.5))   # 가운데 정사각형
    for q in range(90, 29, -5):                                         # 200KB 아래가 될 때까지 화질 낮추기
        buf = io.BytesIO()
        im.save(buf, "JPEG", quality=q, optimize=True, progressive=True)
        if buf.tell() <= MAX_BYTES:
            return buf.getvalue()
    return buf.getvalue()


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)
    src_dir = sys.argv[1]
    files = sorted(f for f in os.listdir(src_dir) if f.lower().endswith(EXTS))
    if not files:
        print("사진이 없어요:", src_dir)
        sys.exit(1)
    os.makedirs(OUT, exist_ok=True)
    done = set()
    for f in files:
        name = os.path.splitext(f)[0].lower().replace("-", "_").replace(" ", "_")
        if name not in EXPECTED:                                        # 이상한 이름이 res 에 들어가면 빌드가 깨진다
            print(f"⏭  {f}  (코드에서 쓰는 이름이 아니라 건너뜀 — 이름을 spot_b2 처럼 바꿔 주세요)")
            continue
        data = shrink(os.path.join(src_dir, f))
        with open(os.path.join(OUT, name + ".jpg"), "wb") as w:
            w.write(data)
        done.add(name)
        print(f"✅ {f}  →  {name}.jpg  ({len(data) // 1024}KB)")
    missing = sorted(EXPECTED - done - {os.path.splitext(x)[0] for x in os.listdir(OUT)})
    print()
    print(f"{len(done)}장 완료 → {os.path.normpath(OUT)}")
    if missing:
        print("⚠ 아직 없는 사진 (이게 없으면 빌드가 안 돼요):", ", ".join(missing))


if __name__ == "__main__":
    main()
