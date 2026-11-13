# -*- coding: utf-8 -*-
"""symbolic-math skill 的 SymPy 命令行入口。

用法：
  python sympy_eval.py <操作> "<表达式>" [--var x] [--point 0] [--order 6] [--save out.md]

操作：simplify(默认) / expand / factor / diff / integrate / series / solve / matrix / latex
示例：
  python sympy_eval.py diff "x**2 * exp(x)" --var x
  python sympy_eval.py matrix "[[1,2],[3,4]]"
"""
import argparse
import sys

import sympy as sp
from sympy.parsing.sympy_parser import (
    parse_expr, standard_transformations,
    implicit_multiplication_application, convert_xor,
)

# 宽松语法：隐式乘法（2x）、^ 幂号
TRANSFORMS = standard_transformations + (implicit_multiplication_application, convert_xor)


def parse(text):
    return parse_expr(text, transformations=TRANSFORMS)


def main():
    ap = argparse.ArgumentParser(description="SymPy 符号计算")
    ap.add_argument("op", nargs="?", default="simplify",
                    choices=["simplify", "expand", "factor", "diff", "integrate",
                             "series", "solve", "matrix", "latex"])
    ap.add_argument("expr")
    ap.add_argument("--var", default="x")
    ap.add_argument("--point", default="0")
    ap.add_argument("--order", type=int, default=6)
    ap.add_argument("--save", help="把结果追加写入 markdown 文件")
    args = ap.parse_args()

    var = sp.Symbol(args.var)
    lines = []

    def emit(title, obj):
        plain = sp.sstr(obj)
        tex = sp.latex(obj)
        lines.append(f"**{title}**\n\n```text\n{plain}\n```\n\nLaTeX：`{tex}`\n")

    if args.op == "matrix":
        m = sp.Matrix(parse(args.expr))
        lines.append(f"矩阵：\n\n```text\n{sp.sstr(m)}\n```\n")
        emit("行列式", m.det())
        if m.det() != 0:
            emit("逆矩阵", m.inv())
        ev = m.eigenvals()
        lines.append("**特征值（含重数）**\n\n```text\n" + sp.sstr(ev) + "\n```\n")
        lines.append("**特征多项式**\n\n```text\n" + sp.sstr(m.charpoly().as_expr()) + "\n```\n")
    else:
        e = parse(args.expr)
        if args.op == "simplify":
            emit("化简结果", sp.simplify(e))
        elif args.op == "expand":
            emit("展开结果", sp.expand(e))
        elif args.op == "factor":
            emit("因式分解", sp.factor(e))
        elif args.op == "diff":
            emit(f"对 {args.var} 求导", sp.simplify(sp.diff(e, var)))
        elif args.op == "integrate":
            emit(f"对 {args.var} 积分", sp.integrate(e, var))
        elif args.op == "series":
            pt = parse(args.point)
            emit(f"{args.var} 在 {args.point} 处的 {args.order} 阶级数",
                 sp.series(e, var, pt, args.order))
        elif args.op == "solve":
            emit(f"方程 {sp.sstr(e)} = 0 的解", sp.solve(e, var))
        elif args.op == "latex":
            lines.append(f"`{sp.latex(e)}`\n")

    out = "\n".join(lines)
    print(out)
    if args.save:
        with open(args.save, "a", encoding="utf-8") as f:
            f.write(f"\n### `{args.op} {args.expr}`\n\n{out}\n")


if __name__ == "__main__":
    sys.exit(main())
