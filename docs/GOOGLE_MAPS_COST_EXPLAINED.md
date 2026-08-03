> **⚠️ HISTORICAL — describes a system that no longer exists.**
>
> BlueEra was migrated off Google Maps Platform to OpenStreetMap on 2026-08-03.
> There is no `google_maps_flutter`, no Places/Geocoding/Directions/Static Maps
> usage, and no Google Maps API key in the app any more.
>
> Kept because the cost analysis explains **why** the current design looks the
> way it does (session caches, rate floors, static previews). Do not follow it
> as instructions.
>
> Current docs: `OSM_DEVOPS_GUIDE.md`, `OSM_BACKEND_GUIDE.md`,
> `OSM_FRONTEND_GUIDE.md`.

# Why Our Google Maps Bill Is High — Explained Simply

A plain-language summary for anyone who needs to understand the problem without
reading code. If you want the technical detail, see:

- `GOOGLE_MAPS_COST_GUIDE.md` — for the app developers
- `GOOGLE_MAPS_BACKEND_DEVOPS_GUIDE.md` — for the server and cloud team

---

## The short version

1. Google charges us **for every single request** our app makes to their maps
   service. Not a monthly fee — a per-request fee.
2. Our app was making **far more requests than it needed to**, and was asking for
   a more expensive type of data than it actually used.
3. We have **fixed the biggest problem already**. Some smaller ones remain, and
   there is **one important thing we still need to check** — see the last
   section.

---

## What are we actually paying for?

Think of Google Maps as a shop where each question costs money. Our app asks four
kinds of questions:

| We ask Google | When | Rough cost |
|---|---|---|
| "Show me suggestions for this address the user is typing" | Address search | Cheap-ish |
| "Give me the full information about this one place" | After a place is chosen | **Expensive** |
| "Draw me the driving route between these two points" | Ride tracking, navigation | **Expensive** |
| "Show a map on the screen" | Any screen with a map | Medium |

The important thing to understand: **the price is per question**. Ask the same
question a thousand times, pay a thousand times.

---

## Why was the bill so high?

### Problem 1: We were asking about places nobody looked at

This was the biggest one.

When a user typed an address, Google returned about 5 suggestions. Our app then
immediately asked Google for **full details of all 5** — even though the user
would tap only one.

Worse, this repeated **every time the user paused while typing**. A single
address entry could trigger around 15-20 of these expensive requests. The user
used exactly one.

> **Simple analogy:** a customer asks "what drinks do you have?" and you list
> five. Instead of waiting for them to choose, you make all five drinks, throw
> four away, and repeat this every time they change their mind.

**Fixed.** The app now asks for details of only the place the user actually taps.
Roughly a 15-20× reduction on this type of request.

### Problem 2: We were asking for expensive information we never used

When asking about a place, Google lets you specify what you want. Ask for just
the location and it is the cheapest rate. Ask for everything — reviews, photos,
opening hours, phone numbers, ratings — and it costs much more.

**We were not specifying anything**, which means Google sent everything and
charged the highest rate. Our app only ever used the location coordinates. We
were paying premium prices for data we threw away.

> **Simple analogy:** ordering the full thali every time when you only ever eat
> the rice.

**Fixed.** The app now asks only for what it uses, at the cheapest rate.

### Problem 3: Ride tracking kept re-asking for the same route — **now fixed**

While a ride is running, the app draws the route on the map. It was set to
refresh that route whenever the vehicle moved about **11 metres** — which a
moving vehicle does every second or two.

So during a ride, the app was buying a fresh route roughly **every 10 seconds**.
And the rider's phone and the customer's phone were each doing this separately,
for the same journey.

> **Simple analogy:** buying a fresh printed map every ten seconds during a
> journey, when the road has not changed.

**Fixed.** Every map and tracking screen — 11 of them — now goes through one
shared piece of code that waits at least 30 seconds, requires real movement
before re-asking, and remembers routes it has already bought. Because it
recognises the same journey, the rider's phone and the customer's phone now
share one route instead of buying two.

The *proper* fix is still ahead of us: our own server works the route out once
and sends it to both phones, so neither has to ask Google at all. That is a
server job and is planned.

### Problem 4: A trap waiting to happen (not costing us today)

There is code in the app that asks Google for "the list of cities in this state"
— a list that never changes and should be stored by us, not bought repeatedly.

**Good news: nothing currently uses it**, so it is costing nothing right now. But
it is sitting there ready for the next developer to wire up. Either delete it, or
replace it with our own stored list before anyone uses it.

