# WordNext Films (fork of FilmCraft)

WordNext Films is WordNext's build of [FilmCraft](https://github.com/storytold/filmcraft), an
open-source video editor written in Rust (MIT OR Apache-2.0). This fork exists to ship installers
and a browser build (WebAssembly) under the WordNext name, served from `films.wordnext.tech`.

## Rules for this fork

- **Upstream copyright and licence stay.** `LICENSE-MIT`, `LICENSE-APACHE`, `NOTICE` and
  `ATTRIBUTION.md` are not edited, except to add WordNext lines below the upstream ones.
- **ArtCraft marks never ship in our product.** `docs/brand/` is kept only because it is part of
  the upstream repository copy; the name, wordmark and "A" mark must not appear in the app, the web
  build, our pages, installers or marketing. The upstream Discord and the ArtCraft website are not
  linked from the app (`crates/ui-egui/src/links.rs`). Product name: **WordNext Films**
  (`filmcraft_ui_egui::links::PRODUCT_NAME`).
- **Keep the diff small.** Branding changes go in `links.rs`, the About dialog, the Home screen,
  the menus, the packaging and the catalogues, so `git merge upstream/main` stays cheap. Crate and
  binary names stay `filmcraft-*`. File formats and interchange identifiers (`.fcproj`, AAF/MXF
  writer names, the autosave folder, "not a FilmCraft project" errors) keep the upstream name on
  purpose: changing them would break compatibility with existing projects and with upstream.
- **Upstream remote:** `git remote add upstream https://github.com/storytold/filmcraft.git`.

## Names

| What | Value |
|---|---|
| Product | WordNext Films |
| Domain | `https://films.wordnext.tech` |
| App identifier (macOS bundle id, Linux / Flatpak app id, Wayland app id) | `tech.wordnext.films` |
| Installer files | `wordnext-films-<version>-<platform>-<arch>.*` (the CLI archives stay `filmcraft-cli-…`, the web zip `filmcraft-web-…`) |
| macOS app and DMG volume | `WordNext Films.app`, `WordNext Films` |
| Publisher | WordNext (MSI manufacturer, AppStream developer, package vendor), contact `info@wordnext.tech` |

The identifier replaces the upstream `ai.storyteller.filmcraft`, so the operating system treats this
as a different app from the original: settings and file associations are not shared with it.

Kept as they were (internal names, changing them is a separate step):

- Executables and crates: `filmcraft`, `filmcraft-cli`, `filmcraft-*`; the executable and icon file
  names inside the macOS bundle.
- The Windows install folder (`Program Files\FilmCraft`, which the shared CI install test expects),
  the settings folders and the Windows registry key names.

## Status of the rebrand

- [x] Identifier, visible names, publisher, installer file names
- [x] Links: no Discord button, no ArtCraft site link; Help menu points at WordNext and this fork
- [x] About dialog, Home screen, header: no ArtCraft marks (the wordmark is no longer embedded)
- [x] README and WORDNEXT.md
- [x] Own app icon: the WordNext monogram on a film frame (`assets/app-icon/`), replacing the upstream owl
- [x] Spanish (Spain, tuteo) catalogue complete; the app follows the system language
- [x] Web page (es/en) and browser build: `vercel.json`, `packaging/vercel/`; Vercel project `wordnext-films` (production branch `main`) with the domain `films.wordnext.tech`
- [x] Desktop installers workflow `.github/workflows/instaladores.yml` (signs when the secrets exist, unsigned otherwise; publishes on a `v*` tag)
- [ ] First release
