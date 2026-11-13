---
name: pdf-extract
description: >-
  从 PDF 精准提取局部内容：按页提取文本、表格抽成 CSV、内嵌图片导出、元数据与目录
  （TOC）查看。用于"只要 PDF 里某部分"的场景，不必整篇转换。
  触发词：PDF 提取、提取 PDF 表格、PDF 表格转 CSV、导出 PDF 图片、看 PDF 目录、
  提取第几页、PDF 某页文字。不适用：整篇转 Markdown 阅读（用 pdf-to-markdown）、
  扫描件识别（用 handwriting-ocr）。
metadata:
  upstream: PyMuPDF(11,055★) + pdfplumber(10,871★)
  runtime: C:\Users\L1141\OneDrive\MIMO\MIMO desk top\.venv\Scripts\python.exe
---

# pdf-extract — PDF 局部内容精准提取

基于 **PyMuPDF**（文本/图片/元数据）+ **pdfplumber**（表格）。与 `pdf-to-markdown` 的分工：
那个负责"整篇转 md 给 AI 读"，这个负责"精准取出某页/某表/某图"。

## 使用方式

```powershell
& "C:\Users\L1141\OneDrive\MIMO\MIMO desk top\.venv\Scripts\python.exe" scripts\pdf_extract.py <子命令> "<PDF>" [--pages 1,3-5] [--out-dir 输出目录]
```

| 子命令 | 作用 | 输出 |
|---|---|---|
| `meta` | 元数据 + 页数 + 目录（TOC） | 打印到控制台 |
| `text` | 按页提取文本 | 控制台 + `out/text_p<页>.txt` |
| `tables` | 提取表格 | `out/table_p<页>_<序号>.csv` + 前几行预览 |
| `images` | 导出内嵌图片 | `out/img_p<页>_<序号>.png` |

- `--pages`：1 起，支持 `1,3-5` 区间；缺省为全部页。
- `--out-dir`：默认当前目录 `pdf_extract_out\`，**不写回 PDF 原目录**。

## 典型场景

- 教授课件里的**参数表/结果表**要拿去 Excel/R 分析 → `tables` 抽成 CSV。
- 只要讲义**第 N 页的文字**核对公式上下文 → `text --pages N`。
- 要 PDF 里的**插图原图**（如 ACF 图）→ `images`。
- 先看**目录**决定读哪几章 → `meta`。

## 环境依赖

- venv 已装 `pymupdf`（PyMuPDF）与 `pdfplumber`，离线、无模型。
- 扫描件无文本层时 `text/tables` 会为空 → 改用 `handwriting-ocr`。
