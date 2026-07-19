# Cinematic Check-In Transition Plan

## 1. Goal
Make tapping the **check-in lens** on Home feel like the user is *stepping
into the sea to stir it*, not pulling up a new page. Home's chrome dissolves
out of the way, the check-in field slides/fades into view, and — critically —
the dot is steering the **same** water the user was just looking at on Home,
so the mirror responds to the user's hand in real time.

---

## 2. Root Cause (verified against the code)

There are today **two independent painters of the water**:

- `lib/app_shell.dart:556-564` — the shell paints a `SeaPainter` driven by
  `_seaManager.model`, on every screen, via `moodSource = () => _atmo`
  (where `_atmo` is the latest kept mood, recomputed in
  `_refreshAtmosphere`).
- `lib/mood_selector_screen.dart:566-574` — the selector paints a *second*
  `SeaPainter` driven by its *private* `SeaFieldModel _model` (line 127),
  which the dot steers via `_onTick` (line 190).

Screen changes go through `AnimatedSwitcher` (app_shell.dart:579), which
swaps keyframes by screen-key. The transition has zero awareness of the dot
or the lens — it just crossfades two opaque widgets.

Even if we left two painters, the dot's `v/a` never reach `_seaManager.model`,
so the **water visible on Home** does not react until the next kept mood.
That's why the sea "still goes wild in the home": it's being driven by stale
atmosphere while the user stirs a private pool behind the curtain.

---

## 3. Target Behaviour

1. **One painter, one truth.** The shell's `SeaPainter` is the only water.
   Remove the selector's local `SeaPainter` and local `SeaFieldModel`.
2. **Live steering.** While the check-in is open, the dot's current
   `(v, a)` is fed into `_seaManager.model.visualV/A` every tick, with a
   small follow-factor (the existing 0.085) so the water inherits the dot
   smoothly while you drag.
3. **In-place transition, not a swap.** Replacing `AnimatedSwitcher` for the
   `home ↔ checkin` edge with a single screen that *transforms*:
   - The lens (home) grows and dissolves (`scale 1 → ~1.6`,
     `opacity 1 → 0`, `kExhale`, ~420 ms) — this already exists in
     `home_screen.dart:151-163` (`_tapLens` → `_dissolving`). Keep, but
     extend the choreography.
   - Concurrently, the home cluster elements (masthead, greeting, write
     invitation, on-this-day, doors) fade and slide off vertically /
     collapse, between ~0 ms and ~600 ms.
   - The check-in field UI (axis labels at `wide awake / running low /
     hard to be in / easy to be in`, the dot, the `home` back chip, the
     reset icon, the caption + keep button) fades and slides in with a
     small upward drift, between ~80 ms and ~620 ms.
   - The dot is **born at the centre of the former lens position** (uses
     `clusterTop + lensSize/2` as the implied centre) and inherits its
     initial visual `(v, a)` from the lens's mood tint (or `(0, 0)` if no
     recent mood), so the water beneath the dot is already pointing the
     right way at the moment the dot appears.
4. **The sea reacts during the transition.** Because `_seaManager.model`
   is now the single source of truth and the dot's `(v, a)` is piped in
   from the instant the lens is tapped, the wave amplitude/coherence
   begins easing toward the new target while the field UI is still
   sliding into place. The user feels they are stirring the same water.
5. **Release on the way back.** Returning to Home (via the `home` chip or
   system back) does the reverse: the dot fades, the field UI slides down,
   the home chrome comes back, and `_seaManager.model.visualV/A` ease back
   to the day's atmosphere (`_atmo`) within ~1–2 s. No abrupt snapping.

---

## 4. Affected Files (and what changes where)

### `lib/app_shell.dart`
- Replace the `AnimatedSwitcher` that swaps `home`/`checkin` screens
  (lines 579-619) with a single `HomeToCheckinShellscreen` widget
  (new file in `lib/features/home/` driven from here, see §5).
- When `_homeCheckin()` runs, instead of bumping `_checkinNonce` and going
  to a brand-new widget, set `homeTransition: home → checkin` on the shell
  screen. The same widget instance is reused.
- Continue passing `_seaManager` (already a late-final from `locate`) into
  the shell screen so the dot can hand `(v, a)` straight into the model.
- Expose a `void steer(MoodField v, MoodField a)` equivalent — easiest:
  pass `_seaManager.model` (it is already public) into the shell screen
  via constructor.
