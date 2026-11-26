# Agent instructions

Rails app. PostgreSQL, RSpec + factory_bot, RuboCop (rails-omakase), importmap.

## Hard gates

This repo enforces rules with git hooks (`.githooks/`, installed by `bin/setup`
via `git config core.hooksPath .githooks`). Running `bin/setup` in a fresh
checkout is required. The hooks block; they are not advice.

`pre-commit` rejects the commit when:

1. A secret is staged (`config/master.key`, `.env*`, `config/credentials/*.key`).
2. RuboCop fails on any staged Ruby file.
3. Rails code under `app/{models,controllers,policies,jobs,mailers,services,queries}`
   changed without a change under `spec/` — write the failing spec first, then
   commit spec and code together.
4. A migration is committed without the matching `db/schema.rb` change.

`pre-push` runs `bundle exec rubocop` and the full `bundle exec rspec`, and
blocks the push on any failure.

Do not use `--no-verify`, do not edit `.githooks/` to silence a failure, and do
not delete or weaken specs to get green. If a gate is wrong, surface it and ask.

## Workflow

Work test-first: write a failing spec, watch it fail, write the minimal code,
watch it pass, then commit. Run `bin/ci` before opening a PR.

Specs live in `spec/` (models, requests, system); factories in `spec/factories`.
Use `bin/rails`, `bin/rubocop`, and `bundle exec rspec` rather than bare commands.
