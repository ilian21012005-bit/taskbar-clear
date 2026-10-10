# Changelog

Format base sur [Keep a Changelog](https://keepachangelog.com/fr/1.1.0/).

## [Unreleased]

### Added

- `setup.ps1`, `uninstall-all.ps1`, scripts de verification et checksums SHA-256
- Documentation publique : SECURITY, CONTRIBUTING, CODE_OF_CONDUCT
- CI GitHub Actions (build Windows)

### Changed

- Durcissement injecteur : chemin DLL strictement adjacent a `inject-once.exe`
- Taches planifiees avec `WorkingDirectory` explicite

## [1.1.0] - 2026-10-07

### Added

- Profil `visual-clean/` (animations OFF, registre HKCU)
- `apply-at-logon.ps1`, `add-defender-exclusion.ps1`
- Tache logon +30 s via wrapper PowerShell + journal

### Fixed

- Demarrage auto casse si `apply-at-logon.ps1` absent ou si Defender met en quarantaine l'injecteur

## [1.0.0] - 2026-09-15

### Added

- TaskbarClear.dll (TAP XAML Clear-only)
- inject-once.exe (injection one-shot Explorer)
- Tache planifiee TransparentTaskbar-Once

[Unreleased]: https://github.com/ilian21012005-bit/taskbar-clear/compare/v1.1.0...HEAD
[1.1.0]: https://github.com/ilian21012005-bit/taskbar-clear/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/ilian21012005-bit/taskbar-clear/releases/tag/v1.0.0
