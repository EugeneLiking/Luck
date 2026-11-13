---
name: pdf-to-markdown
description: >-
  把 PDF 整篇转成干净的 Markdown 供 AI 阅读，大幅缩减读取耗时与 token 用量；
  遇到 PDF 应主动转换、无需用户要求。文本层直转（pymupdf4llm），对带文本层的电子版
  PDF（课件/讲义/论文/电子书）秒级出结果。**含图表的页会整页渲染成 PNG 并在 md 就地
  插入图像链接，必须配合图像查看工具解读图的含义与上下文，不得只读文字**。
  触发词：PDF 转 markdown、PDF 转 md、读这个 PDF、PDF 提取成文本、减少读 PDF 的 token。
  不适用：扫描件/纯图片 PDF（无文本层，先用 handwriting-ocr）；精准抽取某页表格/图片
  （用 pdf-extract）。
metadata:
  upstream: pymupdf4llm（PyMuPDF 官方扩展，11,055★）
  runtime: C:\Users\L1141\OneDrive\MIMO\MIMO desk top\.venv\Scripts\python.exe
---

# pdf-to-markdown — PDF 整篇转 Markdown（省 token + 图表保真）

基于 **pymupdf4llm**（PyMuPDF 官方 LLM 扩展）。把"让 AI 读 PDF"变成"让 AI 读 Markdown"：
文本层直转、**秒级、离线、无模型**，token 远小于 PDF 原始读取。

## 两条铁律（本 skill 存在的意义）

1. **遇到 PDF 主动转**：凡是需要阅读 PDF 内容，先自动用本 skill 转 md，不等用户要求。
2. **图表必须读出含义+上下文**：含图表的页已整页渲染成 PNG 并在 md 就地插入图像链接。
   阅读 md 时，**凡遇到 📊 图表页标记，必须用图像查看工具打开对应 PNG**，
   把图的含义（趋势/显著性/坐标轴/结论）与该页文字上下文一起纳入理解或笔记，
   **不得只读文字跳过图**。图像查看工具在当前环境可用（视觉通道已验证）。

## 使用方式

```powershell
& "C:\Users\L1141\OneDrive\MIMO\MIMO desk top\.venv\Scripts\python.exe" scripts\pdf_to_md.py "<PDF路径>" [--out 输出.md] [--pages 1,3-5] [--dpi 150] [--no-figures]
```

- 默认输出到**当前目录** `<PDF名>.md`（不写回 PDF 原目录，保护个人文件）。
- `--pages`：只转指定页（1 起，支持 `1,3-5`）。
- `--no-figures`：只转文字，不渲染图表页（纯文字 PDF 想省图时用）。
- 逐页转换，页间用 `<!-- page NN -->` 锚点分隔。

## 输出物

| 文件 | 内容 |
|---|---|
| `<名>.md` | 逐页 markdown；图表页就地含 📊 提示 + `![第N页图表](...)` 链接 |
| `<名>_images\page-NN.png` | 图表页整页渲染（**图+图注+周围文字都在图里，上下文自带**） |
| `<名>_figures.json` | 图表页清单：页码、PNG 路径、该页文字（供逐图解读） |

结束打印统计：页数、Markdown 字符数、**估算 token**（≈字符/4）、图表页数。

## 图表页判定

内嵌位图 ≥1（R 输出截图等）**或**矢量绘图 ≥30（柱状/折线等真图表）。
Beamer 装饰线仅 5–9 个矢量元素，不会误判。整页渲染而非只抽内嵌图——
这样图注和上下文文字一并保留，且矢量图也不会漏。

## 通道选择

| PDF 类型 | 走哪个 |
|---|---|
| 电子版课件/讲义/论文（有文本层，本课程 PDF 都是） | 本 skill（秒级） |
| 扫描件/拍照件（无文本层） | `handwriting-ocr`；要更高排版质量可后装 marker/MinerU |
| 只要某页表格/图片/几段文字 | `pdf-extract` |

转出来若几乎为空 → 是扫描件，换通道。

## 环境依赖

- venv 已装 `pymupdf4llm`（依赖 PyMuPDF），离线、无模型。
- pymupdf4llm v2.0 会打印 RapidOCR/tesseract 探测警告，**无害可忽略**（文本层 PDF 不需 OCR）。
