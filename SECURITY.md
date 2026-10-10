# Politique de securite

## Portee

TaskbarClear modifie **uniquement** le processus `explorer.exe` local pour rendre la barre des taches transparente. Le depot ne contient **aucune** telemetrie, connexion reseau, ni collecte de donnees.

## Comportement sensible (a connaitre avant installation)

| Composant | Action | Risque |
|-----------|--------|--------|
| `inject-once.exe` | `CreateRemoteThread` + `LoadLibraryW` dans Explorer | Technique d'injection DLL — similaire a certains malwares (faux positifs AV) |
| `TaskbarClear.dll` | TAP XAML Diagnostics dans Explorer | API non documentee Microsoft ; peut cesser de fonctionner apres une MAJ Windows |
| `add-defender-exclusion.ps1` | Exclusion Defender sur `bin\` | Reduit la surveillance AV sur ce dossier — **a n'utiliser que si vous faites confiance a ce depot** |
| `visual-clean/` | Tweaks registre HKCU | Reversible via `restore-visual-clean.ps1` |

## Mesures de securite implementees

- L'injecteur ne charge **que** `TaskbarClear.dll` situe dans le **meme dossier** que `inject-once.exe` (verification de chemin canonique).
- Aucun telechargement ni execution de code distant dans les scripts d'installation.
- Taches planifiees en **RunLevel Limited** (meme niveau d'integrite qu'Explorer).
- Scripts PowerShell en `Set-StrictMode` ; pas de secrets dans le depot.

## Integrite des binaires

Verifiez les SHA-256 publies dans `bin/CHECKSUMS.sha256` :

```powershell
.\scripts\verify-checksums.ps1
```

En cas de doute, **compilez vous-meme** avec `native\build.ps1` plutot que d'utiliser les binaires precompiles.

## Signaler une vulnerabilite

**Ne pas** ouvrir d'issue publique pour un probleme de securite.

1. Ouvrez un [GitHub Security Advisory](https://github.com/ilian21012005-bit/taskbar-clear/security/advisories/new) (depot prive)  
   **ou** contactez le mainteneur via GitHub Discussions / e-mail indique sur le profil.
2. Incluez : version Windows, build, etapes de reproduction, impact estime.

Delai de reponse vise : **7 jours** pour un premier retour.

## Recommandations utilisateur

- Clonez uniquement depuis ce depot officiel ou une release GitHub verifiee.
- Ne melangez pas des binaires tiers avec ce projet.
- Apres une MAJ Windows majeure, recompilez ou reverifiez les checksums.
