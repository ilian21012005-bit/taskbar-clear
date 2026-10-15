# Changelog

Format base sur [Keep a Changelog](https://keepachangelog.com/fr/1.1.0/).

## [Unreleased]

## [1.2.1] - 2026-10-15

### Added

- Hook init TAP (`WH_CALLWNDPROC`) retire apres IXDE — fiabilite boot type TranslucentTB
- [docs/FAQ.md](docs/FAQ.md), banniere [docs/assets/social-preview.svg](docs/assets/social-preview.svg)

### Changed

- README one-liner, topics GitHub, description repo

## [1.2.0] - 2026-10-15

### Added

- `docs/RELATED_PROJECTS.md`, `ROADMAP.md`, `RELEASING.md`
- Retry logon, `install-all.ps1`, `docs/COMPATIBILITY.md`, badges README
- Declencheur **deverrouillage session**, `setup.ps1 -Silent`, `scripts/release-github.ps1`

### Changed

- DLL Release : **DebugLog desactive** (`NDEBUG`), timeout IXDE **35 s**
- Binaires sync release, `verify-installation` ignore 267011
- `install-task.ps1` : logon +30 s et unlock +5 s

## [1.1.0] - 2026-10-07

### Added

- Profil `visual-clean/` (animations OFF, registre HKCU)
- `apply-at-logon.ps1`, `add-defender-exclusion.ps1`, `setup.ps1`, scripts checksums
- Documentation publique : SECURITY, CONTRIBUTING, CODE_OF_CONDUCT, CI

### Changed

- Durcissement injecteur ; taches planifiees avec `WorkingDirectory`
- Tache logon +30 s via wrapper PowerShell + journal

### Fixed

- Demarrage auto casse si `apply-at-logon.ps1` absent ou si Defender met en quarantaine l'injecteur

## [1.0.0] - 2026-09-15

### Added

- TaskbarClear.dll (TAP XAML Clear-only)
- inject-once.exe (injection one-shot Explorer)
- Tache planifiee TransparentTaskbar-Once

[Unreleased]: https://github.com/ilian21012005-bit/taskbar-clear/compare/v1.2.1...HEAD
[1.2.1]: https://github.com/ilian21012005-bit/taskbar-clear/compare/v1.2.0...v1.2.1
[1.2.0]: https://github.com/ilian21012005-bit/taskbar-clear/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/ilian21012005-bit/taskbar-clear/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/ilian21012005-bit/taskbar-clear/releases/tag/v1.0.0
