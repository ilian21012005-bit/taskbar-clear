# Compatibilite Windows

| Build | Version marketing | TaskbarClear Clear | Notes |
|-------|-------------------|--------------------|-------|
| 22621+ | Windows 11 22H2+ | Oui | TAP XAML requis |
| 26100 | 24H2 | Oui | Teste communautaire |
| 26200 | 25H2 | Oui | Teste mainteneur + [capture README](../docs/assets/clear-desktop-win11.png) |
| 22621 (21H2 barre classique) | 11 21H2 | Partiel | SWCA seul parfois suffisant ; TAP selon shell |

## Non supporte

- Windows 10 (barre non XAML 25H2-style)
- Serveur / sans shell Explorer interactif

## Apres une MAJ Windows

1. `.\scripts\verify-installation.ps1`
2. `.\apply.cmd`
3. Si echec IXDE : issue GitHub + build Windows + log `inject-at-logon.log`

Signalez les builds qui cassent pour mettre a jour ce tableau.
