# Vavaka

Canonical prayer dataset for the **Bahá'í Prayer App (Malagasy) — v2**.

All texts are in Malagasy. They were recovered from the v1 APK (via ADB + apktool) after the original
source code was lost, then transcribed into structured Markdown files. This repository is the source of
truth for the Flutter app that will be built on top of it.

---

## Structure

```
data/
  <id>-<category-slug>/
    vavaka-01.md
    vavaka-02.md
    ...
```

28 categories, each containing one or more prayer files. Every file follows the same shape:

```markdown
# <Category> — Vavaka <N>

<optional context note in parentheses>

<prayer text>

—<Author>
```

Authors are either **Bahá'u'lláh**, **'Abdu'l-Bahá**, or **The Báb**.

### Categories

| # | Slug | Translation |
|---|------|-------------|
| 01 | andro-manelanelana | Days of Há (intercalary days) |
| 02 | ankizy | Children |
| 03 | antenimiera-am-panahy | Spiritual Assembly |
| 04 | fahafatesana | Death |
| 05 | fahamarinana | Truthfulness |
| 06 | fahasitranana | Healing |
| 07 | famaranana-ny-fivoarian-ny-antenimiera-am-panahy | Closing of Spiritual Assembly |
| 08 | famelan-keloka | Forgiveness |
| 09 | fampianarana | Teaching |
| 10 | fanambadiana | Marriage |
| 11 | fanampiana-sy-fanatrehana | Aid and Assistance |
| 12 | fiarovana | Protection |
| 13 | fiderana-sy-fisaorana | Praise and Gratitude |
| 14 | fifadian-kanina | Fasting |
| 15 | firaisankina | Unity |
| 16 | fivahinianana-masina | Pilgrimage |
| 17 | fivoriana | Meetings / Gatherings |
| 18 | hariva | Evening |
| 19 | mangiran-dratsy | Midnight |
| 20 | maraina | Morning |
| 21 | martiora | Martyrs |
| 22 | naw-ruz | Naw-Rúz (Bahá'í New Year) |
| 23 | sedra-sy-fahasahiranana | Tests and Difficulties |
| 24 | takelak-i-ahmad | Tablet of Ahmad |
| 25 | takela-pahatsiarovana | Tablet of Remembrance |
| 26 | toetra-ara-panahy | Spiritual Virtues |
| 27 | vavaka-fahasitranana-lava | Long Healing Prayer |
| 28 | vavaka-ho-an-ny-firenen-drehetra | Prayer for all Nations |

---

## Next step

Normalise all Markdown files into a single canonical JSON dataset under `data/prayers.json`
(or one JSON file per category). Target schema:

```json
{
  "id": "string",
  "title": "string",
  "category": "string",
  "text": "string",
  "transliteration": null
}
```

This JSON will be bundled as a Flutter asset and loaded at app startup.

---

## Contributing

- Encoding: UTF-8. Preserve all accented Malagasy characters exactly.
- Do not translate or paraphrase prayer texts.
- Commit style: conventional commits (`feat:`, `fix:`, `chore:`, `docs:`), messages in English.
