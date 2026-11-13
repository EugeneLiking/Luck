# 环境自检：R 版本 + 课程所需包是否齐全
lib <- file.path(Sys.getenv("LOCALAPPDATA"), "R", "win-library", "4.6")
if (dir.exists(lib)) .libPaths(c(lib, .libPaths()))
cat("R 版本:", R.version.string, "\n")
cat("库路径:\n"); print(.libPaths())

pkgs <- c("FinTS", "tseries", "urca", "forecast", "rugarch",
          "ggplot2", "xts", "zoo", "moments", "lmtest")
cat("\n包检查：\n")
for (p in pkgs) {
  ok <- requireNamespace(p, quietly = TRUE)
  v <- if (ok) as.character(packageVersion(p)) else "-"
  cat(sprintf("%-10s %s %s\n", p, ifelse(ok, "OK", "缺失"), v))
}
