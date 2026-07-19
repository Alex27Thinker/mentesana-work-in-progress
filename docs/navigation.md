# Navigation Architecture

## Current

Flat screen switching via `NavigationManager` + `MentesanaShell.setState`. Screen enum: `AppScreen` with 11 values and a depth map.

## Target

```
app/navigation/
├── app_route.dart                — route definitions (replaces AppScreen)
├── navigation_controller.dart    — owns screen state and transitions
└── back_navigation_policy.dart   — tests system-back precedence
```

### Screen Precedence (System Back)

1. Journal editor open → close editor
2. Undertow overlay open → close undertow
3. Post-journal overlay open → close, return to journal home
4. Invite overlay open → close, return to home
5. Current screen → back to home

### Navigation Principles

- `NavigationController` is a `ChangeNotifier` registered in `get_it`.
- The shell observes `NavigationController` and composes the visible screen.
- Transient overlay state belongs in `ShellOverlayHost`, not in feature controllers.
- Shell lifecycle observation has one clear owner.
- No routing-package migration unless an ADR approves it.

### Future Considerations

- Deep link support would require go_router or similar — not currently needed.
- Web URL routing is out of scope for v1.
