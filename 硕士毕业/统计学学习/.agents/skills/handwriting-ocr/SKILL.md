---
name: handwriting-ocr
description: >-
  教授手写内容识别：把讲义/板书照片/PDF 批注版里的手写笔迹、手写公式、圈画批注
  识别为可编辑文字（markdown）。支持中英混写、90+ 语言，含 PDF 批注差分定位
  （对比无批注版自动裁出手写区域）。触发词：手写识别、手写转文字、笔记 OCR、
  识别教授的批注、handwriting、把讲义上的手写内容整理出来。
  不适用：纯印刷体整书扫描（用 marker 等整书转换工具）。
metadata:
  upstream: datalab-to/surya (21,569★, GPL-3.0)
  runtime: C:\Users\L1141\OneDrive\MIMO\MIMO desk top\.venv\Scripts\python.exe
---

# handwriting-ocr — 教授手写内容识别（Surya）

基于 [datalab-to/surya](https://github.com/datalab-to/surya)（21,569★）：文档 OCR，
对**手写笔迹**效果好，90+ 语言，按阅读顺序输出文本行。配套 PyMuPDF 做 PDF 页面
渲染与批注差分裁剪。模型权重经 hf-mirror.com 下载（本机 huggingface.co 被墙）。

## 工具链

**1. 手写图片 → 文字**：

```powershell
& "C:\Users\L1141\OneDrive\MIMO\MIMO desk top\.venv\Scripts\python.exe" scripts\ocr_handwriting.py <图片或PDF> [<第二个> ...] [--pages 8,14,15] [--save out.md]
```

- PDF 输入自动渲染指定页（`--pages`，默认全部）再识别；
- 输出按阅读顺序分行的 markdown；`--save` 落盘。

**2. 批注差分裁剪**（讲义有「无批注版 + 批注版」两个 PDF 时，自动定位手写区域）：

```powershell
& "...\python.exe" scripts\isolate_annotations.py <批注版.pdf> <无批注版.pdf> --out <输出目录>
```

- 逐页像素差分找出批注所在页，再按连通区域聚类裁出每个手写块的小图；
- 输出 `<输出目录>\p<页码>_b<块号>.png` + `regions.json`（位置元数据）；
- 裁出的小图逐张交给 `ocr_handwriting.py` 识别，公式状符号补用 `math-symbol-ocr`。

## 典型工作流：教授批注讲义 → 文字笔记

1. `isolate_annotations.py` 定位并裁出手写块；
2. `ocr_handwriting.py` 批量识别手写块；
3. 数学符号/公式片段用 `math-symbol-ocr` 二次识别，与文本结果合并；
4. **人工核对**：手写识别错误率高于印刷体，人名、符号、上下标必须对照原图检查。

## 质量建议

- 裁剪块短边 ≥ 30px，过小先放大；整页识别时手写小字容易丢，优先按块识别；
- 中英混写无需指定语言（自动检测）；纯英文批注可加 `--langs en` 提速；
- 识别结果只是草稿，**必须与原图核对后再进笔记/论文**。

## 环境依赖

- Python：`C:\Users\L1141\OneDrive\MIMO\MIMO desk top\.venv\Scripts\python.exe`（torch CPU 版 + surya-ocr + pymupdf + opencv 已装）
- **llama-server 二进制**：`tools\llama-server.exe`（llama.cpp b12034 win-cpu-x64，随 skill 存放；surya 2.x 是 VLM 架构，CPU 推理经 llama.cpp 后端）。脚本已自动设置 `SURYA_INFERENCE_BACKEND=llamacpp` 与 `LLAMA_CPP_BINARY`。
- 模型下载环境变量：`HF_ENDPOINT=https://hf-mirror.com`（脚本内已自动设置；huggingface.co 在本机不可达）。
- 首次运行下载 GGUF 模型（`surya-2.5.gguf` 1.18GB + `mmproj` 0.21GB，经 hf-mirror），之后离线可用。

## 已知陷阱（实测踩过）

- **`cv2.imwrite` 在 Windows 不支持中文路径**（静默失败不报错），脚本已改用 `imencode` + Python 写字节；自己写脚本时注意。
- shell 通配符在非 ASCII 工作目录下可能不展开，脚本已内置 glob 展开；传文件列表更稳。
