# Installation

## Telechargement

**Recommande** — release avec binaires verifies :

1. [Derniere release](https://github.com/ilian21012005-bit/taskbar-clear/releases/latest)
2. Extraire le zip **ou** cloner le depot :

```powershell
git clone https://github.com/ilian21012005-bit/taskbar-clear.git
cd taskbar-clear
```

Verifier l'integrite :

```powershell
.\scripts\verify-checksums.ps1
```

## Prerequis

- Windows **11**, build **22621+**
- PowerShell **5.1+**
- Compte utilisateur standard
- **Admin** uniquement pour `add-defender-exclusion.ps1`

## Installation express

```powershell
.\setup.ps1
```

Equivalent silencieux (sans visual-clean ni prompts) :

```powershell
.\setup.ps1 -Silent
```

Avec profil animations OFF :

```powershell
.\install-all.ps1 -WithVisualClean
```

## Etape Defender (obligatoire en pratique)

Defender detecte souvent `inject-once.exe` (`Bearfoos.A!ml`) et **bloque le demarrage auto**.

```powershell
.\add-defender-exclusion.ps1
```

Acceptez l'elevation UAC. L'exclusion ne porte que sur le dossier `bin\` du projet.

Alternative : compilez vous-meme ([README](../README.md#compiler-soi-meme)) — le faux positif peut subsister.

## Demarrage automatique

`install-task.ps1` enregistre :

| Tache | Declencheur |
|-------|-------------|
| `TransparentTaskbar-Once` | Logon **+30 s** |
| `TransparentTaskbar-Unlock` | Deverrouillage session **+5 s** |

Aucun exe ne reste en memoire apres l'injection.

## Appliquer tout de suite

```cmd
apply.cmd
```

## Desinstallation

```powershell
.\uninstall-all.ps1 -RestartExplorer
```

Avec restauration registre visual-clean :

```powershell
.\uninstall-all.ps1 -RestartExplorer -RestoreVisualDefaults
```

## Mise a jour

1. Telecharger la nouvelle release ou `git pull`
2. `.\scripts\verify-checksums.ps1`
3. `.\uninstall-task.ps1` (optionnel)
4. `.\install-task.ps1 -SkipDefenderExclusion`
5. `.\apply.cmd`

Si Explorer verrouille la DLL : `.\uninstall-task.ps1 -RestartExplorer` avant de copier les nouveaux fichiers dans `bin\`.
