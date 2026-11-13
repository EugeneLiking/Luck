# Week 12 因子模型模板：PCA 主成分 + 因子分析
# 用法：Rscript wk12_factor.R [多变量.csv]
#   无参数时生成带 2 因子结构的模拟数据演示；CSV 时使用全部数值列。
lib <- file.path(Sys.getenv("LOCALAPPDATA"), "R", "win-library", "4.6")
if (dir.exists(lib)) .libPaths(c(lib, .libPaths()))

args <- commandArgs(trailingOnly = TRUE)
dir.create("out", showWarnings = FALSE)

if (length(args) >= 1) {
  df <- read.csv(args[1])
  df <- df[sapply(df, is.numeric)]
} else {
  set.seed(7)
  n <- 500
  f1 <- rnorm(n); f2 <- rnorm(n)
  L <- matrix(runif(10 * 2, 0.5, 0.9), ncol = 2)
  df <- as.data.frame(f1 %*% t(L[, 1]) + f2 %*% t(L[, 2]) +
                        matrix(rnorm(n * 10, sd = 0.3), ncol = 10))
  names(df) <- paste0("x", 1:10)
  cat("内置演示：10 变量、2 因子结构模拟数据\n")
}
df <- df[complete.cases(df), ]
k <- min(3, ncol(df))

cat("\n== PCA 主成分分析 ==\n")
pca <- prcomp(df, scale. = TRUE)
print(summary(pca))
cat("\n载荷（前", k, "个主成分）：\n"); print(round(pca$rotation[, 1:k], 3))

cat("\n== 因子分析（factanal, 2 因子）==\n")
fa <- factanal(df, factors = 2, rotation = "varimax")
print(fa)

png("out/factor_scree.png", width = 800, height = 500)
plot(1:length(pca$sdev), pca$sdev^2, type = "b", xlab = "主成分", ylab = "方差",
     main = "碎石图（Scree Plot）")
dev.off()
cat("碎石图已存 out/factor_scree.png\n")
