# -*- coding: utf-8 -*-
"""pdf-extract skill：PDF 局部内容精准提取（文本/表格/图片/元数据）。

用法：
  python pdf_extract.py meta   "<PDF>"
  python pdf_extract.py text   "<PDF>" [--pages 1,3-5] [--out-dir out]
  python pdf_extract.py tables "<PDF>" [--pages ...]     [--out-dir out]
  python pdf_extract.py images "<PDF>" [--pages ...]     [--out-dir out]
"""
import argparse
import os
import sys

import pymupdf


def parse_pages(spec, n_total):
    if not spec:
        return list(range(n_total))
    out = set()
    for part in spec.split(","):
        part = part.strip()
        if "-" in part:
            a, b = part.split("-")
            out.update(range(int(a) - 1, int(b)))
        elif part:
            out.add(int(part) - 1)
    return sorted(p for p in out if 0 <= p < n_total)


def do_meta(doc, args):
    print("文件:", args.pdf)
    print("页数:", doc.page_count)
    md = doc.metadata or {}
    for k in ("title", "author", "subject", "creator", "producer"):
        if md.get(k):
            print(f"{k}: {md[k]}")
    toc = doc.get_toc()
    print(f"\n目录（{len(toc)} 条）：")
    for lvl, title, page in toc:
        print("  " * (lvl - 1) + f"[{page}] {title}")


def do_text(doc, args, outdir):
    os.makedirs(outdir, exist_ok=True)
    for p in parse_pages(args.pages, doc.page_count):
        text = doc[p].get_text()
        fp = os.path.join(outdir, f"text_p{p+1:02d}.txt")
        with open(fp, "w", encoding="utf-8") as f:
            f.write(text)
        print(f"\n===== 第 {p+1} 页 ({len(text)} 字符) -> {fp} =====")
        print(text)


def do_tables(doc, args, outdir):
    import pdfplumber
    os.makedirs(outdir, exist_ok=True)
    pages = parse_pages(args.pages, doc.page_count)
    with pdfplumber.open(args.pdf) as pdf:
        for p in pages:
            tables = pdf.pages[p].extract_tables()
            print(f"\n===== 第 {p+1} 页：{len(tables)} 个表格 =====")
            for i, tb in enumerate(tables, 1):
                fp = os.path.join(outdir, f"table_p{p+1:02d}_{i}.csv")
                with open(fp, "w", encoding="utf-8-sig", newline="") as f:
                    import csv
                    csv.writer(f).writerows(tb)
                print(f"  表{i}（{len(tb)} 行）-> {fp}")
                for row in tb[:4]:
                    print("   ", row)


def do_images(doc, args, outdir):
    os.makedirs(outdir, exist_ok=True)
    for p in parse_pages(args.pages, doc.page_count):
        imgs = doc[p].get_images(full=True)
        print(f"第 {p+1} 页：{len(imgs)} 张图片")
        for i, im in enumerate(imgs, 1):
            xref = im[0]
            data = doc.extract_image(xref)
            ext = data.get("ext", "png")
            fp = os.path.join(outdir, f"img_p{p+1:02d}_{i}.{ext}")
            with open(fp, "wb") as f:
                f.write(data["image"])
            print("  ->", fp)


def main():
    ap = argparse.ArgumentParser(description="PDF 局部提取")
    ap.add_argument("cmd", choices=["meta", "text", "tables", "images"])
    ap.add_argument("pdf")
    ap.add_argument("--pages", help="页码，如 1,3-5（1 起）")
    ap.add_argument("--out-dir", default="pdf_extract_out")
    args = ap.parse_args()

    if not os.path.isfile(args.pdf):
        print("找不到文件: " + args.pdf, file=sys.stderr)
        return 1

    doc = pymupdf.open(args.pdf)
    if args.cmd == "meta":
        do_meta(doc, args)
    elif args.cmd == "text":
        do_text(doc, args, args.out_dir)
    elif args.cmd == "tables":
        do_tables(doc, args, args.out_dir)
    elif args.cmd == "images":
        do_images(doc, args, args.out_dir)
    doc.close()
    return 0


if __name__ == "__main__":
    sys.exit(main())
