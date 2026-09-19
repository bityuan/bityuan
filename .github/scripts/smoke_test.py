#!/usr/bin/env python3
"""三平台共用的发布包冒烟测试（Linux / macOS / Windows 跑同一份代码）。

用法:
  python3 .github/scripts/smoke_test.py --node ./bityuan --cli ./bityuan-cli \
      --commit $(git rev-parse --short=8 HEAD) [--out version-linux.json] [--timeout 60]

流程:
  1. 启动节点二进制（cwd = 二进制所在目录，配置文件和它放一起）
  2. 轮询 `<cli> version`，解析返回的 JSON（chain33 的 VersionInfo）
  3. 校验字段并把结果写到 --out（供后续跨平台比对）

校验项（三平台完全一致）:
  * title == "bityuan"
  * app / chain33 是 x.y.z 形式
  * chain33 里含本次构建的短 commit（证明产物确实来自该 commit）
其余字段（localDb / chainID）只打印，不做断言。
"""
from __future__ import annotations

import argparse
import json
import os
import platform
import re
import subprocess
import sys
import time

SEMVER = re.compile(r"^\d+\.\d+\.\d+")


def extract_json(raw):
    """从 CLI 输出里抠出第一个 JSON 对象（容忍前后混入日志行）。"""
    start, end = raw.find("{"), raw.rfind("}")
    if start < 0 or end <= start:
        return None
    try:
        return json.loads(raw[start:end + 1])
    except json.JSONDecodeError:
        return None


def query_version(cli, prefix, timeout=20):
    try:
        proc = subprocess.run(prefix + [cli, "version"],
                              capture_output=True, text=True, timeout=timeout)
    except subprocess.TimeoutExpired:
        return None, "cli version 执行超时"
    except OSError as err:
        return None, "cli version 无法执行: %s" % err
    return extract_json(proc.stdout or ""), ((proc.stdout or "") + (proc.stderr or "")).strip()


def stop_node(proc):
    if proc.poll() is not None:
        return
    if os.name == "nt":
        subprocess.run(["taskkill", "/F", "/T", "/PID", str(proc.pid)],
                       capture_output=True, check=False)
    else:
        proc.terminate()
    try:
        proc.wait(timeout=15)
    except subprocess.TimeoutExpired:
        proc.kill()
        proc.wait(timeout=15)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--node", required=True, help="节点二进制路径")
    parser.add_argument("--cli", required=True, help="cli 二进制路径")
    parser.add_argument("--commit", required=True, help="本次构建的短 commit（至少 7 位）")
    parser.add_argument("--out", default=None, help="把结果 JSON 写到这里（可选）")
    parser.add_argument("--timeout", type=int, default=60, help="等待节点就绪的秒数")
    parser.add_argument("--runner-prefix", default="",
                        help="给二进制加前缀命令，例如 macOS 上跑 amd64 产物用 'arch -x86_64'")
    args = parser.parse_args()
    prefix = args.runner_prefix.split()

    node = os.path.abspath(args.node)
    cli = os.path.abspath(args.cli)
    for path in (node, cli):
        if not os.path.isfile(path):
            print("FAIL: 找不到文件 %s" % path)
            return 1

    owner = "%s-%s" % (platform.system(), platform.machine())
    print("[smoke] 平台 %s，启动节点 %s %s" % (owner, " ".join(prefix), node))
    proc = subprocess.Popen(prefix + [node], cwd=os.path.dirname(node),
                            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    try:
        info, raw = None, ""
        deadline = time.time() + args.timeout
        while time.time() < deadline:
            if proc.poll() is not None:
                print("FAIL: 节点进程已退出（exit=%s），无法做冒烟测试" % proc.returncode)
                return 1
            info, raw = query_version(cli, prefix)
            if info:
                break
            time.sleep(2)

        if not info:
            print("FAIL: %ss 内没取到版本信息，cli 最后输出:\n%s" % (args.timeout, raw))
            return 1

        print("[smoke] version = %s" % json.dumps(info, ensure_ascii=False, sort_keys=True))

        prefix = args.commit[:7].lower()
        problems = []
        if info.get("title") != "bityuan":
            problems.append("title 期望 'bityuan'，实际 %r" % info.get("title"))
        for field in ("app", "chain33"):
            if not SEMVER.match(info.get(field) or ""):
                problems.append("%s 不是 x.y.z 形式: %r" % (field, info.get(field)))
        if prefix not in (info.get("chain33") or "").lower():
            problems.append("chain33 里没有本次 commit %s: %r" % (prefix, info.get("chain33")))

        if args.out:
            with open(args.out, "w", encoding="utf-8") as fh:
                json.dump(dict(info, _platform=owner, _expected_commit=args.commit), fh,
                          ensure_ascii=False, indent=2, sort_keys=True)

        if problems:
            print("FAIL: " + "; ".join(problems))
            return 1
        print("[smoke] OK")
        return 0
    finally:
        stop_node(proc)


if __name__ == "__main__":
    sys.exit(main())