---

## What we have fixed so far

| Fix | Status |
|---|---|
| Stop requesting details for places nobody selected | **Done** |
| Stop paying premium rate for data we do not use | **Done** |
| Stop searching before the user has typed enough to mean anything | **Done** |
| Remember answers we already paid for, within one app session | **Done** |
| Slow down route refreshing — **all** map and tracking screens | **Done** |
| Stop paying for a live map in every chat location bubble | **Done** — see the note below |
| Server works out routes once instead of each phone doing it | Not done — **server team only** |
| The unused city-list code | Not costing anything today; tidy it up |
| Check the remaining ~44 screens that show maps | Not done — needs an audit |

One extra saving worth mentioning: during a ride, the rider's phone and the
customer's phone were each buying the same route separately. They now share one,
because the app recognises it is the same journey.

### About the chat location bubbles

When someone shares their location in chat, that bubble used to contain a **real,
live map**. Chat messages are thrown away when you scroll past them and rebuilt
when you scroll back — so every time a location message came back on screen, we
bought another map.

It is now a **picture** of the map instead. The picture is saved on the phone, so
seeing it again — later in the same scroll, or after restarting the app — costs
nothing. You can no longer drag or zoom inside the small bubble, but tapping it
opens the full map exactly as before.

> **One setup step:** someone with Google Cloud access must switch on the "Maps
> Static API" for our project. Without it these bubbles show a grey box with a
> pin instead of a map. Nothing crashes, but it looks broken.

### Before this ships

None of these changes has been tested by a person yet — only checked
automatically for errors. Address search, ride tracking and the chat location
bubbles all behave differently now, so someone should try booking a ride,
searching an address, and sharing a location in chat before this goes to users.

---

## One important thing we still do not know

**We have not yet looked at Google's own breakdown of the bill.**

Everything above came from reading our app's code and finding waste. That tells
us what *looks* wasteful — it does not tell us where the money actually went.

Google's dashboard can show exactly which type of request cost the most. Someone
with access to our Google Cloud account should check this. It takes about ten
minutes. Until then we are fixing what we believe is expensive, not what we have
proven is expensive.

### There is also a security question worth taking seriously

Our app carries a Google "key" — like a credit card that Google charges. Because
the key sits inside the app, a technical person can extract it from the app and
use it themselves, and **our account gets the bill**.

We do not know whether this has happened. The same ten-minute dashboard check
would show it: if we see requests coming from places our app does not run, or for
map services our app never uses, then someone else is spending our money.

If that turns out to be the case, it is **more important than everything else in
this document**, because no amount of improving our app would reduce that bill.

Two protective steps the cloud team should take regardless:

- **Set a daily spending limit** on each service. If something goes wrong, a
  feature stops working and we find out the same day — instead of finding out
  from an invoice a month later.
- **Set up billing alerts** so a person is emailed when spend crosses a
  threshold.

---

## When will the bill actually go down?

Not immediately, for two reasons:

1. **Users must update the app.** People still running the old version keep
   costing the old amount until they update. The saving grows as more people
   update.
2. **Google bills monthly.** You will see the trend in the daily dashboard well
   before the invoice reflects it.

---

## What should we expect?

Honest answer: **a clear reduction, but we cannot promise a specific number yet.**

The fixes we made target one particular type of request. If that type is what was
driving the bill, the drop will be large. If most of the money was actually going
to route requests, map displays, or a leaked key, then today's work helps less
and the remaining items matter more.

**That is exactly why the ten-minute dashboard check matters.** It turns "we
think this will help" into "we know what to fix next."

---

## Common questions

**Can we just switch off Google Maps?**
Not realistically. Address search, ride tracking and navigation depend on it.
The goal is to stop wasting requests, not to stop using maps.

**Is a cheaper alternative available?**
Alternatives exist, but switching is a large project and carries its own risks
around accuracy and coverage in India. Worth evaluating only after we have
removed the waste — it would be unwise to migrate while still making 20 times
more requests than necessary.

**Did somebody make a mistake?**
These are common patterns that look perfectly reasonable while writing the code.
The costly part is invisible: nothing crashes, nothing looks slow, and the app
behaves correctly. It only shows up on the bill. The useful outcome is that we
now have written rules so new code does not repeat it.

**How do we stop this happening again?**
Three things: the daily spending limits described above, the coding rules written
down in the developer guide, and moving these requests to our own server so they
can be counted, limited and cached in one place instead of being scattered across
the app.
