"""handwriting-ocr: 手写笔迹/讲义图片/PDF -> 文字 (markdown)。

用法:
  python ocr_handwriting.py <图片或PDF> [更多文件...] [--pages 8,14] [--dpi 150] [--save out.md]

依赖: surya-ocr (datalab-to/surya), pymupdf, pillow, torch(CPU)。
模型经 hf-mirror.com 下载（脚本自动设置 HF_ENDPOINT）。
"""
import argparse
import glob
import os
import re
import sys

os.environ.setdefault("HF_ENDPOINT", "https://hf-mirror.com")

# surya 2.x 是 VLM 架构：CPU 走 llama.cpp 后端，需要 llama-server 二进制。
# 二进制随 skill 放在 tools/ 下（llama.cpp b12034 win-cpu-x64）。
_LLAMA = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                      "tools", "llama-server.exe")
os.environ.setdefault("SURYA_INFERENCE_BACKEND", "llamacpp")
if os.path.isfile(_LLAMA):
    os.environ.setdefault("LLAMA_CPP_BINARY", _LLAMA)

import pymupdf
from PIL import Image


def expand(patterns):
    """展开通配符并校验存在性（shell 在非 ASCII 目录下可能不展开 glob）。"""
    out = []
    for p in patterns:
        hits = glob.glob(p) if any(c in p for c in "*?[") else ([p] if os.path.exists(p) else [])
        if not hits:
            print(f"跳过：找不到文件 {p}", file=sys.stderr)
            continue
        out.extend(sorted(hits))
    return out


def strip_html(s: str) -> str:
    s = re.sub(r"<br\s*/?>", "\n", s)
    s = re.sub(r"</p>|</div>|</h[1-6]>|</li>", "\n", s)
    s = re.sub(r"<[^>]+>", "", s)
    s = re.sub(r"\n{3,}", "\n\n", s)
    return s.strip()


def load_inputs(paths, pages=None, dpi=150):
    """返回 [(名称, PIL.Image), ...]"""
    items = []
    for path in paths:
        low = path.lower()
        if low.endswith(".pdf"):
            doc = pymupdf.open(path)
            idxs = pages if pages else range(doc.page_count)
            for i in idxs:
                if i >= doc.page_count:
                    continue
                pix = doc[i].get_pixmap(dpi=dpi)
                img = Image.frombytes("RGB", (pix.width, pix.height), pix.samples)
                items.append((f"{os.path.basename(path)}#p{i+1}", img))
            doc.close()
        else:
            items.append((os.path.basename(path), Image.open(path).convert("RGB")))
    return items


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("files", nargs="+", help="图片或 PDF 文件")
    ap.add_argument("--pages", default=None, help="PDF 页码（1 起，逗号分隔），默认全部")
    ap.add_argument("--dpi", type=int, default=150)
    ap.add_argument("--save", default=None, help="追加写入的 markdown 文件")
    args = ap.parse_args()

    pages = None
    if args.pages:
        pages = [int(x) - 1 for x in args.pages.split(",") if x.strip()]

    items = load_inputs(expand(args.files), pages, args.dpi)
    if not items:
        print("没有可识别的输入", file=sys.stderr)
        sys.exit(1)

    print(f"加载 {len(items)} 张图，正在加载 surya 模型（首次运行会下载）...", file=sys.stderr)
    from surya.recognition import RecognitionPredictor

    pred = RecognitionPredictor()
    results = pred([img for _, img in items], full_page=True)

    out_parts = []
    for (name, _), res in zip(items, results):
        blocks = sorted(res.blocks, key=lambda b: b.reading_order)
        texts = []
        for b in blocks:
            if b.skipped or not b.html:
                continue
            t = strip_html(b.html)
            if t:
                texts.append(t)
        body = "\n\n".join(texts) if texts else "(未识别到文字)"
        out_parts.append(f"### {name}\n\n{body}")
        print(f"--- {name} ---")
        print(body)
        print()

    if args.save:
        with open(args.save, "a", encoding="utf-8") as f:
            f.write("\n\n".join(out_parts) + "\n\n")
        print(f"已写入 {args.save}", file=sys.stderr)


if __name__ == "__main__":
    main()
