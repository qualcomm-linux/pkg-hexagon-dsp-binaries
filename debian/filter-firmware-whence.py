#!/usr/bin/python3
# SPDX-License-Identifier: MIT
# Copyright (c) Qualcomm Technologies, Inc. and/or its subsidiaries.

import re, sys

def filter_whence(whence):
    with open(whence, encoding="utf-8") as file:
        pattern_dsp_1 = re.compile("^File: qcom/.*/(qc)?(a|c|gp)dsp.*.mbn")
        pattern_dsp_2 = re.compile("^File: qcom/.*/(qc)?slpi.*.mbn")
        pattern_dsp_3 = re.compile("^File: qcom/.*/.*dsp_dtb.*.(mbn|elf)")
        pattern_jsn_1 = re.compile("^RawFile: qcom/.*/.*dsp.*.jsn")
        pattern_jsn_2 = re.compile("^RawFile: qcom/.*/slpi.*.jsn")
        pattern_jsn_3 = re.compile("^RawFile: qcom/.*/battmgr.*.jsn")
        matched = True # output file header until the first section
        version = False
        header = ""

        for line in file:
            if line.startswith("File:") or line.startswith("RawFile:"):
                version = False
                if pattern_dsp_1.match(line) or \
                   pattern_dsp_2.match(line) or \
                   pattern_dsp_3.match(line) or \
                   pattern_jsn_1.match(line) or \
                   pattern_jsn_2.match(line) or \
                   pattern_jsn_3.match(line):
                    matched = True
                    version = True
                    yield header
                    header = ""
                    yield line
                continue

            if line.startswith("Version:"):
                if matched and version:
                    version = False
                    yield line
                continue

            if line.startswith("------"):
                if matched:
                    yield line
                    yield "\n"
                matched = False
                version = False
                header = ""
                continue

            if matched:
                yield line
            else:
                header += line


def main(args):
    if len(args) != 3:
        print("Usage: %s WHENCE-orig WHENCE" % args[0])

    with open(args[2], mode="wt", encoding="utf-8") as out:
        for line in filter_whence(args[1]):
            out.write(line)

if __name__ == "__main__":
    sys.exit(main(sys.argv))
