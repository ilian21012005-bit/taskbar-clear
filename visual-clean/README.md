# visual-clean

Profil **registre HKCU** pour desactiver animations et effets visuels superflus. Aucun processus resident.

**Conserve** `EnableTransparency` pour compatibilite TaskbarClear.

| Script | Action |
|--------|--------|
| `apply-visual-clean.ps1` | Applique + sauvegarde dans `%LOCALAPPDATA%\transparent-taskbar\visual-clean-backup.json` |
| `install-visual-clean-task.ps1` | Tache logon +5 s |
| `restore-visual-clean.ps1` | Restaure la sauvegarde |
| `uninstall-visual-clean-task.ps1` | Supprime la tache |

Sauvegarde automatique avant la premiere application.
