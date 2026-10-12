---
version: 1
slug: "apps-nexo-social"
primary_target: "apps/nexo_social"
related_targets: []
---

# Surface brief — Nexo app (Flutter, phone-first)

Scope: the whole Flutter client (`apps/nexo_social`), every shell screen plus
auth, composer, live room chrome, moderation and admin. Visitor mode:
**Operate** (app UI). Primary device: phone (iOS); desktop/web adapt.

Audience and job: creators publish and go live; fans browse, react and join
lives; moderators act on comments with an audit trail. The demo path
(publish → schedule/start live → guest → moderator hides a comment → replay)
must read at first sight.

Constraints: keep public names/signatures of AppColors, AppSpacing, AppRadii,
AppSizes, textTheme, StatusBadge, UserAvatar, SectionHeader, FilterPill,
compactCount, NexoPage, Enter/EnterStatic/Pop (another session compiles
against them); values may change. `features/live/**` is owned by another
session until released. Test keys and copy listed by the previous session
stay. Nothing overflows at 320.

## Direction contract

THESIS: Nexo is a sticker sheet. Everything you post, react with or collect is
a die-cut sticker peeled off a dark liner, cut exactly like the logo cat:
white fill, thick ink outline, kiss-cut border. It refuses the category
default: a white feed of bordered rounded cards with one blue accent.

OWN-WORLD: Black glossy liner (#0F0F12) as ground. White stickers carry the
primary actions (white fill, ink text). Kiss-cut borders are white, or holo
foil (the logo gradient: cyan → iris → violet → magenta, lime → green → cyan),
and holo is reserved for what is ON AIR. Flat vinyl colors from the logo
(cyan, iris, violet, magenta, lime, green) plus a hot sticker red for live and
reactions. Display: Dela Gothic One. Text: M PLUS Rounded 1c. State
vocabulary: scheduled = dashed cut line (still on the sheet), live = holo
border, ended/replay = plain white border, hidden = the sticker's back
(liner side with the reason printed).

STORY: A fan opens Nexo at night and sees a sheet of creators. Whoever is on
air is ringed in holo foil. They slap a heart sticker on a post, peel into a
live, and the mascot cat keeps them company in every empty or broken moment.

FIRST VIEWPORT: Feed (Inicio), 390×844. Top: cat mark + "Nexo" in Dela Gothic
at 22, avatar sticker at right. A row of die-cut avatar stickers (holo ring =
live). The filter row as stickers on the sheet: the selected one is a white
sticker with ink text. Next, the featured live as a large holo-bordered media
sticker with a red "EN VIVO" sticker slapped at the corner. Then posts on the
liner with die-cut media and an action row. The tab bar is a dark material
strip; the center create action is a white sticker disc with an ink "+".

FORM: Plancha de stickers (die-cut vinyl sticker sheet). It was position 1 on
the grounded list and was offered as IMPECCABLE’S PICK. Seed key 84c6d906,
user-chosen over the assigned "Backstage · All Access". Signature interaction:
liking slaps a sticker onto the post (scale-down "slap" with a slight random
tilt), and holo borders sweep slowly while something is on air.

FINISH: unreviewed and undocumented is unfinished; this build ends with the finish review, the verdict, DESIGN.md, and every shipping raster carrying its provenance

## Unresolved

- Animations of the mascot come later, made with Higgsfield video. Confirm
  the model with the user first: they rejected the cheapest image model's
  output.
- Remaining Material icons with a reason: the Apple brand glyph, status dots,
  unused fallback icon params, and the demo-account picker (owned by another
  session).
- iOS-simulator captures are still pending: this machine has no Xcode, so
  evidence came from a Flutter web build at a phone viewport.
