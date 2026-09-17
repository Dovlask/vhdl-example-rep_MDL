#!/usr/bin/env python3
"""Gera um resumo em Markdown dos resultados do cocotb (results_*.xml)."""
import glob
import os
import sys
import xml.etree.ElementTree as ET

here = os.path.dirname(os.path.abspath(__file__))
ORDER = ["ula", "reg_file", "arith_machine", "demux"]


def key(path):
    name = os.path.basename(path)[len("results_"):-len(".xml")]
    return (ORDER.index(name) if name in ORDER else len(ORDER), name)


files = sorted(glob.glob(os.path.join(here, "results_*.xml")), key=key)

print("## Resultados dos testes cocotb\n")
if not files:
    print("Nenhum arquivo de resultados encontrado.")
    sys.exit(0)

total = failed = 0
print("| DUT | Teste | Resultado |")
print("|---|---|---|")
for f in files:
    dut = os.path.basename(f)[len("results_"):-len(".xml")]
    for tc in ET.parse(f).getroot().iter("testcase"):
        total += 1
        bad = tc.find("failure") is not None or tc.find("error") is not None
        skipped = tc.find("skipped") is not None
        failed += bad
        status = "❌ FAIL" if bad else ("⏭️ SKIP" if skipped else "✅ PASS")
        print(f"| `{dut}` | `{tc.get('name')}` | {status} |")

print(f"\n**{total - failed}/{total} testes passaram.**")
