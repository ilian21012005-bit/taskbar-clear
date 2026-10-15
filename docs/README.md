# Documentation TaskbarClear

Hub pour installer, depanner et contribuer — **zero processus resident**.

| Guide | Contenu |
|-------|---------|
| [INSTALL.md](INSTALL.md) | Installation pas a pas, Defender, desinstallation |
| [FAQ.md](FAQ.md) | Questions frequentes (FPS, AV, conflits) |
| [TROUBLESHOOTING.md](TROUBLESHOOTING.md) | Barre opaque, taches, logs |
| [COMPATIBILITY.md](COMPATIBILITY.md) | Builds Windows testes |
| [RELATED_PROJECTS.md](RELATED_PROJECTS.md) | TranslucentTB, w11-theming-suite, etc. |
| [assets/README.md](assets/README.md) | Captures, social preview GitHub |

## Racine du depot

| Fichier | Role |
|---------|------|
| [../README.md](../README.md) | Vue d'ensemble + capture |
| [../SECURITY.md](../SECURITY.md) | Securite, injection, checksums |
| [../RELEASING.md](../RELEASING.md) | Publier une version |
| [../ROADMAP.md](../ROADMAP.md) | Evolutions prevues |
| [../visual-clean/README.md](../visual-clean/README.md) | Profil animations OFF |

## Commandes rapides

```powershell
.\setup.ps1                          # installe tout (interactif)
.\setup.ps1 -Silent                  # sans questions
.\add-defender-exclusion.ps1         # admin — fortement recommande
.\scripts\verify-installation.ps1    # diagnostic
.\apply.cmd                          # Clear maintenant
```

Logs : `%LOCALAPPDATA%\transparent-taskbar\inject-at-logon.log`
