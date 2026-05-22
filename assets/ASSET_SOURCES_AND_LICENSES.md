# Asset Sources And Licenses / 素材来源与授权

This folder is a curated, import-ready asset tree.  
这个目录只保留整理后的可导入素材，不是原始下载包堆放区。

## 1. Rules / 规则

- raw marketplace and download artifacts stay in `美术参考_art_reference/free_ui_assets/`
- only curated, usage-oriented files belong under `assets/`
- every imported pack must have a source note and a license note

## 2. Folder Layout / 目录结构

- `assets/ui/`
  - curated UI frames, overlays, fonts, and icon sets
- `assets/音效_sfx/`
  - reserved for explicitly licensed audio only
- `assets/背景_background/`
  - redistribution-safe background candidates

## 3. Imported Packs / 当前已导入

### `assets/ui/Kenney科幻UI_kenney_scifi`

- source pack: `kenney_ui-pack-sci-fi.zip`
- source reference: `美术参考_art_reference/free_ui_assets/kenney_page.html`
- original pack name: `Kenney UI Pack - Sci-Fi`
- license: `CC0`
- imported content:
  - UI bars
  - header and button shells
  - crosshair accents
  - shadow slices
  - `Kenney Future` fonts

### `assets/ui/Wenrexa极简科幻_wenrexa_scifi_minimalism_01`

- source pack: `wenrexa_ui-scifi-minimalism-01_real.zip`
- source reference: `美术参考_art_reference/free_ui_assets/wenrexa_purchase.html`
- likely source page: `https://wenrexa.itch.io/ui-scifi-minimalism-01`
- license: `CC0`
- imported content:
  - panel and top-menu overlays
  - button shells
  - arrows
  - scroll and slider parts
  - decorative info blocks
  - compact icon blocks

### `assets/ui/游戏图标_科幻_game_icons_scifi`

- source pack: `game-icons_science-fiction_svg_white-transparent.zip`
- source reference: `美术参考_art_reference/free_ui_assets/gameicons_scifi.html`
- source page: `https://game-icons.net/tags/science-fiction.html`
- license: `CC BY 3.0`
- local license copy: `assets/ui/游戏图标_科幻_game_icons_scifi/license.txt`

Imported icons and authors:

- `event_icons/energise.svg` - Lorc
- `event_icons/targeting.svg` - Lorc
- `event_icons/forward-field.svg` - Lorc
- `event_icons/bubble-field.svg` - Lorc
- `event_icons/radar-dish.svg` - Lorc
- `event_icons/rocket-thruster.svg` - Delapouite
- `totem_candidates/tesla-turret.svg` - Lorc
- `totem_candidates/power-generator.svg` - Delapouite
- `totem_candidates/star-gate.svg` - Delapouite
- `totem_candidates/double-ringed-orb.svg` - Lorc

Credits rule:

- keep a credits line in the shipped project if any of these icons are used
- recommended wording:
  - `Icons made by Lorc and Delapouite via Game-icons.net (CC BY 3.0)`

### `assets/背景_background/wenrexa_scifi`

- source pack: `wenrexa_ui-scifi-minimalism-01_real.zip`
- source reference: `美术参考_art_reference/free_ui_assets/wenrexa_purchase.html`
- license: `CC0`
- imported content:
  - `Background.jpg`

### `assets/cardfront/`

- source: AI-generated project-specific Cardfront assets (original staging/source)
- generated for: Marble Dominion: Cardfront
- usage: card illustrations, device sprites, VFX textures
- restriction: do not use as third-party source pack; project-specific generated assets
- manifest: `assets/cardfront/提示词_prompts/generated_asset_manifest_v01.md`
- current status: source/staged AI-generated originals plus processed runtime derivatives; runtime use is tracked in section 8
- imported content (11 files):
  - 卡牌插图_cards_illustrations/ (3 source card illustrations) — processed 512 runtime versions are wired by `CardVisualRegistry.gd`
  - 装置地图精灵_devices_map_sprites/ (4 device sprites) — processed 96 runtime versions are wired by `DeviceVisualRegistry.gd`
  - 装置图标_devices_icons/ (1 status icon)
  - 特效纹理_vfx_textures/ (3 VFX textures) — processed 128 runtime versions are wired by `CardfrontVfxLayer.gd`

