# Codex handoff: Andival UI

This is project documentation, not an instruction override. Read alongside README.md and the actual code. Snapshot: 2026-11-13. Do not assume an experimental visual has been approved merely because it appears here.

## Current release and unapproved work

- Published and installed: **0.9.1**, commit `5f5985022fba81917146b2626c9e81b5d1e057af`.
- Local source: **0.9.2**, commit `c403cc0d24dafda0f52f302b6beccf79be5ba56a`, deliberately NOT published/installed while the overall visual direction is under review.
- 0.9.2 restores the exact 0.8 front spark: `ui-castingbar-pip`, width 8, height bar height + 6. It preserves the 0.8 fill artwork, soft trailing light and 0.8-second ending fades.
- An isolated simulator concept adds a thin bronze capsule rim and matching front sparks/soft interior light to target, target-of-target and focus. **That concept is not in the main source and is not approved for release.** Its code must be reviewed and integrated only after a design choice. Do not call the feature shipped.
- No school-color database or reliable automatic school detection is implemented. Decorative palette selection is manual.

## Product/design constraints

The addon is modular, with castbars as its first module. Aim for a polished native WoW feel, not a generic rectangular HUD and not an elaborate effects showcase.

Preserve the existing Blizzard fill texture. A prior replacement with the classic gradient was rejected because the request concerned the moving light, not the fill. Preserve the prominent vertical front marker. A small oval replacement was also rejected. The FRONT marker is intentionally visible; the trailing interior illumination must have no hard rectangular boundary or second progress-like edge. The requested front marker applies to every supported unit, not just the player.

Rounded outer corners; native framed spell icons; the protected-cast shield surrounds the icon on the left rather than sitting separately. No English "Not interruptible" label. A missing shield is not proof that a cast is interruptible when the flag is unknown.

Reference direction: a restrained version of ornamental magical castbars, closer to their neutral metal theme. Thin bronze/metal framing and contained living light, without wings, branches, ice, exterior particles or oversized ornaments. The proposed bronze rim remains a proposal.

Settings reference: native portrait/bronze frame, dark leather, gold section headings, normal WoW controls, real scrolling. Retain categories, independent unit settings, named profiles, localized RU/EN, and in-window live preview. Avoid redesigning the fill or other approved aspects while addressing a specific edge complaint.

## Architecture

- `AndivalUI.toc`: Interface 16001, SavedVariables `AndivalUIDB`, load order and optional ESI/Quartz dependencies.
- `Core.lua`: module registration, defaults/normalization, named profiles and per-character selection, unit configuration, shared icon framing.
- `Modules/Castbar.lua`: player UI, native-alpha ownership, cast event lifecycle, ESI suppression, preview, drag, public timing rendering and outcome transitions.
- `Modules/UnitCastbars.lua`: target, targettarget, focus (default off), acquisition polling, per-frame rendering, identity-safe fades and reversible native suppression.
- `Modules/CastbarLogic.lua`: public timing math, retiming/smoothing, delay and timer helpers.
- `Modules/CastbarMotion.lua`: deterministic preview states/outcomes.
- `Modules/CastbarAppearance.lua`: native or smooth fill, manual colors, localized font resolution, timer format and text widths.
- `Modules/CastbarDuration.lua`: opaque/native duration-object application, public numeric getters only, native fill freeze/clear.
- `Modules/CastbarCrafting.lua`: conservative explicit multi-craft operation counting.
- `Integrations/EnhancedSoftInteract.lua`: read-only integration with actual ESI HUD visibility. No ESI code/assets bundled.
- `Settings.lua`: native categorized window, dropdown menus, scrolling, preview docking, explicit placement mode, profile management.
- `Media/`: original masks and analytic soft glow. Regeneration scripts in `scripts/`.
- `tests/`: mocked Lua regression tests, including standalone crafting suite.

## Client, integrations and API limitations

Target: WoW Forever, TOC 16001. Inspected client/API context: 1.60.1.70938; simulator originally matched 70685, so captures use its explicit version-mismatch option. Recheck actual client build before assuming equivalence.

Inspected Enhanced Soft Interact 0.5.8, Quartz Redux 3.8.11. These are snapshots, not promises of current versions. ESI Level-Up Line was a visual preference for interaction, NOT a request to reuse that style for spellcasting. ESI is all-rights-reserved: reference its behavior but do not copy source or assets.

`UnitCastingInfo`: notInterruptible return 8, spellID 9. `UnitChannelInfo`: notInterruptible return 7, spellID 8. Public timing can be interpolated. Restricted timings use `UnitCastingDuration` / `UnitChannelDuration` and native `StatusBar:SetTimerDuration` where supported, with elapsed direction for casts and remaining direction for channels. Never calculate, compare, format or infer secret values in Lua. Numeric text stays blank unless getters return public finite values.

