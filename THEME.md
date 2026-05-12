# Hyprland Grayscale — Theme Context

A plain-text reference for applying the grayscale theme consistently across
every config: Hyprland, Waybar, Kitty, Rofi/Wofi, Mako/Dunst/SwayNC, GTK,
file managers, editors, lockscreen, etc.

The rule: zero hue, zero chroma, ever. No blue accents, no warm tints, no
"almost-black-with-a-touch-of-blue". Every value below is a pure neutral
gray on the R = G = B axis.

---

## 1. The Color Ladder (16 steps)

Use these tokens by name. Do not invent intermediate values; if you need
something between two steps, pick the closer step and move on.

```
g-000   #000000     pure black                   bar / OLED
g-050   #060606     deepest surface              full-screen overlays, lock
g-100   #0d0d0d     app shell                    main window background
g-150   #141414     sidebar                      secondary nav surface
g-200   #1a1a1a     panel                        cards, menus, launcher body
g-250   #1f1f1f     elevated panel               notifications, popovers
g-300   #262626     hover                        row/button hover
g-350   #2e2e2e     active / pressed             selected workspace, pressed btn
g-400   #383838     hairline emphasis            stronger divider
g-500   #4a4a4a     disabled foreground          inactive icons & controls
g-600   #6b6b6b     tertiary text                timestamps, hints
g-700   #8a8a8a     secondary text               labels, meta
g-800   #b0b0b0     muted primary text           rarely needed
g-900   #d6d6d6     primary text                 default body & UI
g-950   #ebebeb     high-emphasis text           headings, active item, cursor
g-999   #f5f5f5     pure highlight               focus state, urgent only
```

Hairlines (1px borders/dividers) are not solid grays — they are white at
low opacity, so they sit visually on top of any underlying surface:

```
hairline      rgba(255,255,255,0.06)   default divider
hairline-2    rgba(255,255,255,0.10)   stronger border (panels, inputs)
hairline-3    rgba(255,255,255,0.16)   focus ring, emphasis
```

---

## 2. Surface Stacking Rule

Surfaces step UP in lightness as they nest deeper. This is the single
mental model behind every screen.

```
desktop / bar       g-000   #000000     ← always pure black
   └ app shell      g-100   #0d0d0d
       └ sidebar    g-150   #141414
           └ panel  g-200   #1a1a1a
               └ elevated panel  g-250   #1f1f1f
```

Hover and active states are NOT separate surfaces — they are the next
step up applied temporarily on top of whatever surface you are on:

```
default row             (parent surface, no fill)
hover row               g-300   #262626
selected / pressed row  g-350   #2e2e2e
```

Never skip steps. A panel at g-200 hovers to g-300 (one step), not g-400.
Never invert the ladder (a sidebar darker than the shell). Never tint a
surface based on app type — every app uses the same recipe.

---

## 3. Foreground / Text

Three text levels cover ~95% of cases. Reach for a fourth only when truly
needed.

```
g-950   #ebebeb     fg-strong       headings, active item, cursor, focused row text
g-900   #d6d6d6     fg              default body and UI text
g-700   #8a8a8a     fg-muted        secondary labels, captions, meta
g-600   #6b6b6b     fg-dim          tertiary, timestamps, placeholder, hints
g-500   #4a4a4a     fg-disabled     disabled controls and icons
```

Rules:
- Body text on any surface from g-000..g-250 must be at least g-900.
- Never put fg-dim (g-600) on g-100 or darker — it falls below readable
  contrast. fg-dim is for ≥ g-200 surfaces only.
- Active/selected rows always upgrade their text from g-900 to g-950.
- Disabled text uses g-500 AND reduces opacity is wrong — use the token,
  not opacity.

---

## 4. Borders, Dividers, Outlines

- 1px is the only border weight. No 2px, no thick frames.
- Dividers between rows: `hairline` (`rgba(255,255,255,0.06)`).
- Borders around panels, inputs, terminal frames: `hairline-2`
  (`rgba(255,255,255,0.10)`).
- Focus ring or emphasized outline: `hairline-3`
  (`rgba(255,255,255,0.16)`) OR a solid g-500 (`#4a4a4a`).
