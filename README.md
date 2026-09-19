# Nepali Calendar (Bikram Sambat)

A single-file, offline-capable, mobile-first Nepali (Bikram Sambat) calendar.
Everything — markup, styles, data, and logic — lives in `index.html`. No
build step. The only external dependencies are an optional Google Fonts
request and, for the notes feature, the Supabase JS client + your Supabase
project.

Open `index.html` directly in a browser to use it.

## What's inside

- Monthly BS grid, weeks starting Sunday (आइतबार), Saturday marked as the
  weekly holiday.
- Each day cell shows the BS date (large) and the equivalent AD date (small).
- Month/year navigation: previous/next, "today" (computed in Nepal Standard
  Time, UTC+5:45, regardless of the browser's local timezone), and a
  year/month picker dialog.
- BS ⇄ AD converter panel (collapsible, below the calendar).
- नेपाली / English toggle for all labels and numerals (०१२३४५६७८९).
- Clicking or pressing Enter on a day opens a details dialog: full BS date,
  AD date, weekday, and any recorded holidays/events.
- Light/dark theme: follows the OS preference automatically, with a manual
  override button (🌓) that cycles Auto → Dark → Light, saved in
  `localStorage`.
- Keyboard support: arrow keys move between days (crossing month/year
  boundaries at the edges), Enter/Space opens the details dialog. Grid
  cells use `role="grid"`/`"gridcell"` and `aria-label`s carrying the full
  spoken date.
- Per-day notes, backed by Supabase: open a day's details dialog to see
  and add free-text notes for that date, and delete them. Days with notes
  get a small blue dot on the grid (distinct from the orange holiday dot).
  See "Notes / Supabase setup" below.
- A "Self-tests" panel at the bottom re-runs on every load: it checks the
  BS↔AD conversion against several independently verified reference dates
  (see below), a leap-year AD date, a BS year boundary, and out-of-range
  handling. Results also print to the browser console.

## Where the calendar data comes from (important)

The Bikram Sambat calendar has **no closed-form formula** — month lengths
(29–32 days) were fixed year by year by Nepal's calendar authorities, so a
correct converter needs a real lookup table, not a computed approximation.

`BS_CALENDAR_DATA` in `index.html` (BS 2000–2090) is reproduced from the
open-source (MIT-licensed) project
[whitphx/nepali-calendar-js](https://github.com/whitphx/nepali-calendar-js/blob/master/index.js),
a long-circulated dataset used by numerous Nepali date converters.

The conversion anchor — **1 Baisakh 2000 BS = 14 April 1943 AD** — and
several other year-start dates spread across the table (BS 2050, 2070,
2080, 2081, 2082) were independently cross-checked against
[nepalicalendar.rat32.com](https://nepalicalendar.rat32.com/) during
development; all matched exactly. (Note: some sources quote 13 April 1943
for this anchor — that's off by one day from both the sourced data table's
own internal reference and the independent site above, so 14 April was
used.)

Conversion itself is done with plain day-count arithmetic against that
anchor (see `bsToAD` / `adToBS` in the `<script>` block) — no borrowed
algorithm, just the sourced table plus straightforward addition.

## Holidays / events

`FIXED_BS_HOLIDAYS` includes six national holidays whose **BS date is
fixed every year** (verified against Wikipedia's "Public holidays in
Nepal" and hamropatro.com / nepalipatro.com.np):

| BS date        | Holiday |
|----------------|---------|
| Baisakh 1      | Nepali New Year |
| Jestha 15      | Republic Day |
| Ashoj 3        | Constitution Day |
| Poush 27       | Prithvi Jayanti |
| Magh 16        | Martyrs' Day (Shahid Diwas) |
| Falgun 7       | Democracy Day |

**Lunar/movable festivals are intentionally NOT included** — Dashain,
Tihar, Holi, Buddha Jayanti, Chhath, Maghe Sankranti, Eid, etc. shift by
the Nepali lunar calendar and change AD/BS-day-of-month every year. Adding
these accurately requires a yearly-updated authoritative source (e.g. the
official Government of Nepal calendar or a maintained API such as Hamro
Patro's). Guessing them would silently produce wrong dates, so they're
left out rather than approximated. There's an empty
`LUNAR_HOLIDAYS_BY_DATE` object ready for that data — see below.

## Updating the calendar for future years (past BS 2090)

1. **Get verified data.** Do not hand-type or estimate month lengths.
   Good sources:
   - An updated release of a maintained npm/GitHub package such as
     `nepali-date-converter`, `nepali-datetime`, or the
     `whitphx/nepali-calendar-js` repo this file's data came from.
   - The official Government of Nepal calendar (Nepal Panchang Nirnayak
     Samiti / Ministry of Home Affairs publications).
2. **Add entries to `BS_CALENDAR_DATA`** in `index.html`, one per year:
   ```js
   2091: [31,32,31,32,31,30,30,30,29,30,29,31], // 12 month lengths, sum = 365 or 366
   ```
3. **Bump `BS_MAX_YEAR`** to the new last year covered.
4. **Sanity-check** by opening the page: the self-tests panel will still
   pass (they only assert facts inside BS 2000–2090), but you should
   manually verify a known date in the new year range against an external
   source, then optionally add it as a new `check(...)` call in
   `runSelfTests()` inside `<script>`.
5. **Add any newly-known fixed-date holidays** to `FIXED_BS_HOLIDAYS`, or
   lunar/movable events for specific years to `LUNAR_HOLIDAYS_BY_DATE`
   using the key format `"BSyear-month-day"`, e.g.:
   ```js
   const LUNAR_HOLIDAYS_BY_DATE = {
     "2082-7-2": [{ ne: "विजया दशमी", en: "Vijaya Dashami (Dashain)" }]
   };
   ```

## Notes / Supabase setup

Per-day notes are stored in a Supabase Postgres table and read/written
straight from the browser with the public **anon** key — there's no login
system in this app.

1. Run [`supabase-schema.sql`](supabase-schema.sql) in your Supabase
   project's SQL editor. It creates the `calendar_notes` table and Row
   Level Security policies that let the `anon` role select/insert/delete.
2. In `index.html`, `SUPABASE_URL` and `SUPABASE_ANON_KEY` near the top of
   the `<script>` block (search for "PER-DAY NOTES") are already set for
   this project's Supabase instance. To point at a different project,
   replace those two values — the URL is on the **Data API** settings
   page, the key is the one labeled **`anon` / `public`** (sometimes shown
   as a "publishable key") on the **API Keys** page. Never put the
   `service_role` / secret key here — it bypasses RLS and must stay
   server-side only.
3. The anon key is safe to have visible in client-side code by design (RLS
   is what enforces access rules, not key secrecy) — but as shipped, the
   policies allow **anyone who loads the page** to add or delete notes,
   since there's no auth to scope them by user. That's fine for a
   personal/local tool. If you host this page publicly and want real
   access control, add Supabase Auth and change the policies in
   `supabase-schema.sql` to check `auth.uid()` instead of allowing `anon`
   everything.
4. If the Supabase script fails to load (offline, blocked CDN, wrong
   keys), the calendar itself still works — only the notes panel shows an
   inline "unavailable" message instead of the add-note form.

## Offline use

The only network dependency is the optional Google Fonts link (Noto Sans
Devanagari) in `<head>`, plus the Supabase JS client (for notes) and calls
to your Supabase project. The calendar/converter/self-tests work with zero
network requests — delete the Google Fonts `<link>` tags and the Supabase
`<script src>` (and its usages) if you want a version with no external
calls at all; the CSS font stack already falls back to system Devanagari
fonts (`Nirmala UI` on Windows, etc.) either way.

## Supported range

BS 2000–2090 (≈ AD 1943 to AD 2034). Dates outside this range are
rejected with a clear error message in both the converter panel and the
navigation (prev/next buttons disable at the table's edges) rather than
silently producing a wrong date.
