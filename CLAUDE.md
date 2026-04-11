# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Onebox is a Ruby gem that converts media URLs into HTML previews (YouTube, GitHub, Twitter, Amazon, etc.). Originally extracted from Discourse, it is no longer actively maintained here — development has moved into Discourse core.

## Commands

```bash
bundle install                # Install dependencies
bundle exec rspec             # Run all tests
bundle exec rspec spec/lib/onebox/engine/youtube_onebox_spec.rb  # Run a single test file
bundle exec rubocop           # Lint (uses rubocop-discourse rules)
bundle exec rake server       # Dev server at http://127.0.0.1:9000
```

## Architecture

**Engine pattern** — each supported URL type is an engine class that includes `Onebox::Engine`:

- `lib/onebox/engine.rb` — base module providing DSL: `matches_domain`, `matches_path`, `always_https`, `requires_iframe_origins`, `priority`
- `lib/onebox/engine/` — ~80 engine implementations (one per file, e.g. `youtube_onebox.rb`)
- Engines must implement `to_html` and typically override `data` (hash of extracted metadata) and `raw` (fetch/parse)

**Matcher** (`lib/onebox/matcher.rb`) — dispatches a URL to the correct engine by matching domain/path/content-type, sorted by priority.

**Preview** (`lib/onebox/preview.rb`) — user-facing API. `Onebox.preview(url)` returns a Preview that delegates to the matched engine and sanitizes output.

**Two rendering paths:**
1. Engines including `LayoutSupport` auto-render via Mustache templates in `lib/onebox/templates/{onebox_name}.mustache`
2. Engines can directly return HTML from `to_html`

**Mixins** (`lib/onebox/mixins/`) — shared behaviors like GitHub/Reddit auth headers, git blob rendering, Twitch parsing.

**Testing** uses RSpec with FakeWeb for HTTP mocking. Fixtures live in `spec/fixtures/`. Shared context `"engines"` and shared examples `"an engine"` / `"a layout engine"` provide common test scaffolding.

## Adding a new engine

1. Create `lib/onebox/engine/{name}_onebox.rb` — include `Engine` (and optionally `LayoutSupport`), declare `matches_domain`
2. Create `lib/onebox/templates/{name}.mustache` if using `LayoutSupport`
3. Add HTTP fixture to `spec/fixtures/`
4. Create `spec/lib/onebox/engine/{name}_onebox_spec.rb` using the shared engine context
