# Vavaka — AI Agent Instructions

This file is the canonical source of instructions for AI coding assistants working in this repository.
It is intentionally tool-agnostic and can be used with Claude Code, OpenAI Codex, or any similar agent.

---

## Project overview

**Vavaka** is the data repository for the **Bahá'í Prayer App (Malagasy) — v2**, a Flutter mobile app
targeting Android and iOS. The v1 codebase was lost; this repo is the result of Phase 0 (data recovery):
prayer texts were extracted from the original APK (via ADB + apktool) and converted into structured
Markdown files grouped by category. This dataset is the source of truth for the new Flutter app.

---

## Repository layout

```
data/
  <id>-<category-slug>/   # one folder per prayer category (28 categories total)
    README.md             # prayer texts for that category in Malagasy
  README.md               # dataset overview
AGENTS.md                 # this file — AI agent instructions (tool-agnostic)
CLAUDE.md                 # Claude Code proxy → points to this file
```

Folder names follow the pattern `<zero-padded-number>-<malagasy-slug>`, e.g. `01-andro-manelanelana`.
Do not rename folders or change numbering without explicit instruction.

---

## Notion workspace

The authoritative project spec and task list live in Notion. Always check these before starting any
significant piece of work — they describe the current phase, remaining tasks, and acceptance criteria.

- **Project page:** https://app.notion.com/p/36489229f0a681268a6ac0fb2a05a95d
- **Task board** (inline on that page): lists all Phase 0–5 tasks with status checkboxes

Always check the Notion task board for the current phase and open tasks before starting work.

---

## Working conventions

- All source content is in Malagasy. Preserve the original text exactly; do not translate or paraphrase
  unless explicitly asked.
- Accented Malagasy characters must be preserved correctly (encoding: UTF-8).
- Do not generate placeholder or lorem-ipsum content.
- Do not add tooling, dependencies, or files outside `data/` without explicit instruction.
- Do not uninstall or modify anything on the physical Samsung device used for extraction.

---

## Flutter app context (for reference)

The data in this repo feeds a Flutter app with the following planned screens:

- **Home** — category list
- **CategoryDetail** — prayer list within a category
- **PrayerDetail** — reader with font size controls, share, and bookmark
- **Search** — local full-text search across all prayers
- **Settings** — theme and font size, persisted via SharedPreferences

State management: Riverpod or Provider. Navigation: go_router.
This context is useful when deciding how to structure the JSON schema.

---

## Commit style

- Use conventional commits: `feat:`, `fix:`, `chore:`, `docs:`.
- Keep commit messages in English even though content is in Malagasy.
- Scope commits narrowly — one category or one concern per commit.
