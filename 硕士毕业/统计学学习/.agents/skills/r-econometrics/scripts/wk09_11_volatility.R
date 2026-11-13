# Week 9-11 波动率模型模板：ARCH 效应检验、GARCH 拟合、VaR 计算
# 用法：Rscript wk09_11_volatility.R [收益率.csv]
#   无参数时模拟 GARCH(1,1) 序列演示（对应 Week9 的 ARCH 拟合输出）；
#   CSV 时第一列为对数收益率序列。
lib <- file.path(Sys.getenv("LOCALAPPDATA"), "R", "win-library", "4.6")
if (dir.exists(lib)) .libPaths(c(lib, .libPaths()))
suppressMessages({library(FinTS); library(rugarch)})

args <- commandArgs(trailingOnly = TRUE)
dir.create("out", showWarnings = FALSE)

if (length(args) >= 1) {
  df <- read.csv(args[1])
  x <- as.numeric(df[[1]])
  cat("数据文件:", args[1], "  序列长度:", length(x), "\n")
} else {
  set.seed(42)
  spec0 <- ugarchspec(variance.model = list(garchOrder = c(1, 1)),
                      mean.model = list(armaOrder = c(0, 0), include.mean = TRUE),
                      fixed.pars = list(mu = 0.0005, omega = 0.00002,
                                        alpha1 = 0.10, beta1 = 0.85))
  x <- as.numeric(ugarchpath(spec0, n.sim = 1500)@path$seriesSim)
  cat("内置演示：GARCH(1,1) 模拟序列（alpha=0.10, beta=0.85, n=1500）\n")
}
x <- x[is.finite(x)]

cat("\n== ARCH 效应检验（FinTS::ArchTest，对应 Tsay 教材）==\n")
print(ArchTest(x, lags = 12))

spec <- ugarchspec(variance.model = list(model = "sGARCH", garchOrder = c(1, 1)),
                   mean.model = list(armaOrder = c(0, 0), include.mean = TRUE))
fit <- ugarchfit(spec = spec, data = x, solver = "hybrid")
cat("\n== GARCH(1,1) 拟合 ==\n"); print(fit)

png("out/garch_fit.png", width = 1000, height = 800)
par(mfrow = c(2, 1))
plot(as.numeric(x), type = "l", main = "收益率序列", ylab = "r_t")
plot(as.numeric(sigma(fit)), type = "l", col = "red", main = "GARCH 条件波动率", ylab = "sigma_t")
dev.off()
cat("拟合图已存 out/garch_fit.png\n")

# VaR（下周 VaR 计算：用拟合的条件分布；演示取正态假设 + 历史分位数对照）
mu <- as.numeric(fitted(fit)); sg <- as.numeric(sigma(fit))
n <- length(x)
alpha <- c(0.01, 0.05)
var_garch <- mu[n] + sg[n] * qnorm(alpha)
var_hist <- quantile(x, alpha)
cat("\n== 下一期 VaR（基于 GARCH 条件分布，正态假设）==\n")
print(setNames(round(var_garch, 6), paste0("VaR_", alpha)))
cat("历史分位数法对照：\n"); print(round(var_hist, 6))
