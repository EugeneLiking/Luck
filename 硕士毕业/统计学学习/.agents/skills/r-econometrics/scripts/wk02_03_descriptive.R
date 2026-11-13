# Week 2-3 单变量/多变量数据分析模板
# 用法：Rscript wk02_03_descriptive.R [数据.csv]
#   无参数时用内置模拟数据演示；有 CSV 时分析第一个（单变量）或全部（多变量）数值列。
lib <- file.path(Sys.getenv("LOCALAPPDATA"), "R", "win-library", "4.6")
if (dir.exists(lib)) .libPaths(c(lib, .libPaths()))
suppressMessages({library(moments); library(tseries)})

args <- commandArgs(trailingOnly = TRUE)
dir.create("out", showWarnings = FALSE)

if (length(args) >= 1) {
  df <- read.csv(args[1])
  x <- df[[1]]
  cat("数据文件:", args[1], "  变量:", names(df)[1], "\n")
} else {
  set.seed(42)
  x <- rt(500, df = 5)          # 厚尾分布演示
  cat("内置演示数据：t 分布(df=5) 500 个样本\n")
}

x <- x[is.finite(x)]
cat("\n== 描述统计 ==\n")
print(summary(x))
cat(sprintf("均值=%.4f  标准差=%.4f  偏度=%.4f  峰度=%.4f\n",
            mean(x), sd(x), skewness(x), kurtosis(x)))
cat("\n== Jarque-Bera 正态性检验 ==\n"); print(jarque.bera.test(x))

png("out/descriptive_hist_qq.png", width = 1000, height = 480)
par(mfrow = c(1, 2))
hist(x, breaks = 40, col = "lightblue", main = "直方图", xlab = "x")
qqnorm(x); qqline(x, col = "red")
dev.off()
cat("\n图已存 out/descriptive_hist_qq.png\n")

# 多变量（CSV 多列时）
if (length(args) >= 1) {
  numdf <- df[sapply(df, is.numeric)]
  if (ncol(numdf) >= 2) {
    cat("\n== 相关系数矩阵 ==\n"); print(round(cor(numdf, use = "pairwise.complete.obs"), 4))
    png("out/descriptive_pairs.png", width = 900, height = 900)
    pairs(numdf, main = "散点图矩阵")
    dev.off()
    cat("散点图矩阵已存 out/descriptive_pairs.png\n")
  }
}
