# TaskbarClear

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Windows 11](https://img.shields.io/badge/Windows-11%20(22H2%2B)-0078D4)](https://www.microsoft.com/windows)

Barre des taches **100 % transparente** (mode Clear) sur **Windows 11**, sans TranslucentTB ni Windhawk.

- **Zero processus resident** — injection ~200 ms au logon, puis exit
- **Pas de hook global** sur fenetres / jeux — petite DLL dans `explorer.exe` uniquement
- **Optionnel** : profil `visual-clean` (animations OFF, registre HKCU)

> **Avertissement** : technique d'injection DLL dans Explorer (API non officielle Microsoft). Lisez [SECURITY.md](SECURITY.md) avant installation.

## Prerequis

| Element | Detail |
|---------|--------|
| OS | Windows 11, build **22621+** (22H2+) |
| Droits | Utilisateur standard (admin **uniquement** pour exclusion Defender) |
| Antivirus | Faux positif frequent sur `inject-once.exe` — voir ci-dessous |

## Installation (recommandee)

```powershell
git clone https://github.com/ilian21012005-bit/taskbar-clear.git
cd taskbar-clear
.\setup.ps1
```

Le script :

1. Verifie OS et binaires
2. Propose l'exclusion Defender (fortement recommande)
3. Installe la tache `TransparentTaskbar-Once` (logon +30 s)
4. Applique Clear immediatement

### Etape Defender (important)

Windows Defender peut classer `inject-once.exe` en trojan (`Bearfoos.A!ml`) et **empecher le demarrage auto** :

```powershell
.\add-defender-exclusion.ps1   # admin, une fois
```

### Installation manuelle

```powershell
.\add-defender-exclusion.ps1    # admin
.\install-task.ps1
.\apply.cmd
```

## Desinstallation

```powershell
.\uninstall-all.ps1 -RestartExplorer
```

Avec restauration des effets visuels (si `visual-clean` installe) :

```powershell
.\uninstall-all.ps1 -RestartExplorer -RestoreVisualDefaults
```

## Verifier que tout fonctionne

```powershell
.\scripts\verify-installation.ps1
.\scripts\verify-checksums.ps1
```

Journal logon : `%LOCALAPPDATA%\transparent-taskbar\inject-at-logon.log`

## Comment ca marche

```text
Logon (+30 s) → apply-at-logon.ps1 → inject-once.exe → LoadLibrary(TaskbarClear.dll) → exit
                                                      ↓
                                            explorer.exe (TAP XAML)
                                                      ↓
                               BackgroundFill / BackgroundStroke → Transparent
```

Sur Win11 25H2, `SetWindowCompositionAttribute` seul ne suffit plus (barre XAML opaque).

## Profil visual-clean (optionnel)

Tweaks registre **sans processus resident** :

```powershell
.\visual-clean\apply-visual-clean.ps1
.\visual-clean\install-visual-clean-task.ps1
```

Restauration : `.\visual-clean\restore-visual-clean.ps1`

## Compiler soi-meme

Prerequis : **VS 2022 Build Tools** (C++ + Windows SDK).

```powershell
.\native\build.ps1
.\scripts\update-checksums.ps1
.\apply.cmd
```

## Structure du depot

| Chemin | Role |
|--------|------|
| `setup.ps1` | Installation guidee |
| `bin/` | Binaires precompiles + `CHECKSUMS.sha256` |
| `install-task.ps1` / `apply-at-logon.ps1` | Demarrage automatique |
| `visual-clean/` | Profil performances visuelles |
| `scripts/` | Verification install / checksums |
| `native/` | Sources C++ |

## Limitations

- Si **Explorer redemarre**, relancez `apply.cmd`
- Tache au **logon**, pas au deverrouillage ecran seul
- Clear uniquement (pas blur/acrylic dynamique)
- Peut casser apres une MAJ Windows majeure

## Securite et confiance

- [SECURITY.md](SECURITY.md) — injection, Defender, integrite
- [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) — credits MIT
- [CONTRIBUTING.md](CONTRIBUTING.md) — contributions

## Credits

- TAP / injection : derive de [w11-theming-suite](https://github.com/decarvalhoe/w11-theming-suite) (MIT)
- Inspiration : [TranslucentTB](https://github.com/TranslucentTB/TranslucentTB)

## Licence

MIT — voir [LICENSE](LICENSE).
