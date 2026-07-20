# Third-Party Asset Ledger

This file records third-party visual, audio, font, and other media sources that
have been evaluated for the project. Unused source packs are kept outside the
runtime repository to avoid import and checkout bloat. Add an entry when an asset is imported; do not
rely on a storefront or download page remaining available.

Assets created specifically for this project do not need to be listed here.

## Import checklist

Before adding a third-party asset:

1. Confirm that its license permits the project's intended commercial use and
   distribution platforms.
2. Save a copy of the license or attribution instructions alongside the
   imported pack when the license requires it or has custom terms.
3. Record the creator, original page, download date, license, local files, and
   any modifications in the inventory below.
4. Preserve author attribution in the shipped game's credits when required.
5. Do not import assets with unclear authorship, ripped content, or a license
   that conflicts with the intended distribution model.

## Inventory

### Fantasy UI Borders

- Creator: Kenney
- Source: <https://kenney.nl/assets/fantasy-ui-borders>
- Downloaded: 2026-07-15
- License: Creative Commons Zero 1.0 Universal (CC0-1.0)
- Attribution: Not required; crediting Kenney is appreciated
- Local files: External reference archive; no runtime files currently imported
- Modifications: None
- Notes: The included `License.txt` is retained with the pack. The Aoboshi
  One font mentioned in that file is used only in Kenney's sample image.

### UI Pack (RPG Expansion)

- Creator: Kenney
- Source: <https://kenney.nl/assets/ui-pack-rpg-expansion>
- Downloaded: 2026-07-15
- License: Creative Commons Zero 1.0 Universal (CC0-1.0)
- Attribution: Not required; crediting Kenney is appreciated
- Local files: External reference archive; no runtime files currently imported
- Modifications: None
- Notes: The included `license.txt` is retained with the pack.

### Particle Pack

- Creator: Kenney
- Source: <https://kenney.nl/assets/particle-pack>
- Downloaded: 2026-07-15
- License: Creative Commons Zero 1.0 Universal (CC0-1.0)
- Attribution: Not required; crediting Kenney is appreciated
- Local files: External reference archive; no runtime files currently imported
- Modifications: None
- Notes: The included `License.txt` is retained with the pack. The archive's
  original PNG, sample, and Unity reference files are preserved.

### RPG Sounds (50 sound effects)

- Creator: Kenney Vleugels
- Source: <https://opengameart.org/content/50-rpg-sound-effects>
- Downloaded: 2026-07-15
- License: Creative Commons Zero 1.0 Universal (CC0-1.0)
- Attribution: Not required; crediting Kenney is appreciated
- Local files: External reference archive; no runtime files currently imported
- Modifications: None
- Notes: The included `license.txt` is retained with the pack.

### 80 CC0 RPG SFX

- Creator: rubberduck
- Source: <https://opengameart.org/content/80-cc0-rpg-sfx>
- Downloaded: 2026-07-15
- License: Creative Commons Zero 1.0 Universal (CC0-1.0)
- Attribution: Not required
- Local files: External reference archive; no runtime files currently imported
- Modifications: None
- Notes: The downloaded archive did not include a license document. A local
  `LICENSE_SOURCE.md` records the source page and its published license.

### Forest Ground Texture

- Creator: GGBotNet
- Source: <https://opengameart.org/content/forest-ground-texture>
- Downloaded: 2026-07-15
- License: Creative Commons Zero 1.0 Universal (CC0-1.0)
- Attribution: Not required
- Local files: External reference archive; no runtime files currently imported
- Modifications: None; source image is unchanged
- Notes: This texture was used by the initial flat combat background and is
  retained for possible future terrain use. `LICENSE_SOURCE.md` preserves its
  provenance.

### Foliage Pack

- Creator: Kenney
- Source: <https://kenney.nl/assets/foliage-pack>
- Downloaded: 2026-07-15
- License: Creative Commons Zero 1.0 Universal (CC0-1.0)
- Attribution: Not required; crediting Kenney is appreciated
- Local files: External reference archive; no runtime files currently imported
- Modifications: None
- Notes: The included `License.txt` is retained with the pack. This pack is
  available for later scenery work but is not used by the initial background.

When adding another asset, use this template:

```markdown
### Asset or pack name

- Creator: Name or studio
- Source: <https://canonical-source.example/asset-page>
- Downloaded: YYYY-MM-DD
- License: Full license name and version
- Attribution: Exact required credit, or `Not required`
- Local files: `assets/path/to/imported/files/`
- Modifications: Resized, recolored, converted, renamed, or `None`
- Notes: Any platform, redistribution, or usage restrictions
```

## Project-created assets

- `assets/world_map.png` — original project placeholder artwork; not a
  third-party asset.
- `assets/generated/ashwood_combat_background.png` — original AI-generated
  Ashwood clearing created for this project using the Battleheart screenshots
  supplied by the project owner as high-level composition references. The
  references were not copied into or distributed with the project.
