"""math-symbol-ocr: 公式图像 -> LaTeX (pix2tex / LaTeX-OCR)。

用法:
  python ocr_math.py <图片> [更多图片...] [--display] [--save out.md]

--display  输出用 \\[ ... \\] 包裹的陈列式；默认输出裸 LaTeX。
--save     把结果按 $...$ 追加写入 markdown 文件。

依赖: pix2tex (lukas-blecher/LaTeX-OCR), pillow, torch(CPU)。
模型经 hf-mirror.com 下载（脚本自动设置 HF_ENDPOINT）。
"""
import argparse
import glob
import os
import sys

os.environ.setdefault("HF_ENDPOINT", "https://hf-mirror.com")

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


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("images", nargs="+")
    ap.add_argument("--display", action="store_true")
    ap.add_argument("--save", default=None)
    args = ap.parse_args()

    print("加载 pix2tex 模型（首次运行会下载）...", file=sys.stderr)
    from pix2tex.cli import LatexOCR

    model = LatexOCR()
    outs = []
    for path in expand(args.images):
        img = Image.open(path).convert("RGB")
        # 过小输入自动放大，提高识别率
        if min(img.size) < 40:
            scale = 2 if min(img.size) >= 20 else 3
            img = img.resize((img.width * scale, img.height * scale), Image.LANCZOS)
        latex = model(img)
        latex = latex.strip()
        outs.append((os.path.basename(path), latex))
        print(f"--- {os.path.basename(path)} ---")
        if args.display:
            print("\\[ " + latex + " \\]")
        else:
            print(latex)
        print()

    if args.save:
        with open(args.save, "a", encoding="utf-8") as f:
            for name, latex in outs:
                f.write(f"<!-- {name} -->\n\n$$\n{latex}\n$$\n\n")
        print(f"已写入 {args.save}", file=sys.stderr)


if __name__ == "__main__":
    main()
