# Andival UI

A small modular interface addon for **WoW Forever (Interface 16001)**.

## First module: Castbar

A restrained Blizzard-style **player** castbar: native Blizzard backdrop and gold/channel textures, compact text, optional small spell icon, readable name and elapsed / total time, latency zone, short success/interruption feedback, and reduced-motion option. Optional target and target-of-target bars share the rounded native styling. Focus/pet bars are not replaced.

The Enhanced Soft Interact adapter checks the actual visibility of its live interaction bar. When ESI shows gathering or opening progress, Andival UI yields. If ESI is absent, disabled, hidden, or cannot associate the interaction, the regular castbar is the fallback. Preview HUDs do not suppress spells, and an old ESI completion animation does not hide a new spell.

## Install

Copy the `AndivalUI` addon folder into `World of Warcraft/_forever_/Interface/AddOns/`. The final path must be `AddOns/AndivalUI/AndivalUI.toc`. Restart the client if newly added while it was running.

1. Enable Andival UI in the addon list.
2. Disable **Quartz's Player module** (or Quartz entirely) and reload. Andival UI intentionally stays out of the way while that module is active. Other Quartz modules can remain.
3. Disable any other replacement for the **player** castbar (for example a separately enabled Enhance QoL castbar). This addon never changes another addon's settings.
4. `/aui` or `/acast` opens the settings and live preview. Drag the preview to position it. Escape/Done ends preview. `/aui status` reports ESI/Quartz detection.

The ESI integration is read-only and currently targets ESI 0.5.8. Leave ESI's own default-bar hiding enabled if you want it to hide Blizzard's bar during interaction. No ESI code, fonts, or artwork is distributed here.

## На русском

`/aui` открывает настройки и предпросмотр. Перетащите полосу, выберите ширину и масштаб, включите/выключите иконку, зону задержки и анимацию. Есть полосы игрока, цели и цели цели. Полосы цели включаются отдельно; в предпросмотре их можно перетаскивать. Полоса питомца не меняется.

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
- No live-client visual or combat testing has yet been completed. This is **0.7.1, a revised test build**, not a claim of raid-ready compatibility.
- Actual Blizzard atlas rendering, secure-value behavior, ESI fade timing, and coexistence with other castbar owners need in-game testing.
- The module does not implement Quartz's mirror timers, GCD, swing timer or focus/pet features.

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

## 0.2.0 revision

Replaces the plain bronze rectangle with native Blizzard castbar backdrop artwork, tighter typography, a smaller optional icon (off by default), and a restrained native completion glow. Explicit atlas assignment and additional event-order/ESI-ownership tests. Existing saved positioning and preferences are preserved; Reset module applies the new dimensions and icon default. No in-game screenshot or visual validation is claimed.

## 0.3.0 polish

Rounded antialiased outer silhouette, shared clipping for native fill and the latency zone, compact shadowed native text, and a restrained cast-specific completion glow. The castbar remains visually distinct from Enhanced Soft Interact. `Media/RoundedMask.tga` is original geometric artwork included under MIT. Defaults are 280 by 16; existing settings remain unchanged until Reset module.

Mock tests validate mask attachment and cast lifecycle, not pixel output. A simulator preview uses actual addon code and client assets; it is not live-client combat validation.

## 0.4.0 motion

A low-opacity light moves within the existing fill, clipped to both its progress and rounded silhouette. Success gets a brief warm bloom and gentle fade; interruption darkens the partial bar and extinguishes its light. Reduced motion disables travelling light, glow and animated fading. Preview now demonstrates success and interruption in a seven-second cycle using the same rendering functions as real casts. ESI-owned interactions never receive these effects.

## 0.5.0 unit bars and audit

Icon toggle, optional player latency zone, gold casts and native channel texture with reverse progress already existed. This release adds independent target/target-of-target toggles, draggable preview positions, and explicit interruptibility labels: interruptible, not interruptible, or unknown. Unknown/secret state is never inferred. These labels describe the spell, not whether your interrupt ability is ready or in range.

`Modules/UnitCastbars.lua` is separately registered and polls the actual target unit APIs every 50 ms (plus immediate target-change refresh), because target-of-target spellcast events are not reliably established. If the client provides no readable cast/timing, that custom bar stays hidden. The normal target castbar is restored; there is no guaranteed native target-of-target fallback. No countdown is invented for secret timings. The first implementation does not use secret duration objects.

While Quartz's Target module is enabled, our target bar waits, just as the player bar waits for Quartz Player. Disable those modules manually to use the replacements. Other addon's settings/events are never changed. If Enhance QoL's target castbar is enabled, disable one owner manually to avoid duplicates. No native target-of-target unit frame is hidden.

Target and target-of-target rendering can be previewed with deterministic sample data in the simulator. This verifies rendering and Lua compatibility, not real combat data availability or private-server event behavior. Live-client testing remains necessary.

## 0.5.2 icon frames

Optional spell icons now use a consistent native Blizzard quick-slot rim on player, target and target-of-target bars. The rim tracks the icon toggle and frame fades. No other addon settings are changed.

0.5.2 also replaces the interim text status labels with Blizzard's native castbar shield, shown **only** for a confirmed non-interruptible spell. Unknown and explicitly interruptible spells show no shield; absence of the shield does not assert interruptibility when the API state is unavailable.

