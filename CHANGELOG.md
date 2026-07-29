# Changelog

## Unreleased

### Changed

- While a project runs, keyboard and text input with no shortcut, hook,
  or shown input widget no longer accumulates in the hidden console.
  It stays in the project route and has no effect. An explicit future
  route participant could provide a different fallback if needed.
