---
name: symbolic-math
description: >-
  符号数学推导：用 SymPy 做公式化简、展开、因式分解、求导、积分、级数展开、
  解方程、矩阵运算（行列式/逆矩阵/特征值），同时输出 LaTeX 与纯文本，用于
  统计学/计量经济学课程（BECO7010）讲义公式推导与作业验证。
  触发词：符号计算、公式推导、帮我求导、积分、化简这个式子、解这个方程、
  行列式、逆矩阵、特征值、验证我的推导。不适用：数值统计计算与建模
  （用 r-econometrics）、图像公式识别（用 math-symbol-ocr）。
metadata:
  upstream: sympy/sympy (15,068★, BSD)
  runtime: C:\Users\L1141\OneDrive\MIMO\MIMO desk top\.venv\Scripts\python.exe
---

# symbolic-math — 符号数学推导（SymPy）

基于 [sympy/sympy](https://github.com/sympy/sympy)（15,068★，纯 Python 计算机代数系统）。
适合：验证讲义上的公式推导（如 AR 模型系数递推、矩估计、矩阵运算）、作业里手工推导的核对。

## 使用方式

```powershell
& "C:\Users\L1141\OneDrive\MIMO\MIMO desk top\.venv\Scripts\python.exe" scripts\sympy_eval.py <操作> "<表达式>" [选项]
```

支持的操作：

| 操作 | 作用 | 示例 |
|---|---|---|
| `simplify` | 化简（默认） | `simplify "2*x + 3*x"` → `5*x` |
| `expand` | 展开 | `expand "(x+1)**3"` |
| `factor` | 因式分解 | `factor "x**2 - 5*x + 6"` |
| `diff` | 求导 | `diff "x**2 * exp(x)" --var x` |
| `integrate` | 积分（不定） | `integrate "1/(1+x**2)" --var x` |
| `series` | 泰勒级数 | `series "exp(x)" --var x --point 0 --order 6` |
| `solve` | 解方程（=0） | `solve "x**2 - 5*x + 6" --var x` |
| `matrix` | 矩阵诊断 | `matrix "[[1,2],[3,4]]"` → 行列式/逆/特征值 |
| `latex` | 只输出 LaTeX | `latex "(a+b)/(c+d)"` |

选项：`--var <变量>`（默认 x）、`--point <展开点>`（默认 0）、`--order <阶数>`（默认 6）、
`--save <文件.md>`（把结果追加写入 markdown）。

## 输入语法（宽松）

- 乘号可省略：`2x` = `2*x`；`^` 等价 `**`（幂）。
- 常见函数直接用：`sin(x)`、`exp(x)`、`log(x)`、`sqrt(x)`、`pi`、`E`。
- 希腊字母直接写名字：`alpha`、`beta`、`gamma`、`sigma`。

## 注意

1. 结果是**符号精确值**，不是数值近似；需要数值再加 `evalf`（脚本输出已含数值化结果时以文本为准）。
2. 多变量表达式用 `--var` 指明对哪个变量操作，否则默认 `x`。
3. 结果用于作业/考试前**人工核对一步**：符号系统对定义域、分支（如 log、sqrt）的处理可能与课程约定不同。

## 环境依赖

- Python：`C:\Users\L1141\OneDrive\MIMO\MIMO desk top\.venv\Scripts\python.exe`（sympy 随 venv 已装）
- 无需联网、无模型，纯本地计算。
