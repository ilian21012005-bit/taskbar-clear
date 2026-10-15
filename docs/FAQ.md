# FAQ

## La barre redevient opaque au demarrage

1. Verifiez `inject-at-logon.log` : `%LOCALAPPDATA%\transparent-taskbar\`
2. Lancez `.\scripts\verify-installation.ps1`
3. Exclusion Defender : `.\add-defender-exclusion.ps1` (admin)
4. Reinstallez : `.\install-task.ps1` puis `.\apply.cmd`

## Windows Defender / antivirus

`inject-once.exe` utilise `CreateRemoteThread` + `LoadLibrary` → faux positif frequent (`Bearfoos.A!ml`).

**Solution recommandee** : exclusion du dossier `bin\` via notre script (admin), ou compilez vous-meme depuis les sources.

Ne desactivez pas Defender entierement.

## Est-ce que ca impacte les FPS / jeux ?

Non en pratique :

- Aucun processus resident apres le logon
- Pas de hook global clavier/souris/jeu
- La DLL dans Explorer ne poll pas ; pas de boucle WinEvent

Le profil `visual-clean` ne touche qu'au registre (animations OFF).

## Explorer a redemarre (crash ou mise a jour)

Relancez `apply.cmd` ou attendez le deverrouillage session (tache Unlock).

## Puis-je utiliser avec TranslucentTB / Windhawk ?

Deconseille : double injection TAP / hooks dans Explorer. Choisissez **un seul** outil barre des taches.

## Build Windows supportes

Voir [COMPATIBILITY.md](COMPATIBILITY.md).

## Desinstaller completement

```powershell
.\uninstall-all.ps1 -RestartExplorer -RestoreVisualDefaults
```
