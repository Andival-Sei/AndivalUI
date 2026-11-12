# Andival UI

A small modular interface addon for **WoW Forever (Interface 16001)**.

## First module: Castbar

A restrained Blizzard-style **player** castbar: native gold/channel textures, thin bronze framing, spell icon, readable name and remaining time, latency zone, short success/interruption feedback, and reduced-motion option. Target/focus/pet bars are not replaced in this first release.

The Enhanced Soft Interact adapter checks the actual visibility of its live interaction bar. When ESI shows gathering or opening progress, Andival UI yields. If ESI is absent, disabled, hidden, or cannot associate the interaction, the regular castbar is the fallback. Preview HUDs do not suppress spells, and an old ESI completion animation does not hide a new spell.

## Install

Copy the `AndivalUI` addon folder into `World of Warcraft/_forever_/Interface/AddOns/`. The final path must be `AddOns/AndivalUI/AndivalUI.toc`. Restart the client if newly added while it was running.

1. Enable Andival UI in the addon list.
2. Disable **Quartz's Player module** (or Quartz entirely) and reload. Andival UI intentionally stays out of the way while that module is active. Other Quartz modules can remain.
3. Disable any other replacement for the **player** castbar (for example a separately enabled Enhance QoL castbar). This addon never changes another addon's settings.
4. `/aui` or `/acast` opens the settings and live preview. Drag the preview to position it. Escape/Done ends preview. `/aui status` reports ESI/Quartz detection.

The ESI integration is read-only and currently targets ESI 0.5.8. Leave ESI's own default-bar hiding enabled if you want it to hide Blizzard's bar during interaction. No ESI code, fonts, or artwork is distributed here.

## На русском

`/aui` открывает настройки и предпросмотр. Перетащите полосу, выберите ширину и масштаб, включите/выключите иконку, зону задержки и анимацию. Первый модуль заменяет только полосу **игрока**. Полосы цели и питомца пока не меняются.

Сначала отключите модуль Player в Quartz и выполните `/reload`. Другие аддоны и их настройки автоматически не меняются. Полоса Enhanced Soft Interact при сборе ресурсов и открытии предметов получает приоритет, только когда она реально видна.

## Architecture

- `Core.lua`: module registry and versioned root settings.
- `Modules/CastbarLogic.lua`: testable progress and visibility rules.
- `Modules/Castbar.lua`: player cast lifecycle and native-asset presentation; settings under `AndivalUIDB.castbar`.
- `Integrations/EnhancedSoftInteract.lua`: read-only ESI adapter.
- `Settings.lua`: localized module controls and preview.

Future modules register independently through `ns.RegisterModule` and use their own saved-settings namespaces. Do not edit other addons or bundle their assets.

## Validation and limits

- Runtime files load in a mocked Lua environment; tests cover casts, channels, stale end events, interruption, visible/hidden/transparent ESI, preview exclusion, fallback and restricted timing.
- Restricted cast data is not calculated or guessed: the addon yields to Blizzard's native bar.
- No live-client visual or combat testing has yet been completed. This is **0.1.0, an initial test build**, not a claim of raid-ready compatibility.
- Actual Blizzard atlas rendering, secure-value behavior, ESI fade timing, and coexistence with other castbar owners need in-game testing.
- The module does not implement Quartz's mirror timers, GCD, swing timer or target/focus/pet features.

### Tests

Requires Node.js. `npm ci --ignore-scripts`, then `npm test`. Dev dependencies are not needed by WoW and must not be copied into AddOns.

### In-game acceptance checklist

- Holy Light cast, movement interruption, channel start/update/stop and rapid repeated casts.
- Mining/herbs/chest with ESI: one progress presentation, including looking away, cancellation and success.
- ESI disabled or HUD hidden: fallback castbar visible.
- New spell during ESI success flash: spell immediately visible.
- Settings/preview close, combat interruption of preview, reload persistence, scale and placement at 4K.
- BugSack clean; native fallback visible for any unreadable/restricted cast.

## License

Original addon source: MIT. Blizzard assets are referenced from the installed client, not included. This project is not affiliated with Blizzard or Enhanced Soft Interact.
