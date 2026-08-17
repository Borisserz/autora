# Design — Autora

Locked system for the iOS catalog. Do not rotate themes per tab.

## Genre
editorial (letterpress workshop, Belarus car catalog)

## Macrostructure family
App pages: Catalogue. Photo is the product. Masthead wordmark + hairline. No card-in-card.

## Theme
- paper light `#E6E8E5` · paper dark `#090A09`
- ink light `#141615` · ink dark `#E6E8E5`
- muted `#6C706E`
- accent brass TOP only `#9A8B5C`
- no av.by `#0084E6`, no cream `#F4F1EA`, no purple

## Typography
- Display: New York / SF serif, roman, wordmark + listing titles only
- Body: SF
- Mono: SF tabular for prices
- Photo: card 360 · detail 460 · gutter 20

## Motion (max 3 primitives)
1. Zoom card → detail (`navigationTransition`)
2. Catalog stagger once (opacity + 12pt, cap 420ms)
3. Ink press (scale 0.975, 120ms) + masthead hairline draw

Reduce Motion: skip spatial motion, keep opacity ≤150ms.

## Assets
Linocut empty-state stills. Grain tiled at low opacity. Tab bar: one SF glyph, 26pt, ink. Not stickers, not 3D.

## Voice
Russian UI. Specific. No 01/02, no “10k+”, no glass.