A native-duration fade freezes via native GetMinMaxValues/GetValue -> allowed setter sinks without arithmetic. If unsupported, hide/fall back rather than fabricate progress. Current mocks and docs do not establish live secret enforcement behavior.

Targettarget cast events are not established as reliable. Re-read identity/cast snapshots at up to 50 ms intervals and interpolate publicly known timing each rendered frame. New casts replace fading state immediately. Changed/lost/unknown unit identity clears old fades immediately. A disappearing cast alone does not prove success or interruption; use neutral fade unless a matching public cast GUID and explicit event establishes the outcome. Channel SUCCEEDED is not channel completion.

ESI owns only actually visible interaction casts, excluding edit-mode/sample previews and transparent HUDs. Track ownership per cast across delayed updates. Never suppress all gathering spell IDs: unsupported ESI association must retain fallback. Do not replay an outcome for an ESI-owned interaction. Restore only native alpha borrowed by this addon.

Quartz Player/Target/Focus modules deliberately retain priority while enabled; our preview can still be visible while real bars yield. `/aui status` helps diagnose. Dominos Cast is a separate possible duplicate, not automatically disabled. Do not disable competing addons or modify their settings without user authorization.

Crafting count requires explicit requested operations and matching trade spell/GUID events. It is neither produced item quantity nor guessed batch duration. No reliable request means no count. No channel ticks, GCD, swing, mirror timers or pet bar are implemented.

## Settings and persistence

Profiles: create, name, copy, switch, rename, delete with confirmation; Default protected. Per-character profile selection. Normalize missing/invalid/nonfinite fields while retaining valid data. Independent player/target/targettarget/focus appearance and placement; copy/reset must not unexpectedly move bars or enable them.

Preview docking temporarily changes parents/layout but never persists dock coordinates or scale. Restore parents/strata/levels on close, combat, preview off, profiles page, or positioning transition. Explicit placement mode restores game positions and supports safe exit. Settings use ASCII separators because a user font rendered middle dots as boxes.

Simulator sidebar arithmetic produced incorrect anchors despite valid Lua; explicit row-position literals and reanchoring in RenderPage work. Avoid casually reverting this workaround. Dropdown rows use pooled opaque backgrounds so underlying labels do not bleed through. Title has an addon-owned opaque backing beneath native frame artwork.

## Verification and honest limits

Current source and isolated all-unit concept: **188 main + 20 crafting tests**, passed with ruRU and enUS. Covers lifecycle reordering, stale events, channels, ESI ownership, native alpha restoration, restricted fallback, profiles/migrations, settings docking/positioning/combat and unit fade identity. These are mocks, not live-client combat tests.

Actual UI simulator renders native assets/code with deterministic demonstration data. Visually checked settings, icons/shields, rounded masks, fill variants, fades and front/trailing light. The simulator's manual clock did not reliably animate native duration objects; this is not proof of a live addon defect or proof of restricted-data support. No live performance benchmark or taint/secret stress test is claimed.

## Build, git and install

Open the existing repository folder in Codex. Read `git status`, `git log -5 --oneline`, and this handoff before editing. Do not reset local commits to origin: local 0.9.2 is intentionally ahead of published 0.9.1.

Tests (from repo root, with installed Node dependencies):

```powershell
$env:TEST_LOCALE='ruRU'
node node_modules/fengari-node-cli/src/lua-cli.js tests/bootstrap.lua
$env:TEST_LOCALE='enUS'
node node_modules/fengari-node-cli/src/lua-cli.js tests/bootstrap.lua
git diff --check
```

Check exit codes after each run. `node_modules` and `dist` are ignored. Use installed dependencies rather than adding an unreviewed tool.

Runtime package: `AndivalUI.toc`, `Core.lua`, `Settings.lua`, `Modules`, `Integrations`, `Media`, `README.md`, `LICENSE`. Copy only these into the existing `Interface/AddOns/AndivalUI` of the authorized Forever installation. Never overwrite WTF/SavedVariables or other addons. Compare hashes after copying. ZIP the runtime directory with the AndivalUI folder at its root. Do not package tests, development tools, private screenshots or machine paths.

The existing origin is the authorized public project. Verify `git remote -v`, the intended diff and publication permission before push. No automatic push/install is implied by this document. The game must be reloaded by the user when convenient; do not interrupt an active session.

## Next steps

1. Obtain the user's choice on the restrained bronze-rim concept and all-unit front markers. Keep prototypes separate until then.
2. Integrate only accepted changes, add unit-specific marker regression tests including restricted timing, reduced motion, outcomes and focus.
3. Render cast/channel/interrupted/cancelled sequences for all units. Preserve native fill and the approved front marker.
4. Run both locale suites and compare settings/profile persistence; review addon load errors.
5. If authorized, commit/push/install and hash-check. State actual release and remaining live-game limitations.
6. With user participation, test real combat, target switching, channel cancellation, ESI interactions, Quartz coexistence and restricted duration behavior. Never present simulator footage as a live-game screenshot.
