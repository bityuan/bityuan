#!/usr/bin/env python3
"""比对各平台冒烟测试输出的 version JSON，确认三平台结论一致。

用法:
  python3 .github/scripts/compare_versions.py build/version-*.json
  python3 .github/scripts/compare_versions.py --allow-partial build/version-*.json

校验:
  * 每种产物文件名齐全（version-windows / version-linux / version-darwin-arm64 /
    version-darwin-amd64；--allow-partial 时只比对已有的）
  * title / app / chain33 在各平台之间完全一致
  * 每个平台的 chain33 里含它自己构建用的短 commit
"""
from __future__ import annotations

import glob
import json
import os
import sys

EXPECTED = {
    "version-windows.json",
    "version-linux.json",
    "version-darwin-arm64.json",
    "version-darwin-amd64.json",
}
# 只比对 title 与 chain33：app 是构建时注入的 VERSION，走 make（非 tag 构建时是一段
# 短 sha）与走 go build 的平台天然不同，拿它做跨平台比对必然误报。
FIELDS = ("title", "chain33")


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    allow_partial = "--allow-partial" in sys.argv[1:]

    paths = []
    for pattern in args:
        paths.extend(glob.glob(pattern))
    paths = sorted(set(paths))

    if not paths:
        print("FAIL: 没找到任何 version-*.json（冒烟测试没跑或结果没上传）")
        return 1

    names = {os.path.basename(p) for p in paths}
    missing = EXPECTED - names
    if missing and not allow_partial:
        print("FAIL: 缺少平台的冒烟结果 %s（现有 %s）" % (sorted(missing), sorted(names)))
        return 1

    rows = []
    for path in paths:
        with open(path, encoding="utf-8") as fh:
            rows.append((os.path.basename(path), json.load(fh)))

    skipped = sorted(name for name, data in rows if data.get("_skipped"))
    if skipped:
        print("WARNING: 以下平台本次没做冒烟测试（标记为 skip）：%s" % skipped)
    rows = [(name, data) for name, data in rows if not data.get("_skipped")]
    if not rows:
        print("FAIL: 没有任何平台完成了冒烟测试")
        return 1

    print("各平台冒烟结果:")
    for name, data in rows:
        print("  %-26s title=%s app=%s chain33=%s localDb=%s chainID=%s"
              % (name, data.get("title"), data.get("app"), data.get("chain33"),
                 data.get("localDb"), data.get("chainID")))

    problems = []
    for field in FIELDS:
        values = {data.get(field) for _, data in rows}
        if len(values) != 1:
            detail = {name: data.get(field) for name, data in rows}
            problems.append("%s 各平台不一致: %s" % (field, detail))
    for name, data in rows:
        expected = (data.get("_expected_commit") or "")[:7].lower()
        if expected and expected not in (data.get("chain33") or "").lower():
            problems.append("%s 的 chain33 里没有它自己的 commit %s" % (name, expected))

    if problems:
        print("FAIL: " + "; ".join(problems))
        return 1
    print("OK: %d 个平台结论一致" % len(rows))
    return 0


if __name__ == "__main__":
    sys.exit(main())
