---
name: r-econometrics
description: >-
  BECO7010（Statistics and Financial Econometrics，Yi Ding）课程 R 计量分析工具链：
  按课程大纲提供可直接运行的 R 模板——单变量/多变量描述统计、线性回归与诊断、
  时间序列（ACF/PACF、单位根、ARIMA）、ARCH/GARCH 波动率模型、VaR、因子模型。
  触发词：R 分析、跑一下回归、拟合 ARIMA、GARCH 拟合、ACF、单位根检验、
  VaR 计算、因子分析、计量分析、时间序列作业。不适用：符号公式推导
  （用 symbolic-math）、图片公式识别（用 math-symbol-ocr）。
metadata:
  runtime: C:\Program Files\R\R-4.6.2\bin\Rscript.exe
  packages: FinTS, tseries, urca, forecast, rugarch, ggplot2, xts, zoo, moments, lmtest
  upstream: FinTS(Tsay 教材配套包), rugarch, forecast 等 CRAN 包
---

# r-econometrics — BECO7010 课程 R 计量分析工具链

针对 **BECO7010 – Statistics and Financial Econometrics**（教材 Tsay《Analysis of Financial
Time Series》，课程用 R）封装。环境：R 4.6.2（`C:\Program Files\R\R-4.6.2\bin\Rscript.exe`）+
10 个课程 R 包（用户级库 `%LOCALAPPDATA%\R\win-library\4.6`，免管理员）。

## 使用方式

```powershell
& "C:\Program Files\R\R-4.6.2\bin\Rscript.exe" scripts\<模板>.R [数据.csv]
```

- **无参数**：每个模板用内置模拟数据演示（可验证工具链、看输出长什么样）。
- **带 CSV**：第一列为被分析变量（回归模板：第一列 y、其余列为解释变量；描述统计多列时自动做相关矩阵/散点矩阵）。
- 图表输出到**当前目录 `out\*.png`**（避免在中文路径直接出图）。

## 按课程大纲的模板映射

| 周 | 主题 | 模板脚本 |
|---|---|---|
| 2-3 | 单变量/多变量数据分析 | `scripts/wk02_03_descriptive.R` |
| 4-5 | 线性回归 I/II | `scripts/wk04_05_regression.R` |
| 6-8 | 时间序列模型 I/II | `scripts/wk06_08_timeseries.R` |
| 9-11 | 波动率模型 + 风险管理应用 | `scripts/wk09_11_volatility.R` |
| 12 | 因子模型 | `scripts/wk12_factor.R` |
| — | 环境自检 | `scripts/check_env.R` |

关键函数对照（课程常用）：
- 单位根：`tseries::adf.test`、`urca::ur.df`
- AR/ARIMA：`ar()`、`forecast::auto.arima`
- ARCH 效应：`FinTS::ArchTest`（Tsay 教材配套）
- GARCH：`rugarch::ugarchspec + ugarchfit`
- 回归诊断：`lmtest::bptest`（异方差）、`lmtest::dwtest`（自相关）
- 描述统计：`moments::skewness/kurtosis`、`tseries::jarque.bera.test`

## 工作方式约定

1. 模板是**起点不是终点**：换数据时把 CSV 路径传入即可；要改模型设定（如 GARCH 阶数、分布假设），直接改脚本里的 `ugarchspec`/`auto.arima` 参数。
2. **课程作业用 R 演示**：本 skill 的函数与课程 R 演示一致（FinTS/tseries/rugarch），结果可与课堂输出对照。
3. 检验结论要结合 p 值与图形一起看，别只读数字。
4. 若需新增包：编辑 `scripts/install_packages.R` 追加后重跑（清华镜像）。

## 环境依赖

- R 4.6.2：winget `RProject.R` 安装（`C:\Program Files\R\R-4.6.2\bin\Rscript.exe`）
- 包安装：`Rscript scripts/install_packages.R`（清华 CRAN 镜像，装到用户库）
- 重装/换机：先装 R，再跑 install_packages.R，最后 check_env.R 验证。

## 与本项目其他 skill 的分工

| 需求 | 用哪个 |
|---|---|
| 数值统计计算/建模（本课程） | 本 skill |
| 公式符号推导验证 | `symbolic-math` |
| 截图/图片公式 → LaTeX | `math-symbol-ocr` |
| 教授手写批注 → 文字 | `handwriting-ocr` |