### `assets/cardfront_runtime/`

- processed runtime assets derived from `assets/cardfront/` source
- device sprites under `装置精灵_devices/96/` are already wired by `DeviceVisualRegistry.gd`
  - registered sprites: absorber core, engineer bot, pioneer beacon, temporary reflector
- VFX textures under `视觉特效_vfx/128/` are wired by `CardfrontVfxLayer.gd`
- device icons under `装置图标_icons/48/` are staged runtime icons for later HUD polish
- card illustrations under `卡牌插图_cards/512/` are wired by `CardVisualRegistry.gd`

## 4. Not Mirrored Into `assets/` / 未直接镜像进 `assets/` 的素材

### Cat's Tooth free sci-fi backgrounds

- source pack: `cats_tooth_free-scifi-backgrounds_real.zip`
- source reference:
  - `美术参考_art_reference/free_ui_assets/cats_page.html`
  - `美术参考_art_reference/free_ui_assets/cats_file_api_pretty.json`
- source page: `https://cats-tooth-studio.itch.io/free-sci-fi-backgrounds`
- license note from prior audit:
  - custom free-use terms
  - no raw redistribution as-is
  - no AI training or AI-use permission

Decision:

- keep this pack in `美术参考_art_reference/free_ui_assets/`
- do not mirror the raw background files into `assets/背景_background/`
- if the project wants to ship a derived background later, re-check the specific terms first

## 5. SFX Status / 音效状态

### Current imported audio subset / 当前已导入音频子集

The project now includes a first-pass curated audio subset under `assets/音效_sfx/`.
当前项目已经导入第一轮筛选后的音频子集，位于 `assets/音效_sfx/`。

Imported categories:

- `bullets/`
- `capture/`
- `ui_click/`
- `ui_hover/`
- `event_roulette/`
- `event_result/`
- `chamber/`
- `turret_destroy/`
- `timer_warning/`
- `results/`
- `music/`
- `ambient/`

Selection note:

- `assets/音效_sfx/SFX_SELECTION_NOTES.md`

Primary source packs and licenses:

- `50 CC0 Sci-Fi SFX` - author `rubberduck` - `CC0`
- `Interface Sounds` - author `Kenney` - `CC0`
- `UI sounds` - author `HaelDB` - `CC0`
- `Interface Beeps` - `CC0`
- `10 Clicks and Switches` - author `StarNinjas` - `CC0`
- `GUI Sound Effects` - author `Lokif` - `CC0`
- `Win Jingle` - author `Fupi` - `CC0`
- `Victory Sting` - author `congusbongus` - `CC0`
- `Space Echo` - author `Centurion_of_war` - `CC0`
- `Sci-Fi Background noise` - author `Spring Spring` - `CC0`
- `Space Dungeon` - author `MintoDog` - `CC0`

Local source and license evidence:

- raw downloads and extracted packs:
  - `美术参考_art_reference/asset_gap_downloads/`
- saved source pages and license snapshots:
  - `美术参考_art_reference/asset_gap_downloads/licenses/`

## 6. Feature Mapping / 功能映射建议

- menu background
  - safe current candidate: `assets/背景_background/wenrexa_scifi/Background.jpg`
  - restricted external candidate: Cat's Tooth pack in `美术参考_art_reference/free_ui_assets/`
- button SFX
  - no approved asset imported yet
- turret animation dressing
  - no direct animation sheet imported yet
  - Kenney crosshair accents and Wenrexa overlays can serve as style references
- chamber glow framing
  - use Kenney bars/gloss slices and Wenrexa panel overlays
- faction totems
  - start from `assets/ui/游戏图标_科幻_game_icons_scifi/totem_candidates/`