- The `homeCheckin` flow keeps the same fields (`_checkinEarlier`,
  `_checkinRevisit`, `_checkinInitialV/A`, `_checkinAfterCheck`,
  `_checkinJournaledSubline`) and the same `_homeCheckin` entry point,
  but routes through the new transition state rather than changing
  `_navManager.screen`.

### `lib/home_screen.dart`
- Keep `_lens`, `_ripples`, `_tapLens` essentially as-is. The lens is the
  "ignition" — its dissolve animation becomes the **first beat** of the
  unified transition (already 420/550 ms with `kExhale`).
- Add `onLensOrigin` (an `Offset`) so the shell screen knows where to birth
  the dot (or pass the `clusterTop`/lens centre from the builder above).
- Add `onTransitionStart()` callback (already implicit via
  `_tapLens` → `widget.onCheckin`), used by the shell to begin the
  out-animations on the home cluster.
- Refactor the build so the cluster (masthead/greeting/write-line/
  on-this-day/doors) is wrapped in its own `HomeClusterLayer` that exposes
  `outOpacity / outOffsetY` so the parent shell screen can drive the
  exit choreography without rebuilding the widget.
- The lens's "now is your weather" state is unchanged. The lens is just
  no longer the *only* interactive surface on the home — it is the entry
  point.

### `lib/mood_selector_screen.dart`
- **Remove** the inner `CustomPaint(painter: SeaPainter(model: _model...))`
  (lines 566-574) and remove the `_model`, `_ticker`, `_breathCtrl`
  initialiser logic (124-174 and 190-200). The shell already paints the
  sea.
- Replace field state with two targets `(targetV, targetA)` mirrored from
  drag/keep/revisit logic, exposed through:
    - `void steerSea(v, a)` to push current values into the shared model.
    - `void releaseSea()` to hand control back (transitions `v/a` toward
      zero / atmosphere).
- The dot, axis labels, mood word + chips, footer + keep button, bloom,
  ripples, etc. remain as widget-only concerns (driven by the existing
  targets, edits, captions).
- Wire `onDisappear` (so the home release plays) and accept an
  `onAppear` flow so the dot does its entrance drift from the lens
  centre toward `(0, 0)` (or away from `(clusterTop / centre)` if
  `_checkinEarlier` is set).
- The mascot-side logic (`_keep`, `_keepTimer`, `_bloomGo`, ripples on
  keep, `widget.onKept`) is **unchanged** in semantics — it still calls
  back to the shell's `_onKept`, and that already pipes a ripple into
  `_seaManager.ripple(...)` (app_shell.dart:279). The keep ripple becomes
  felt on the shared sea because the shell painter is the one.

### `lib/features/home/home_to_checkin_shell.dart` *(new)*
Encapsulates the unified screen. Public surface:

```dart
class HomeToCheckinShell extends StatefulWidget {
  const HomeToCheckinShell({
    super.key,
    required this.store,
    required this.seaModel,         // _seaManager.model — single truth
    required this.checkinEarlier,
    required this.checkinRevisit,
    required this.checkinInitialV,
    required this.checkinInitialA,
    required this.checkinAfterCheck,
    required this.checkinJournaledSubline,
    required this.onKept,           // existing MoodEntry callback
    required this.onWrite,
    required this.onDoor,
    required this.onSettings,
    required this.onHome,           // dismiss to home
  });
}
```

It owns a `HomeCheckinState { idle, transitioningIn, checkin, transitioningOut }`
machine. Inside it stacks **two named layers** that are always built (no
animated widget swap), with animation controllers driving their visibility:

- `HomeCluster` — the existing masthead / greeting / write-line / doors /
  on-this-day from `home_screen.dart`. Wrapped in `AnimatedOpacity` and
  `AnimatedSlide` driven by `_outAnim` (0 = visible, 1 = gone).
- `CheckinField` — the dot, axis labels, header question, `home` chip,
  reset icon, caption + keep button, bloom, ripple rings from
  `mood_selector_screen.dart`. Wrapped in `AnimatedOpacity` and
  `AnimatedSlide` driven by `_inAnim` (0 = gone, 1 = visible).
- The lens sits in a third "igniter" layer with its own entrance/exit
  animation that hands its position to the dot, then fades.