- The bar's right edge against the desktop uses `hairline`.
- Window borders in Hyprland: active = g-950 (`#ebebeb`), inactive = g-200
  (`#1a1a1a`). Both at 1px.

Never use a colored border. Never use a glowing border. If you need to
draw attention, raise the surface a step instead.

---

## 5. Border Radius

Sharp, restrained. Three radii, used consistently:

```
r-sm    4px     buttons, chips, workspace pills, small inputs
r-md    6px     panels, cards, terminal window, file manager, launcher
r-lg    10px    full-screen modals, lock screen card (rare)
```

Hyprland window rounding: **4px**. Match it across all apps. Never use
8px, never use a radius above 10px. No fully-rounded ("pill") shapes
except for toggle switches.

---

## 6. Spacing

Use a 4px base. Stick to multiples of 4.

```
4    inner padding of dense rows, gap between bar icons
8    standard gap between sibling controls, panel inset
12   panel padding, list-row vertical padding
16   card padding, section spacing
24   panel-to-panel spacing, section breathing room
32+  outer page margins only
```

Hyprland gaps: `gaps_in = 4`, `gaps_out = 8`. Tighter than typical
desktops because the system already feels quiet — you don't need
generous gaps to calm it down.

---

## 7. Typography

Two families, both metrics-matched:

```
sans    Geist          UI, labels, body
mono    Geist Mono     terminal, code, status bar, timestamps
```

Weight scale: 300 / 400 / 500 / 600. Never bold (700+). Headings are 500.

Type scale (px / line-height / letter-spacing / weight):

```
display     40 / 1.05 / -0.025em / 500    rare, used in headers/lock
h1          24 / 1.2  / -0.015em / 500    window titles, major sections
h2          18 / 1.3  / -0.01em  / 500    panel headings, menu items
body        14 / 1.55 /  0       / 400    default UI and body text
small       12 / 1.5  /  0       / 400    captions, helper text
mono lg     14 / 1.6  /  0       / 400    terminal default
mono sm     11 / 1.6  /  0.02em  / 400    waybar, status text, timestamps
```

Rules:
- The bar uses mono sm — always. It's how clocks, battery %, network
  speeds stay aligned.
- Terminal uses Geist Mono at 12pt minimum.
- All-caps labels (section headers, status chips) use mono with 0.04em
  to 0.1em letter-spacing and color fg-dim.
- Never mix three font families. Never use system-ui as a fallback for
  Geist — pin Geist explicitly.

---

## 8. Component Patterns

### Buttons
Three kinds, no more.

```
primary     background g-950, text g-000, no border          confirm, apply
default     background g-200, text g-900, border hairline-2  cancel, neutral action
ghost       transparent, text fg-muted, no border            tertiary, dismiss
```

Hover:
- primary → background g-999
- default → background g-300, text fg-strong
- ghost   → text fg-strong (no background change)

Padding: 7px 14px. Radius: r-sm (4px). Font: sans 12px / 400.

### Inputs
Background g-100, border hairline-2, radius r-sm. Font: mono 12px.
Focus state: border becomes g-500. Placeholder is fg-dim (g-600).

### Toggles
Width 32, height 18, fully rounded.
Off: track g-300, thumb g-700.
On:  track g-950, thumb g-100.

### Status chips
Mono 10px, 0.05em tracking, 4×8 padding, radius 3px (one tick smaller
than r-sm intentionally).
- ACTIVE   bg g-200, text fg-strong, border hairline-2
- IDLE     bg g-100, text fg-muted,  border hairline
- DISABLED transparent, text fg-dim, border hairline-2
- FOCUS    bg g-950, text g-000

### Progress / sliders
Track g-200, fill g-900 (progress) or g-800 (slider). Slider thumb is
g-900 with a 2px g-100 border so it reads on any surface.

---

## 9. Shadows

Used sparingly and only on truly floating things (launcher, notifications,
modals).

```
shadow-1    inset top-highlight + 0 8px 24px rgba(0,0,0,0.5)
            terminal, panels that can move
shadow-2    inset top-highlight + 0 16px 48px rgba(0,0,0,0.65)
            launcher, full-screen modals, lock card
```