The protection shield is anchored on the left: before the framed spell icon when icons are enabled, otherwise before the bar. Its spacing avoids covering the spell artwork or progress.

## 0.5.3 shield composition

The native shield now surrounds the spell icon on the left of the bar, as one composition, rather than appearing as a separate badge. The icon is drawn above the shield; its normal square rim is suppressed for protected casts. Confirmed non-interruptible casts retain this icon-and-shield indicator even when optional ordinary spell icons are hidden. Unknown state never shows a shield.

## 0.5.4 shield proportions

Protected spells use a 16 px icon inset into the native 29 by 33 px shield. The smaller artwork leaves the metal rim visible rather than covering it; ordinary icons remain 20 px. Native art and existing icon crop are retained, with no custom imitation or extra badge.

## 0.5.5 integrated shield and elapsed timers

Protected spells inset their artwork into the inner shield silhouette using an original antialiased mask, leaving the native Blizzard metal rim visible. This is a deliberate refinement of Blizzard's square-icon-on-shield composition, not an exact copy of its template. The ordinary square icon is hidden for protected casts; the shield is still shown only for confirmed non-interruptible casts.

All active player, target and target-of-target timers now show elapsed / total duration, including channels. Russian clients use decimal commas. Channel fill still drains while elapsed time increases. Restricted timing still falls back safely; no numbers are fabricated. Simulator previews use deterministic sample data, not live combat.

## 0.6.0 independent profiles and state testing

Player, target and target-of-target have independent width, height, scale, icon, reduced-motion and enabled settings. Existing target positions and inherited appearances migrate once. Copy appearance explicitly between profiles without moving or enabling the destination. Reset appearance also preserves position and enabled state. Network latency remains a player-only setting, not a claimed target ping measurement.

An authoritative cast timing change now produces a transient signed correction (for example +0.3 seconds); the fill eases to its corrected position over 0.18 seconds without altering the actual elapsed/total timer. Channel shortening displays a negative correction. This is spell pushback/timing correction, not an invented network latency number. Reduced motion applies the correction immediately. Unit changes do not inherit another target's correction; unknown identity is not guessed.

Settings offer looping preview and individual cast, channel, delay, success, interruption, protected-spell and ESI-suppression demonstrations. ESI simulation hides only our sample bars and never changes ESI settings or globals. The shield preview applies to target/target-of-target. Preview is disabled in combat. Existing real player success/interruption effects are retained; target outcome animations here are preview-only, not inferred from disappearance of an enemy cast.

Channels retain reverse fill and elapsed / total timing. Tick marks are deliberately absent: no reliable per-spell tick schedule has been verified for this client. School colors remain deferred because a build-matched data extraction is not yet available. No live-game combat validation is claimed.

## 0.7.0 named profiles and language audit

Open `/aui` → **Profiles**. Create a named profile from Default, duplicate a selected profile, switch, rename, or delete with explicit confirmation. Creation/duplication immediately selects the new profile for this character. Profile data is account-wide; each character's selection is stored separately. Characters intentionally selecting the same profile share its live settings.

Existing settings migrate into **Default** once, including positions. Default remains editable but cannot be deleted or renamed. Copies are independent deep copies; existing names cannot be overwritten. Deleting a profile returns every character using it to Default. No changes are allowed in combat; switching waits until character identity is available. No import/export or automatic specialization switching is included.

The interface automatically follows the WoW client: ruRU uses Russian; enUS/enGB and other locales use English fallback. There is no manual language selector. Settings, all test modes, profile operations/errors, status diagnostics and decimal formatting have been audited. Actual spell names still come from the client. The preview's Cycle all now includes all seven explicit states, including simulated ESI suppression; this is sample data only.

## 0.7.1 runtime and saved-data audit

- Explicit channel failure wins over near-end natural completion. Channel STOP briefly reconciles subsequent result events before selecting an outcome; early channel stop fades as interrupted. Quiet failures are handled. An unidentified terminal event first checks whether a spell remains live.
- Player and gamepad native castbars preserve their prior alpha, including fractional/zero alpha. Restoration waits rather than resurrecting a finished native bar. ESI remains read-only and retains control while its interaction bar is visible.
- Closing preview or entering combat stops an in-progress drag. Unrelated party/raid UNIT_TARGET events no longer reset selected-target smoothing.
- Presentation updates every rendered frame; target acquisition remains bounded to 50 ms. Idle player work is skipped unless native restoration is pending. Unchanged text/icons/atlases are not repeatedly reassigned. Internal light fades at loop boundaries; spark height and timer space follow bar dimensions.
- Every profile activation normalizes complete defaults, strict booleans and finite coordinates. Incomplete/invalid saved fields cannot pass nil/NaN/infinity to frame positioning; valid positions and settings remain unchanged.

Tests include reordered events, near-end channel failure, original alpha ownership, missing identities, 240 Hz presentation steps, drag cancellation and incomplete saved profiles in both languages. These are mocked regression tests and actual UI-simulator checks, not live-client combat/performance measurements. Restricted cast data still falls back safely; tick schedules and spell-school colors remain intentionally unimplemented. Target completion effects are still preview-only, not guessed from disappearing casts. The brief result reconciliation cannot guarantee recovery of arbitrarily delayed or absent game events.
