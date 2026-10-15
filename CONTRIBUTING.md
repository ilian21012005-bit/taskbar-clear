# Contribuer

Merci de votre interet pour TaskbarClear.

## Avant de commencer

- Lisez [SECURITY.md](SECURITY.md) si votre changement touche l'injection, les taches planifiees ou Defender.
- Windows **11 build >= 22621** est la cible principale.
- Gardez la philosophie du projet : **pas de processus resident**, pas de hooks globaux jeux.

## Environnement de dev

1. Visual Studio 2022 Build Tools (C++ desktop + Windows SDK)
2. PowerShell 5.1+
3. Build :

```powershell
.\native\build.ps1
.\scripts\update-checksums.ps1
```

## Pull requests

1. Fork + branche descriptive (`fix/...`, `feat/...`)
2. Changes minimales, style existant (C++ / PowerShell)
3. Mettre a jour [CHANGELOG.md](CHANGELOG.md) (section Unreleased)
4. Tester manuellement :
   - `.\setup.ps1 -SkipVisualClean`
   - `.\scripts\verify-installation.ps1`
   - Redemarrage Explorer ou `apply.cmd`

## Issues

- **Compatibilite Windows** : modele *Compatibilite Windows* + build `winver` + logs
- **Bug** : modele bug standard
- **Idees** : modele *Idee* (zero process resident)

Joignez toujours :

- Build Windows (`winver`)
- Sortie de `.\scripts\verify-installation.ps1`
- Dernieres lignes de `%LOCALAPPDATA%\transparent-taskbar\inject-at-logon.log`

## Licence

En contribuant, vous acceptez que vos contributions soient sous [MIT](LICENSE), sauf code tiers deja sous sa licence d'origine (voir [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)).
