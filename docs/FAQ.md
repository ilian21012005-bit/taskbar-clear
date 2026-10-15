# FAQ

## C'est quoi TaskbarClear ?

Un outil **Clear-only** pour la barre des taches Windows 11 : fond XAML transparent, **sans** processus qui tourne en permanence apres le logon.

## Est-ce que ca impacte les FPS / jeux ?

**Non en pratique.**

- Pas de processus resident (injecteur ~200 ms puis exit)
- Pas de hook global souris/clavier/jeu
- DLL passive dans Explorer (pas de boucle WinEvent)

Le module optionnel `visual-clean` ne modifie que le registre (animations OFF).

## Pourquoi Windows Defender bloque ?

`inject-once.exe` utilise `CreateRemoteThread` + `LoadLibrary` dans `explorer.exe` — pattern proche de certains malwares.

**Solution** : `.\add-defender-exclusion.ps1` (dossier `bin\` uniquement) ou compilation locale + confiance explicite.

## Clear vs TranslucentTB / Windhawk ?

| | TaskbarClear | TranslucentTB |
|---|--------------|---------------|
| Process resident | Non | Oui (worker) |
| Blur / acrylic | Non | Oui |
| Clear | Oui | Oui |
| Complexite | Minimale | Elevee |

Ne combinez pas plusieurs injecteurs TAP.

## La barre redevient opaque ?

Voir [TROUBLESHOOTING.md](TROUBLESHOOTING.md).

## Puis-je compiler sans faire confiance aux binaires ?

Oui :

```powershell
.\native\build.ps1
.\scripts\update-checksums.ps1
```

Prerequis : VS 2022 Build Tools + Windows SDK.

## Ou sont les logs ?

| Fichier | Contenu |
|---------|---------|
| `%LOCALAPPDATA%\transparent-taskbar\inject-at-logon.log` | Demarrage auto |
| `%LOCALAPPDATA%\transparent-taskbar\TaskbarClear.log` | Debug DLL (**Debug** builds seulement) |

## Desinstallation complete ?

```powershell
.\uninstall-all.ps1 -RestartExplorer -RestoreVisualDefaults
```

## C'est supporte par Microsoft ?

Non. API XAML Diagnostics non documentee ; peut casser apres une MAJ Windows.

## Signaler un bug ou une incompatibilite

[New issue → choisir un modele](https://github.com/ilian21012005-bit/taskbar-clear/issues/new/choose)
