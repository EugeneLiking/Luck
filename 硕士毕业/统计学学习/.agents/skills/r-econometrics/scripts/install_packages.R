# BECO7010 课程 R 包安装脚本（清华 CRAN 镜像，用户级库免管理员）
# 用法：Rscript install_packages.R

lib <- file.path(Sys.getenv("LOCALAPPDATA"), "R", "win-library", "4.6")
dir.create(lib, recursive = TRUE, showWarnings = FALSE)
.libPaths(c(lib, .libPaths()))
cat("库路径:", lib, "\n")

options(repos = c(CRAN = "https://mirrors.tuna.tsinghua.edu.cn/CRAN"))
options(timeout = 600)

pkgs <- c(
  "FinTS",    # Tsay《Analysis of Financial Time Series》教材配套包（数据集+演示函数）
  "tseries",  # 时间序列基础：adf.test 单位根、garch 基础拟合
  "urca",     # 单位根/协整：ur.df、ca.jo
  "forecast", # ARIMA、auto.arima、预测
  "rugarch",  # ARCH/GARCH 完整工具箱（课程波动率模型主力）
  "ggplot2",  # 画图
  "xts", "zoo", # 时间序列数据结构
  "moments",  # 偏度/峰度/Jarque-Bera 检验（描述统计周）
  "lmtest"    # 回归诊断：bptest 异方差、dwtest 自相关
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) {
    cat("== 安装", p, "==\n")
    tryCatch(install.packages(p, lib = lib),
             error = function(e) cat("!! 安装失败", p, ":", conditionMessage(e), "\n"))
  } else {
    cat("已存在:", p, "\n")
  }
}

cat("\n== 验证 ==\n")
for (p in pkgs) cat(sprintf("%-10s %s\n", p, requireNamespace(p, quietly = TRUE)))
