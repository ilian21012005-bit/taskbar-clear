# TaskbarClear

Barre des tâches **100 % transparente** (mode Clear) sur **Windows 11 24H2/25H2**, sans TranslucentTB ni Windhawk.

- **Aucun processus résident** — `inject-once.exe` s'exécute ~200 ms au logon, puis se termine
- **Aucun hook global** sur les fenêtres / jeux — seule une petite DLL reste dans `explorer.exe`
- **Impact frametime négligeable** vs un outil qui surveille focus / maximisation en permanence

## Comment ça marche

```text
Logon (+15 s) → inject-once.exe → LoadLibrary(TaskbarClear.dll) → exit
                                      ↓
                            explorer.exe (XAML TAP)
                                      ↓
                     BackgroundFill / BackgroundStroke → Transparent
```

Sur Win11 25H2, `SetWindowCompositionAttribute` seul ne suffit plus (barre XAML). TaskbarClear injecte un **TAP XAML Diagnostics** dans Explorer, comme TranslucentTB, mais **sans worker WinEvent** ni tray icon.

## Installation rapide (binaires précompilés)

1. Télécharge / clone ce repo
2. Ouvre PowerShell **sans admin** dans le dossier du projet
3. Installe la tâche planifiée :

```powershell
.\install-task.ps1
```

4. Applique tout de suite (optionnel) :

```cmd
apply.cmd
```

La barre devient transparente. Au prochain login, c'est automatique (+30 s).

**Windows Defender** peut classer `inject-once.exe` en trojan (faux positif `Bearfoos.A!ml`) et bloquer la tâche planifiée au démarrage. **Obligatoire une fois** :

```powershell
.\add-defender-exclusion.ps1   # demande admin
```

Log démarrage : `%LOCALAPPDATA%\transparent-taskbar\inject-at-logon.log`

## Profil visuel perf (animations OFF)

Scripts natifs **sans processus résident** — tweaks registre HKCU uniquement, gratuit en FPS.

```powershell
.\visual-clean\apply-visual-clean.ps1          # applique maintenant (+ sauvegarde)
.\visual-clean\install-visual-clean-task.ps1   # auto au logon (+5 s)
```

Désactive : animations système, ombres/fades, animations barre des tâches, Aero Peek, contenu fenêtre pendant le drag. **Conserve** `EnableTransparency` pour TaskbarClear.

Restauration :

```powershell
.\visual-clean\restore-visual-clean.ps1
.\visual-clean\uninstall-visual-clean-task.ps1 -RestoreDefaults
```

## Désinstallation

```powershell
.\uninstall-task.ps1 -RestartExplorer
```

Redémarre Explorer → la DLL est déchargée, la barre revient au rendu Windows par défaut.

## Compiler soi-même

Prérequis : **Visual Studio 2022 Build Tools** (C++ desktop + Windows SDK).

```powershell
.\native\build.ps1
```

Sortie : `bin\TaskbarClear.dll` + `bin\inject-once.exe`

Si la DLL est verrouillée dans Explorer :

```powershell
.\uninstall-task.ps1 -RestartExplorer
.\native\build.ps1
.\apply.cmd
```

## Fichiers

| Fichier | Rôle |
|---------|------|
| `bin/inject-once.exe` | Injecteur one-shot (CreateRemoteThread + LoadLibraryW) |
| `bin/TaskbarClear.dll` | TAP XAML Clear-only dans Explorer |
| `install-task.ps1` | Tâche planifiée `TransparentTaskbar-Once` (logon +15 s) |
| `apply.cmd` | Réinjecte manuellement |
| `uninstall-task.ps1` | Supprime la tâche (+ option restart Explorer) |

## Limitations

- **Windows 11 build ≥ 22621** (22H2+), testé sur **26200 (25H2)**
- Si **Explorer redémarre** en session, relance `apply.cmd`
- La tâche se déclenche au **logon**, pas au déverrouillage écran
- Pas de modes blur/acrylic dynamiques (Clear uniquement)
- Même fragilité que TranslucentTB si Microsoft change l'API XAML Diagnostics

## Pourquoi pas SWCA seul ?

Un script PowerShell `SetWindowCompositionAttribute` one-shot **ne produit aucun rendu visible** sur 25H2 : Explorer repeint un calque XAML opaque. Pire : appeler SWCA *en plus* du TAP recouvre le fond transparent d'un accent DWM gris (bug corrigé dans ce projet).

## Crédits

- TAP / injection : adapté de [w11-theming-suite](https://github.com/decarvalhoe/w11-theming-suite) (MIT)
- Inspiration architecture : [TranslucentTB](https://github.com/TranslucentTB/TranslucentTB) ExplorerTAP

## Licence

MIT — voir [LICENSE](LICENSE).
