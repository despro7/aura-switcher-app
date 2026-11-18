# Translation templates

`<code>.md` — one file per language for native-speaker proofreading (format `key = text`: App menu / Website / Update page). Texts are taken from the app and the site, so the files are generated, not edited by hand:

```
python3 tools/translations_gen.py
```

Run it after changing any translation (`tools/menu_i18n.py`, `site/i18n-more.js`, `site/shared.js`, `site/seo.js`, `site/update/index.html`) or the version. No dependencies; a second run changes nothing. Languages already proofread by a native speaker are listed in `REVIEWED` at the top of the script: their files are never overwritten, the script only prints the keys that differ from the sources. Help and questions: https://github.com/klbk/aura-switcher-app/issues/6