On `ignite()` (called by `HomeScreen._tapLens`):
1. start `_lensScale` 1 → 1.6 and `_lensOpacity` 1 → 0 over ~420 ms.
2. at ~80 ms, start `_outAnim` 0 → 1 (home cluster exit) over ~520 ms.
3. at ~140 ms, start `_inAnim` 0 → 1 (check-in field) over ~480 ms.
4. record the lens's `Offset` (`globalCentre`) as `_dotBirthOrigin`.
5. progressively push the dot's `Opacity 0 → 1` and `Scale 0.55 → 1` while
   it drifts from `globalCentre` toward the field-rect centre (or toward
   the `_checkinEarlier` position).
6. **on the same tick**, begin piping the dot's evolving `(v, a)` into
   `seaModel.visualV/A` (over the existing 0.085 follow factor baked into
   the model's `_onTick` analogue — but we now call it explicitly from the
   state). The water is following the dot from frame one. *This is the
   "actively changing the state of the sea" the user is asking for.*

On `release()` (tap `home` chip or system back):
1. begin easing `seaModel.visualV/A` back toward 0 / shell atmosphere via
   `_seaManager.moodSource` override or by clearing the source. (Cheapest:
   swap `moodSource` from `_atmo` to a closure that returns the current
   dot `(v, a)` for ~1.2 s while the release plays, then returns the
   stored atmosphere.)
