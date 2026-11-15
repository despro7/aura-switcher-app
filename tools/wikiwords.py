#!/usr/bin/env python3
"""Word counts from a Wikipedia dump, for languages FrequencyWords lacks (same "word count" lines as its lists).

Usage: curl -r 0-40000000 https://dumps.wikimedia.org/<code>wiki/latest/<code>wiki-latest-pages-articles.xml.bz2 \
         | bzcat | python3 tools/wikiwords.py <script> > <code>.txt      (a cut-off bz2 stream is fine)
script: cyr | lat | arm | deva
"""
import re, sys, collections, unicodedata

RANGES = {"cyr": [(0x400, 0x52F)], "arm": [(0x530, 0x58F)], "deva": [(0x900, 0x97F)],
          "lat": [(0x41, 0x24F), (0x1E00, 0x1EFF)]}
rg = RANGES[sys.argv[1]]
SEP = re.compile(r"[\s\d_.,;:!?()\[\]{}<>|\"/\\*#=+~^%$&@`«»“”„‘’–—…]+")
STRIP = [re.compile(p, re.S) for p in (r"\{\{[^{}]*\}\}", r"<ref[^>]*>.*?</ref>", r"<[^>]+>", r"https?://\S+",
                                       r"\[\[(?:File|Image|Category|Файл|Сурет|Санат|Категория)[^\]]*\]\]", r"&\w+;")]
# wiki markup that survives the stripping (template parameters, table and HTML attributes)
NOISE = set("ref name text wikitext x-wiki align center td tr th style width class colspan rowspan bgcolor border url title http https www cite web date accessdate publisher id file thumb right left px br div span small references gallery nowiki redirect infobox".split())
c = collections.Counter()
buf = ""
def flush(t):
    for p in STRIP: t = p.sub(" ", t)
    t = re.sub(r"\[\[[^\]|]*\|", " ", t)          # link target, keep the shown text
    for w in SEP.split(t.lower()):
        w = w.strip("'ʼ-")
        if len(w) >= 2 and all(unicodedata.category(ch)[0] in "LM" and any(a <= ord(ch) <= b for a, b in rg) or ch in "'ʼ-" for ch in w):
            c[w] += 1
for line in sys.stdin.buffer:
    buf += line.decode("utf-8", "ignore")
    if len(buf) > 2_000_000: flush(buf[:-2000]); buf = buf[-2000:]
flush(buf)
for w, n in c.most_common(50000 + len(NOISE)):
    if w not in NOISE: print(w, n)
