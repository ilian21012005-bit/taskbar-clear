# Roadmap

Principe non negociable : **aucun processus resident**, **aucun hook global jeux**, **cout idle ~0** (DLL passive dans Explorer uniquement).

## Fait

- [x] TAP XAML Clear-only (BackgroundFill / BackgroundStroke)
- [x] `inject-once.exe` + tache logon (+30 s)
- [x] `visual-clean/` (registre HKCU, optionnel)
- [x] Checksums SHA-256, CI compile + lint
- [x] Documentation securite / installation publique

## Prochain (priorite perf)

| Priorite | Item | Perf | Statut |
|----------|------|------|--------|
| P0 | Tache **deverrouillage session** | Evenement only | Fait |
| P0 | Logs **Release** desactives (`NDEBUG`) | Moins I/O disque | Fait (rebuild DLL requis) |
| P1 | Timeout IXDE 35 s (TranslucentTB) | Boot only | Fait |
| P1 | Release GitHub + checksums | Confiance | Script `scripts/release-github.ps1` |
| P2 | `setup.ps1 -Silent` | — | Fait |

## Explicitement hors scope (perf)

- Worker WinEvent permanent (TranslucentTB)
- Blur / acrylic dynamique + IPC
- Windhawk mod / TaskbarX centrage
- WMI polling persistence (w11-theming-suite)
- GUI Electron ou tray icon

## Risques Windows

- MAJ 25H2+ peut casser XAML Diagnostics → suivre issues TranslucentTB et tester build preview.
