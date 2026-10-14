# Projets proches (carte de l'ecosysteme)

Comparatif oriente **perf / processus resident** — ce que TaskbarClear vise a eviter.

| Projet | Lien | Rapport avec TaskbarClear | Perf / resident |
|--------|------|---------------------------|-----------------|
| **TaskbarClear** (ce repo) | [taskbar-clear](https://github.com/ilian21012005-bit/taskbar-clear) | Clear only, inject once | **Minimal** — pas d'exe resident |
| **TranslucentTB** | [TranslucentTB/TranslucentTB](https://github.com/TranslucentTB/TranslucentTB) | Reference TAP XAML, blur/acrylic, IPC | **Moyen** — worker WinEvent + tray |
| **w11-theming-suite** | [decarvalhoe/w11-theming-suite](https://github.com/decarvalhoe/w11-theming-suite) | Upstream MIT TaskbarTAP + SWCA | **Variable** — GUI Electron + persistence WMI |
| **Lively (TaskbarBridge)** | [rocksdanister/lively](https://github.com/rocksdanister/lively) | TAP derive, refresh **event-driven** | **Eleve** — app wallpaper + bridge |
| **ExplorerPatcher** | [valinet/ExplorerPatcher](https://github.com/valinet/ExplorerPatcher) | Barre classique / shell | **Moyen** — DLL Explorer permanente |
| **Windhawk** | [ramensoftware/windhawk](https://github.com/ramensoftware/windhawk) | Mods generiques (hooks) | **Eleve** — service + hooks globaux |
| **TaskbarX** | [ChrisAnd1998/TaskbarX](https://github.com/ChrisAnd1998/TaskbarX) | Centrage icones | **Moyen** — processus resident |
| **Open-Shell** | [Open-Shell/Open-Shell-Menu](https://github.com/Open-Shell/Open-Shell-Menu) | Menu Demarrer | Hors scope barre Clear |

## Ce qu'on peut emprunter (sans copier tout le projet)

### TranslucentTB (priorite haute, fiabilite)

- Retry `InitializeXamlDiagnosticsEx` avec `VisualDiagConnection{N}` incremente (**deja dans TaskbarClear**).
- Timeout / attente TAP ready (hook `WH_CALLWNDPROC`) — plus fiable au boot, **cout : 0 en idle** une fois charge.
- Release **2025.1** : blur XAML, fixes builds 25H2 — lire les commits `ExplorerTAP/` pour regressions Windows.

### w11-theming-suite (priorite moyenne, structure)

- Separation claire TAP vs SWCA (SWCA seul **insuffisant** sur 25H2 — documente dans notre README).
- Scripts PowerShell modulaires — inspire `visual-clean/` et `setup.ps1`.
- **A eviter** pour notre objectif perf : persistence WMI continue, GUI Electron.

### Lively TaskbarBridge (priorite basse, architecture)

- Reapply **sur evenement** (Explorer redemarre) plutot que poll 500 ms.
- Equivalent leger chez nous : taches planifiees **logon + deverrouillage** + `AlreadyLoaded()` dans `inject-once`.

### Windhawk / TaskbarX / ExplorerPatcher

- Utiles comme **reference UX**, pas comme base code : trop lourd ou hors scope Clear-only esport.

## Positionnement TaskbarClear

```text
         perf esport / zero resident
                    ^
                    |
    TaskbarClear ---+--- (sweet spot actuel)
                    |
    TranslucentTB --+--- plus de features, plus de code actif
                    |
    Windhawk --------+--- hooks generiques
```

## Liens utiles (releases / docs)

- [TranslucentTB releases](https://github.com/TranslucentTB/TranslucentTB/releases) — verifier compatibilite build Windows.
- [SECURITY.md](../SECURITY.md) — injection, Defender, checksums.
- [ROADMAP.md](../ROADMAP.md) — evolutions prevues sans regression perf.
