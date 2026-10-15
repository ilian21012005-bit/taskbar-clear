# Depannage

## Diagnostic en 30 secondes

```powershell
.\scripts\verify-installation.ps1
Get-Content "$env:LOCALAPPDATA\transparent-taskbar\inject-at-logon.log" -Tail 15
```

| Resultat tache | Signification |
|----------------|---------------|
| **0** | Derniere execution OK |
| **267011** | Tache jamais lancee (normal avant 1er logon) |
| Autre | Voir log + etapes ci-dessous |

## Barre opaque au demarrage

1. `.\add-defender-exclusion.ps1` (admin)
2. Verifier `bin\inject-once.exe` present (pas en quarantaine)
3. `.\install-task.ps1 -SkipDefenderExclusion`
4. `.\apply.cmd`
5. Reboot test : attendre **~45 s** apres login

Log attendu : `attempt=1/3 exit=0 OK TaskbarClear injecte...`

## Barre opaque apres verrouillage (Win+L)

La tache `TransparentTaskbar-Unlock` doit etre **Ready**. Sinon :

```powershell
.\install-task.ps1 -SkipDefenderExclusion
```

Puis deverrouillez ; ou `.\apply.cmd`.

## Explorer redemarre / crash

Normal apres certaines MAJ. **Une seule action** :

```cmd
apply.cmd
```

## inject-once.exe introuvable

Defender en quarantaine. Restaurer depuis :

- [Release GitHub](https://github.com/ilian21012005-bit/taskbar-clear/releases/latest)
- ou `git checkout main -- bin/`

Puis exclusion Defender.

## apply-at-logon.ps1 introuvable

Le repo local est incomplet. `git pull` ou re-cloner ; reinstaller la tache.

## Conflit TranslucentTB / Windhawk

Desinstallez l'autre outil ou TaskbarClear. **Une seule** injection TAP recommandee.

## Echec persistant

Ouvrez une issue [**Compatibilite Windows**](https://github.com/ilian21012005-bit/taskbar-clear/issues/new/choose) avec :

- Sortie `winver` (build)
- `verify-installation.ps1`
- 15 dernieres lignes du log inject
