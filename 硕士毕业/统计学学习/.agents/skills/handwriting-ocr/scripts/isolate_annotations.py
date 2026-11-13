"""isolate_annotations: 对比「批注版 PDF」与「无批注版 PDF」，自动定位并裁出手写批注块。

用法:
  python isolate_annotations.py <批注版.pdf> <无批注版.pdf> --out <输出目录> [--dpi 150]

输出:
  <输出目录>/p<页码>_b<块号>.png   裁出的手写块（带边距）
  <输出目录>/regions.json         块位置元数据
  控制台输出：哪些页存在批注、每页块数

依赖: pymupdf, opencv-python-headless, numpy, pillow。
"""
import argparse
import json
import os

import cv2
import numpy as np
import pymupdf


def render(path, page_i, dpi):
    doc = pymupdf.open(path)
    pix = doc[page_i].get_pixmap(dpi=dpi)
    img = np.frombuffer(pix.samples, dtype=np.uint8).reshape(pix.height, pix.width, 3)
    doc.close()
    return img


def find_blocks(annotated, clean):
    diff = cv2.absdiff(annotated, clean).max(axis=2)
    _, th = cv2.threshold(diff, 40, 255, cv2.THRESH_BINARY)
    # 膨胀把同一笔迹/邻近笔画聚成块
    k = cv2.getStructuringElement(cv2.MORPH_RECT, (25, 25))
    merged = cv2.dilate(th, k)
    n, _, stats, _ = cv2.connectedComponentsWithStats(merged, connectivity=8)
    blocks = []
    for i in range(1, n):
        x, y, w, h, area = stats[i]
        if area < 200 or w < 12 or h < 12:
            continue
        blocks.append((x, y, w, h))
    return blocks


def imwrite_unicode(path, img_bgr):
    """cv2.imwrite 在 Windows 不支持非 ASCII 路径，用 imencode + open 绕开。"""
    ok, buf = cv2.imencode(".png", img_bgr)
    if not ok:
        raise IOError("PNG 编码失败: " + path)
    with open(path, "wb") as f:
        f.write(buf.tobytes())


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("annotated")
    ap.add_argument("clean")
    ap.add_argument("--out", required=True)
    ap.add_argument("--dpi", type=int, default=150)
    ap.add_argument("--margin", type=int, default=12)
    args = ap.parse_args()

    os.makedirs(args.out, exist_ok=True)
    da = pymupdf.open(args.annotated)
    dc = pymupdf.open(args.clean)
    if da.page_count != dc.page_count:
        print(f"警告: 页数不一致 ({da.page_count} vs {dc.page_count})，只比较公共页")

    meta = []
    for i in range(min(da.page_count, dc.page_count)):
        a = render(args.annotated, i, args.dpi)
        c = render(args.clean, i, args.dpi)
        if a.shape != c.shape:
            print(f"第{i+1}页 尺寸不同，跳过")
            continue
        blocks = find_blocks(a, c)
        if not blocks:
            continue
        print(f"第{i+1}页: {len(blocks)} 个手写块")
        for j, (x, y, w, h) in enumerate(blocks):
            m = args.margin
            x0, y0 = max(0, x - m), max(0, y - m)
            x1, y1 = min(a.shape[1], x + w + m), min(a.shape[0], y + h + m)
            crop = a[y0:y1, x0:x1]
            name = f"p{i+1:02d}_b{j+1:02d}.png"
            imwrite_unicode(os.path.join(args.out, name), cv2.cvtColor(crop, cv2.COLOR_RGB2BGR))
            meta.append({"page": i + 1, "file": name,
                         "bbox_dpi": [int(x0), int(y0), int(x1), int(y1)], "dpi": args.dpi})

    with open(os.path.join(args.out, "regions.json"), "w", encoding="utf-8") as f:
        json.dump(meta, f, ensure_ascii=False, indent=2)
    print(f"共 {len(meta)} 个手写块 -> {args.out}")


if __name__ == "__main__":
    main()