- victory and event presentation
  - combine Wenrexa panel layers, Game-Icons, and custom tween/VFX work

## 7. Related Docs / 相关文档

- `美术参考_art_reference/free_ui_assets/FREE_UI_INTEGRATION_PLAN.md`
- `docs/技术_technical/TECHNICAL_GUIDE.md`
- `docs/设计_design/ASSET_GAP_PLAN.md`
- `assets/音效_sfx/SFX_SELECTION_NOTES.md`

## 8. Asset Integration Status / 素材集成状态 (v0.2.3)

The old `assets zero references` audit is no longer current. Cardfront now uses
several curated runtime assets through registries and lightweight feedback
systems. Some UI surfaces still use procedural `ColorRect` / `StyleBoxFlat`
fallbacks, but assets are no longer disconnected from code.

旧的“assets 零引用”结论已经过时。Cardfront 当前已经通过注册表和轻量反馈系统接入了多类运行时素材；部分 UI 仍保留程序样式 fallback，但代码和素材已经不再完全断开。

### Current wired paths / 当前已接入路径

| Area | Runtime entry | Asset status |
|---|---|---|
| Card illustrations | `scripts/cardfront/ui/CardVisualRegistry.gd` and `CardfrontCardView.gd` | 1001-1004 load from `assets/cardfront_runtime/卡牌插图_cards/512/`; placeholder fallback remains. |
| Device sprites | `scripts/cardfront/devices/DeviceVisualRegistry.gd` and `CardfrontDeviceOverlayLayer.gd` | Absorber, Engineer, Pioneer Beacon, and Temporary Reflector sprites load from `assets/cardfront_runtime/装置精灵_devices/96/`. |
| VFX textures | `scripts/cardfront/vfx/CardfrontVfxLayer.gd` | Energy ripple, shield crack/pulse, and region pulse load from `assets/cardfront_runtime/视觉特效_vfx/128/`, with draw-circle fallback. |
| Card audio feedback | `scripts/cardfront/ui/CardfrontCardAudioFeedback.gd` | Hover, click, success, and fail feedback use curated `assets/音效_sfx/` files when present; missing assets fail silently. |
| UI art registry prep | `scripts/cardfront/ui/CardfrontUiAssetRegistry.gd` | Kenney font, Kenney/Wenrexa panels, and Game-Icons paths are centralized with `ResourceLoader.exists` fallback. |

### Current UI art state / 当前 UI 美术状态

The UI is in a **resource-prep / partial skin** state, not final art completion.

- `CardfrontHandPanel`, `CardfrontCardView`, `CardfrontTopResourceBar`, `CardfrontCardDetailPopup`, `CardfrontToastLayer`, and `CardfrontRegionInfoPanel` now query `CardfrontUiAssetRegistry`.
- Missing textures or fonts keep the current deep-blue `ColorRect` / `StyleBoxFlat` fallback.
- Do not scatter Kenney/Wenrexa/Game-Icons paths into gameplay scripts or `Main.gd`.
- Game-Icons entries are `CC BY 3.0`; keep credits when these icons are used in shipped UI:
  - `Icons made by Lorc and Delapouite via Game-icons.net (CC BY 3.0)`

### Still planned / 仍待处理

| Category | Status |
|---|---|
| Card thumbnails | Planned for `v0.2.4b-card-thumbnail-pass`; use `CardVisualRegistry.thumbnail` for hand cards and reserve 512 art for detail/full-card views. |
| Final UI art pass | Planned for `v0.2.4-ui-art-resource-pass`; replace remaining procedural panels with registry-backed assets. |
| Full theme resource | Not yet created; no global `.tres` theme is canonical. |
| Wider audio system | Card hover/click/success/fail exists; global music, menu SFX, and battle-state audio remain separate future work. |
| Asset credits polish | Keep this document and `generated_asset_manifest_v01.md` aligned whenever a new asset category becomes shipped UI. |
