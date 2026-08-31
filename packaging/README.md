# Frost packages

This repository owns the Frost PKGBUILDs, local signed pacman repository tooling, package-selection evidence, and package ownership tests.

It has a new history and no donor remote. Builds must use an explicit Frost source archive and may not clone or download donor code.

The initial private repository is local and consumed through `file://`. The Phase 2 `frost` package owns only Frost-namespaced session integration and fixed upstream runtime dependencies; the final package selection and both `frost-settings` and `frost-meta` remain blocked until their gates. Public mirrors and release infrastructure are outside the current phase.
