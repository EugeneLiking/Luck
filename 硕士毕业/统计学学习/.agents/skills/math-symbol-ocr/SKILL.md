---
name: math-symbol-ocr
description: >-
  数学符号与公式解析：把公式图像（截图、扫描件、讲义截图、手写公式照片）识别为
  LaTeX 代码，支持行内公式与陈列式公式，可直接贴入笔记或论文。
  触发词：数学符号解析、公式识别、公式转 LaTeX、image to latex、math ocr、
  把这条公式打出来、识别这个符号。适用于统计学/经济学课程讲义、教材截图、
  论文公式录入。不适用：纯文字段落识别（用 handwriting-ocr 或通用 OCR）。
metadata:
  upstream: lukas-blecher/LaTeX-OCR (pix2tex, 16,602★, MIT)
  runtime: C:\Users\L1141\OneDrive\MIMO\MIMO desk top\.venv\Scripts\python.exe
---

# math-symbol-ocr — 数学符号解析（pix2tex）

基于 [lukas-blecher/LaTeX-OCR](https://github.com/lukas-blecher/LaTeX-OCR)（pix2tex，16,602★）：
ViT 模型把公式图像转为 LaTeX。模型权重经 hf-mirror.com 下载（本机 huggingface.co 被墙）。

## 使用方式

**单图快速识别**（推荐入口）：

```powershell
& "C:\Users\L1141\OneDrive\MIMO\MIMO desk top\.venv\Scripts\python.exe" scripts\ocr_math.py <图片路径> [<图片2> ...]
```

- 输出每个图片的 LaTeX；多图批量传入即可。
- `--display`：输出 `\[ ... \]` 陈列式包裹；默认只给裸 LaTeX。
- `--save 输出.md`：追加写入 markdown 文件（公式用 `$...$` 包裹）。

**程序内调用**：

```python
from pix2tex.cli import LatexOCR
from PIL import Image
model = LatexOCR()          # 首次运行会下载权重（走 hf-mirror）
latex = model(Image.open("formula.png"))
```

## 提高识别质量的输入约定

1. **裁剪要紧**：只留公式区域，上下留白不超过公式高度的一半；多余文字会诱导幻觉。
2. **分辨率**：公式短边 ≥ 40px；小于时先放大 2-3 倍（`scripts/ocr_math.py` 会自动放大过小输入）。
3. **印刷体效果最好**。⚠️ 实测（BECO7010 教授手写批注）：pix2tex 对**手写**内容会输出幻觉 LaTeX（无意义符号串），手写一律先走 `handwriting-ocr` 的文本通道；只有确认是印刷体公式截图才用本 skill。
4. 识别结果**必须人工核对**：模型对上下标、希腊字母、分式偶尔出错；用于论文/作业前逐符号对照原图。

## 与本工作区其他 skill 的分工

| 情况 | 用哪个 |
|---|---|
| 截图/图片里的公式 → LaTeX | 本 skill |
| 教授手写批注/手写笔记 → 文字 | `handwriting-ocr` |
| 整页讲义 PDF → markdown 笔记 | `handwriting-ocr` 的 PDF 工具链 + 本 skill 补公式 |
| 统计术语与报告规范 | `nature-statistics` |

## 环境依赖

- Python：`C:\Users\L1141\OneDrive\MIMO\MIMO desk top\.venv\Scripts\python.exe`（torch CPU 版 + pix2tex 已装）
- 模型下载环境变量：`HF_ENDPOINT=https://hf-mirror.com`（脚本内已自动设置）
- 首次运行下载权重约 200MB，之后离线可用。
