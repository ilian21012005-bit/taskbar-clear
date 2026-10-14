# Publier une release

1. Compiler et verifier :

```powershell
.\native\build.ps1
.\scripts\update-checksums.ps1
.\scripts\verify-checksums.ps1
.\scripts\verify-installation.ps1
```

2. Mettre a jour [CHANGELOG.md](CHANGELOG.md) (date + version).

3. Commit, tag, push :

```powershell
git add bin/CHECKSUMS.sha256 bin/*.exe bin/*.dll CHANGELOG.md
git commit -m "release: vX.Y.Z"
git tag vX.Y.Z
git push origin main --tags
```

4. Publier les assets (zip + checksums) :

```powershell
.\scripts\release-github.ps1 -Tag vX.Y.Z
```

Les utilisateurs doivent verifier `bin/CHECKSUMS.sha256` avant installation ([SECURITY.md](SECURITY.md)).
