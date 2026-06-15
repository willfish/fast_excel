# AGENTS.md - fast_excel / uber_fast_excel

This repository is the maintained `uber_fast_excel` gem. It keeps the upstream
Ruby API and `FastExcel` namespace, while publishing under the
`uber_fast_excel` gem name.

## Repository Shape

- Source compatibility matters: keep `require "fast_excel"` and the
  `FastExcel` namespace working unless the user explicitly asks for a breaking
  change.
- `lib/uber_fast_excel.rb` is the gem-name require path and should remain a thin
  compatibility entrypoint.
- The gemspec is `uber_fast_excel.gemspec`; do not reintroduce
  `fast_excel.gemspec` as the package identity.
- `libxlsxwriter/` is vendored C code. Avoid broad vendored refreshes unless the
  change is explicitly about syncing libxlsxwriter and includes build
  verification on the supported platforms.
- Prefer focused PRs. When porting from `Paxa/fast_excel`, extract small,
  reviewable fixes rather than merging abandoned branches wholesale.

## Development Environment

- Use the Nix shell through direnv:

  ```sh
  direnv exec . bundle exec rake test
  ```

- If a tool is missing, use ephemeral Nix (`nix shell nixpkgs#<tool> -c ...`)
  rather than installing globally or adding temporary tooling to the project.
- The local shell config comes from `flake.nix` and `.envrc`; keep them aligned
  with the style used in `../trade-tariff-backend`.

## Commits

- Use conventional commit subjects. CI runs Cocogitto against every commit in
  the pushed or PR range.
- Commit format:

  ```text
  <type>(optional-scope): short imperative description

  Issue: No ticket/issue
  ```

- If there is a real issue or ticket, put it in the footer/body, not the
  subject.
- Add `Co-authored-by:` trailers when a change incorporates meaningful upstream
  work. For the missing worksheet lookup fix, preserve:

  ```text
  Co-authored-by: Amber Cronin <amber@amber.vision>
  ```

- Do not squash PRs in a way that hides individual non-conforming commits. The
  repository expects every commit to pass the conventional commit check.

## Testing And Verification

- The main verification command is:

  ```sh
  direnv exec . bundle exec rake test
  ```

- Run examples when changes touch public API behavior or bindings:

  ```sh
  direnv exec . bundle exec rake examples
  ```

- Run performance validation when changing write paths, benchmarks, or README
  speed claims:

  ```sh
  direnv exec . bundle exec rake perf:validate
  ```

- SimpleCov is enabled for the test suite and should stay at or above the
  configured 95% gate. Avoid adding untested public API surface.
- CI tests Ubuntu, macOS, and Windows across Ruby 2.7, 3.1, 3.3, and 3.4.

## Releases And Tags

- Releases are tag-driven. Tags must use the `v` prefix, for example `v0.6.0`.
- `cog.toml` is configured with `tag_prefix = "v"` and writes release notes to
  `CHANGELOG.md`.
- Before tagging, ensure:

  ```sh
  direnv exec . bundle exec rake test
  direnv exec . bundle exec rake examples
  direnv exec . bundle exec rake perf:validate
  gem build uber_fast_excel.gemspec
  ```

- The release workflow publishes with `rubygems/release-gem@v1` and requires a
  RubyGems trusted publisher configured for this repository workflow.
- If a commit under a release tag is rewritten, retag locally and update the
  remote tag intentionally. Do not leave `master` and `vX.Y.Z` pointing at
  different histories for the same release.

## Dependencies And CI

- Keep GitHub Actions and Bundler dependencies current through Dependabot.
- Action versions are intentionally pinned to explicit versions in workflow
  files; update them deliberately and verify CI.
- This repo does not use Sonar. Do not add Sonar config unless the user
  explicitly asks for it.
- Octocov is the GitHub coverage reporting integration; SimpleCov is the Ruby
  coverage library enforcing local suite coverage.

## GitHub Workflow

- The maintained repository is `willfish/fast_excel`; the original abandoned
  upstream is `Paxa/fast_excel`.
- Do not comment on upstream issues or PRs unless the user explicitly asks.
- When reviewing upstream open PRs, classify them as:
  - already incorporated,
  - safe to port as a focused fix,
  - useful tests/docs only,
  - too broad and requiring a separate design/release plan.
- Open PRs against `willfish/fast_excel` for fixes and merge them after checks
  are green.

## Attribution

- `CONTRIBUTORS.md` records maintainer and contributor acknowledgement.
- The Trade Tariff Core group should remain acknowledged there.
- Preserve credit for upstream contributors when their work informs this fork,
  even when the final implementation is adapted rather than copied.