2. reverse anims (`_inAnim` 1 → 0, `_outAnim` 1 → 0, lens returns in
   place — but the lens paints `Opacity 0` while transitioning out so we
   don't see a flicker), ~520 ms ease-in cubic.
3. transition state machine back to `idle`.

The keep flow and the post-keep invite overlay (`_inviteOpen`,
`_inviteTimer`) are unchanged and live above this widget in the shell —
they keep working the way the JS prototype does, because they only depend
on the navigation manager and `AppStore`, neither of which changes.

### `lib/core/sea_manager.dart`
- No required changes. `SeaFieldModel` already supports `visualV` and
  `visualA` plus eased `sea` state (foam, chop, coherence, etc.) — that is
  exactly what we want the dot to drive.
- Optional cosmetic: expose a `tintAtmosphere((v,a))` helper so the
  shell can swap from `_atmo` → `(v, a)` for the duration of an
  ignited check-in (with a timed release) without tampering with the
  store-level atmosphere. This is the cleanest way to keep the home
  sea from snapping back the moment the user lifts off the dot.

### `lib/core/navigation_manager.dart`
- No change to the enum or the depth map. The `home ↔ checkin` edge may
  remain `depth = 0` for both (the existing map already has both at 0,
  see line 26-27). The shell will stop calling `show(AppScreen.checkin)`
  for this edge and instead drive the local transition state in
  `HomeToCheckinShell`.

### `lib/features/checkin/` *(rest of the package)*
- Unchanged. The selector's widget skeleton is being extracted into the
  new shell; downstream callers (`journal_editor`, `entry_detail`,
  `postJournal`, invite, undertow) all stay outside the screen.

---

## 5. Implementation Order

1. **Extract** the visual layers from `home_screen.dart` into a
   `HomeCluster` widget (lib/features/home/home_cluster.dart). It takes
   the same callbacks (`onWrite`, `onDoor`, `onSettings`) and exposes a
   `ValueListenable<double> outProgress` (0 = visible, 1 = dismissed). No
   behavioural change yet.
2. **Strip** `mood_selector_screen.dart` of its `SeaPainter` and its
   `SeaFieldModel _model`. Replace the local `_onTick` with a small
   method `void steerSea({double v, double a})` that writes through to a
   `SeaFieldModel` passed in by the shell. Confirm nothing else read
   `_model`.
3. **Build** `HomeToCheckinShell` (lib/features/home/home_to_checkin_shell.dart):
   - composes `HomeCluster`, `CheckinField`, and an `IgniterLens`,
   - owns the `_outAnim`, `_inAnim`, `_lensIgnite`, and a single
     `AnimationController` per anim,
   - implements `ignite()` / `release()` and the state machine,
   - injects the shell-level `seaModel` so the dot steers the water.
4. **Wire** it into `lib/app_shell.dart`: replace the `AnimatedSwitcher`
   body that handles `AppScreen.home`/`AppScreen.checkin` with a single
   `HomeToCheckinShell(...)` that is conditionally hidden when
   `_navManager.screen` is `journalhome`/etc. (Use a route-aware wrapper;
   when away from the home↔checkin edge, fall back to the existing code
   path so journal/archive/insights don't change.)
5. **Add** the `_tintSea`/release helper to `SeaManager` (small,
   one-method addition).
6. **Tune** timings in `HomeToCheckinShell`: ensure the lens dissolve
   (`kExhale`, 420/650 ms — already there) ends ~80 ms **before** the
   check-in field is fully visible, so the dot appears to *step out of*
   the dissolving lens. Reduced-motion path: all anims collapse to 0 ms
   but the field still replaces chrome in place (no slide).
7. **Tune** sea follow: keep the dot's drag feeding
   `seaModel.visualV/A` at the existing 0.085 follow factor; on keep
   (`_keep` in selector) call `seaModel.bump()` then
   `_seaManager.ripple(dotC)` for the bloom origin, so the kept ripple
   reads on the *same* water the user was steering.
8. **Verify** back-stack: tapping `home` chip / system back releases
   cleanly; `_atmo` resumes after the `releaseSea` timer; no orphaned
   controllers.

---

## 6. Failure Modes & Edge Cases

- **Reduced motion**: all transitions collapse to instantaneous swaps;
  the dot appears in place, the home cluster disappears. No
  `AnimatedSlide` stuttering.
- **System back while transitioning**: ignore further taps during the
  `transitioningIn` / `transitioningOut` window (state machine guards).
- **Back from another screen (`journalhome → home`)**: the new shell
  widget mounts fresh; `_outAnim` is 0 from the start; no entrance
  jank. The first keep after returning is the normal `home` flow.
- **Keep + invite**: unchanged overlay stack; `onKept` callback still
  fires through to the shell, ripple still goes to shared sea.
- **Revisit / after-check / journaled-subline** flags: passed straight
  through to `CheckinField` as today.
- **Pin lock / welcome / undertow overlays**: still rendered at shell
  level above the new shell-screen — verify z-order is preserved.

---

## 7. Validation

1. `flutter analyze` clean.
2. Manual walks (per platform):
   - Cold-boot → home → tap lens → home chrome fades, check-in settles in,
     and *the water visibly shifts* (amp/chop/coherence) toward the dot
     position as it slides into place.
   - Drag dot across extremes → water tracks continuously.
   - Tap `keep` → bloom on the button, two heart-beat ripples from the
     dot position on the shared water; invite appears later; back to home
     smoothly; sea relaxes toward today's atmosphere.
   - System back during the in-transition → ignored.
   - Pin-lock / onboarding overlays still cover everything.
3. Widget test (goldens): capture three frames — T+0 (pre-ignite),
   T+220 ms (mid-transition, home cluster ~50% out, check-in field
   ~40% in), T+700 ms (settled on check-in). Reduce-motion variant at
   T+0 only (settled state).
4. Reduced-motion gate: with `MediaQuery.disableAnimations = true`:
   no slide, no scale, but the sea still follows the dot (which now
   only updates on the dispatcher frame boundary, not animated).

---

## 8. Out-of-Scope / Not Touching

- `app_store.dart`, AI service, journal editor, archive/insight screens,
  undertow, currents engine, prompt library, calendar, settings, tide lab.
- The animation easings library (`kExhale`, `kBreath`) — kept as-is.
- The dot's per-press ripples — kept; they now also emanate on the shared
  sea because both painters are the same one.
- Atmosphere memory logic (`_refreshAtmosphere`) — behavior unchanged;
  we just override `moodSource` for the duration of a check-in and hand
  it back.

---

## 9. Open Decisions for the Implementation Phase

These will not block this plan going to implementation but should be
confirmed during build:

- **T+A.1** Should the `home` chip on the top-left of the check-in field
  be hidden during the first ~600 ms of the in-transition, so the user
  cannot accidentally back out before the ceremony lands?
  *Default: no, keep visible — reduce-motion users need a stable target.
  Re-evaluate after manual testing.*
- **T+A.2** When `_checkinEarlier` is set (a kept mood earlier today),
  is the dot born at that position, or always at `(0, 0)`?
  *Default: born at `_checkinEarlier`, ease toward `(0, 0)` over ~1.4 s,
  matching today's `moveToMood` behaviour (mood_selector_screen.dart:470).*
- **T+A.3** Should lens ripples (`HomeScreen._ripples`) continue to expand
  *during* the dissolve, or stop at ignite? Stop for clarity.