The inset top-highlight (`0 1px 0 rgba(255,255,255,0.04) inset`) is what
gives surfaces a faint "lit edge" without using a colored border. Keep it.

Hyprland decoration: `drop_shadow = false`. The window already sits on
black; a shadow does nothing useful and adds noise.

---

## 10. Blur

Hyprland blur is allowed but conservative:

```
size    6
passes  2
```

Higher values smear the grayscale into mush. Two passes at size 6 keeps
the wallpaper legible behind floating windows without bleeding.

---

## 11. Wallpaper Discipline

The whole system assumes a dark, low-saturation wallpaper. If the
wallpaper is bright or colorful, the bar (pure black) will feel
disconnected. Recommend:
- Dark photographs, dusk/night scenes, near-monochrome.
- If using anything saturated, drop its brightness to ≤ 30% and add
  a slight desaturation pass. The system is the UI, not the picture.

---

## 12. The Bar (Hyprland-side)

Always:
- Position: left edge.
- Width: 36px fixed.
- Background: `#000000` (g-000).
- Right border: 1px hairline (`rgba(255,255,255,0.06)`).
- Workspace numbers: mono 11px.
  - default → fg-dim (g-600)
  - has windows → fg-muted (g-700)
  - active → background g-250, text fg-strong, radius r-sm
  - hover → background g-300
- Tray icons: 14×14 stroke icons, color fg-muted. Hover → fg-strong.
- Time at bottom, vertical, mono 9px, fg-muted, 0.08em tracking.

Never put a colored dot, badge, or status indicator on the bar. If
something needs attention, change the icon's color to fg-strong (g-950).
Urgent state may use g-999 — that is the only escalation.

---

## 13. Anti-Patterns (Do Not Do)

- Do not add a single accent color "for life". The whole point is
  zero color. If the user wants energy, they get it from the wallpaper.
- Do not use opacity to fake gray steps. Use the ladder.
- Do not use 2px borders or glow effects.
- Do not round corners above 10px.
- Do not mix gray temperatures (no #0a0a0c next to #0d0d0d). Every gray
  is on the R=G=B axis.
- Do not use semantic colors for states (no green for success, no red
  for error). Severity is communicated by:
  - fg-strong text, OR
  - urgent state bumping to g-999, OR
  - a 1px g-950 border on the affected element.
- Do not use emoji or full-color icons in chrome. Stroke icons only,
  drawn in fg-muted, hover to fg-strong.
- Do not use system fonts as a Geist fallback at the same size — fall
  back to a stack of the same metrics, or accept the visible swap.

---

## 14. Quick Cross-App Mapping

```
Hyprland border (active)     #ebebeb
Hyprland border (inactive)   #1a1a1a
Hyprland rounding            4
Waybar bg                    #000000
Waybar fg                    #d6d6d6
Waybar workspace.active bg   #1f1f1f
Waybar workspace.active fg   #ebebeb
Kitty/foot bg                #0d0d0d
Kitty/foot fg                #d6d6d6
Kitty cursor                 #ebebeb
Kitty selection bg           #2e2e2e
Rofi/Wofi panel bg           #1a1a1a
Rofi/Wofi selected bg        #262626
Rofi/Wofi selected fg        #ebebeb
Mako/Dunst bg                #1f1f1f
Mako/Dunst border            #2e2e2e
Mako/Dunst urgent border     #ebebeb
Hyprlock card bg             #0d0d0d
Hyprlock card border         hairline-2
GTK theme base               Adwaita-dark, override accents to #ebebeb
```

---

## 15. Decision Heuristic

When in doubt, ask in this order:

1. What surface am I on? (read the ladder)
2. What's one step up? (that's hover)
3. What's two steps up? (that's active)
4. Is the text on the highest-emphasis level for this state?
5. Did I add any color? Remove it.
6. Did I add a radius above 10px? Reduce it.
7. Did I add a border thicker than 1px? Reduce it.

If the answer to all of the above is clean, the design is on-system.
