# Week 4-5 线性回归模板（含异方差/自相关诊断）
# 用法：Rscript wk04_05_regression.R [数据.csv]
#   无参数时用内置模拟数据演示；CSV 时第一列为 y、其余为解释变量。
lib <- file.path(Sys.getenv("LOCALAPPDATA"), "R", "win-library", "4.6")
if (dir.exists(lib)) .libPaths(c(lib, .libPaths()))
suppressMessages(library(lmtest))

args <- commandArgs(trailingOnly = TRUE)
dir.create("out", showWarnings = FALSE)

if (length(args) >= 1) {
  df <- read.csv(args[1])
  df <- df[complete.cases(df), ]
  form <- as.formula(paste(names(df)[1], "~", paste(names(df)[-1], collapse = "+")))
} else {
  set.seed(1)
  n <- 300
  x1 <- rnorm(n); x2 <- rnorm(n)
  y <- 2 + 3*x1 - 1.5*x2 + rnorm(n)
  df <- data.frame(y, x1, x2)
  form <- y ~ x1 + x2
  cat("内置演示数据：y = 2 + 3*x1 - 1.5*x2 + 噪声\n")
}

fit <- lm(form, data = df)
cat("\n== 回归结果 ==\n"); print(summary(fit))

cat("\n== 异方差检验 (Breusch-Pagan) ==\n"); print(bptest(fit))
cat("\n== 残差自相关检验 (Durbin-Watson) ==\n"); print(dwtest(fit))

png("out/regression_diagnostics.png", width = 1000, height = 900)
par(mfrow = c(2, 2)); plot(fit)
dev.off()
cat("\n诊断图已存 out/regression_diagnostics.png\n")

# 多元回归 VIF（自变量 ≥2 时）
if (length(coef(fit)) > 2) {
  xs <- model.matrix(fit)[, -1, drop = FALSE]
  vif <- sapply(seq_len(ncol(xs)), function(j) {
    1 / (1 - summary(lm(xs[, j] ~ xs[, -j]))$r.squared)
  })
  cat("\nVIF：\n"); print(round(vif, 3))
}
