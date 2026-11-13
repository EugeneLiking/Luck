# -*- coding: utf-8 -*-
"""pdf-to-markdown skill：PDF 整篇转 Markdown（文本层直转，秒级），并保证图表不丢。

核心约定：
  1. 逐页转换，页与页之间用 <!-- page NN --> 锚点分隔；
  2. 含图表的页（内嵌位图 ≥1 或矢量绘图 ≥30）整页渲染成 PNG，
     在 markdown 里就地插入图像链接 + 「必须看图并联系上下文」提示；
  3. 生成 figures.json 清单（页码、PNG 路径、该页文字），供 agent 逐图解读。

用法：
  python pdf_to_md.py "<PDF>" [--out 输出.md] [--pages 1,3-5] [--dpi 150] [--no-figures]
默认输出到当前目录 <PDF名>.md，不写回 PDF 原目录。
"""
import argparse
import json
import os
import sys

import pymupdf
import pymupdf4llm


def parse_pages(spec):
    if not spec:
        return None
    out = set()
    for part in spec.split(","):
        part = part.strip()
        if "-" in part:
            a, b = part.split("-")
            out.update(range(int(a) - 1, int(b)))
        elif part:
            out.add(int(part) - 1)
    return sorted(out)


def is_figure_page(page):
    """位图 ≥1（R 输出截图等）或矢量绘图 ≥30（柱状/折线等真图表；Beamer 装饰仅 5-9）。"""
    if len(page.get_images(full=True)) >= 1:
        return True
    try:
        return len(page.get_drawings()) >= 30
    except Exception:
        return False


def main():
    ap = argparse.ArgumentParser(description="PDF -> Markdown（文本层直转 + 图表页保真）")
    ap.add_argument("pdf")
    ap.add_argument("--out", help="输出 md 路径，默认 当前目录/<PDF名>.md")
    ap.add_argument("--pages", help="页码，如 1,3-5（1 起）")
    ap.add_argument("--dpi", type=int, default=150, help="图表页渲染分辨率")
    ap.add_argument("--no-figures", action="store_true", help="只转文字，不渲染图表页")
    args = ap.parse_args()

    if not os.path.isfile(args.pdf):
        print("找不到文件: " + args.pdf, file=sys.stderr)
        return 1

    stem = os.path.splitext(os.path.basename(args.pdf))[0]
    out = args.out or (stem + ".md")
    out_dir = os.path.dirname(os.path.abspath(out))
    img_dir = os.path.splitext(os.path.abspath(out))[0] + "_images"

    doc = pymupdf.open(args.pdf)
    n_total = doc.page_count
    pages = parse_pages(args.pages) or list(range(n_total))

    md_parts = []
    figures = []
    if not args.no_figures:
        os.makedirs(img_dir, exist_ok=True)
    img_rel = os.path.basename(img_dir)

    for p in pages:
        page = doc[p]
        md_page = pymupdf4llm.to_markdown(args.pdf, pages=[p], show_progress=False)
        block = f"<!-- page {p+1} -->\n\n{md_page.strip()}\n"
        if not args.no_figures and is_figure_page(page):
            png = os.path.join(img_dir, f"page-{p+1:02d}.png")
            pix = page.get_pixmap(dpi=args.dpi)
            pix.save(png)
            rel = f"{img_rel}/page-{p+1:02d}.png"
            block += (
                f"\n> 📊 **本页含图表**（整页图：`{rel}`）。\n"
                f"> **阅读约定**：必须用图像查看工具打开此图，把图的含义与上面文字上下文\n"
                f"> 一起理解（趋势/显著性/坐标轴/结论），不得只读文字而跳过图。\n\n"
                f"![第{p+1}页图表]({rel})\n"
            )
            figures.append({"page": p + 1, "image": rel, "text": page.get_text().strip()})
        md_parts.append(block)

    md = "\n\n---\n\n".join(md_parts)
    with open(out, "w", encoding="utf-8") as f:
        f.write(md)
    if figures:
        with open(os.path.splitext(out)[0] + "_figures.json", "w", encoding="utf-8") as f:
            json.dump(figures, f, ensure_ascii=False, indent=2)
    doc.close()

    est_tokens = len(md) // 4
    print(f"已转换: {args.pdf}")
    print(f"输出:   {out}")
    print(f"页数:   {len(pages)}/{n_total}   Markdown 字符: {len(md):,}   估算 token: ~{est_tokens:,}")
    print(f"图表页: {len(figures)} 页已整页渲染到 {img_rel}\\（含上下文，必须看图解读）")
    if len(md.strip()) < 50:
        print("⚠️ 输出几乎为空：可能是扫描件（无文本层），改用 handwriting-ocr。")
    return 0


if __name__ == "__main__":
    sys.exit(main())
