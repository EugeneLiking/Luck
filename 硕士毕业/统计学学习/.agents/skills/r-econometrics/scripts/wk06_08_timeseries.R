# Week 6-8 时间序列模板：ACF/PACF、单位根检验、AR/ARIMA 拟合、残差诊断、预测
# 用法：Rscript wk06_08_timeseries.R [序列.csv]
#   无参数时模拟一个 AR(2) 序列演示（对应讲义 Cov(yt,yt-j)、ACF 内容）；
#   CSV 时分析第一列数值序列。
lib <- file.path(Sys.getenv("LOCALAPPDATA"), "R", "win-library", "4.6")
if (dir.exists(lib)) .libPaths(c(lib, .libPaths()))
suppressMessages({library(tseries); library(forecast)})

args <- commandArgs(trailingOnly = TRUE)
dir.create("out", showWarnings = FALSE)

if (length(args) >= 1) {
  df <- read.csv(args[1])
  x <- as.numeric(df[[1]])
  cat("数据文件:", args[1], "  序列长度:", length(x), "\n")
} else {
  set.seed(42)
  x <- as.numeric(arima.sim(list(ar = c(0.5, 0.3)), n = 500))
  cat("内置演示：AR(2) 模拟序列（phi1=0.5, phi2=0.3, n=500）\n")
}
x <- x[is.finite(x)]

png("out/ts_series_acf_pacf.png", width = 1000, height = 900)
par(mfrow = c(3, 1))
plot(x, type = "l", main = "序列", xlab = "t")
acf(x, main = "ACF")
pacf(x, main = "PACF")
dev.off()
cat("序列/ACF/PACF 图已存 out/ts_series_acf_pacf.png\n")

cat("\n== 单位根检验 ADF ==\n"); print(adf.test(x))

fit <- auto.arima(x, stepwise = FALSE, approximation = FALSE)
cat("\n== auto.arima 定阶与拟合 ==\n"); print(summary(fit))

cat("\n== 残差 Ljung-Box 检验（滞后 12 阶）==\n")
print(Box.test(residuals(fit), lag = 12, type = "Ljung-Box"))

fc <- forecast(fit, h = 20)
cat("\n== 向前 20 期预测 ==\n"); print(fc)
png("out/ts_forecast.png", width = 900, height = 500)
plot(fc, main = "20 期预测")
dev.off()
cat("预测图已存 out/ts_forecast.png\n")
