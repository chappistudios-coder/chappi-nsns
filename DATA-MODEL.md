# Data model (taken from the running code)

All app data lives in one in-memory object `S` created by `emptyData()` / `hydrateData()` in `index.html`. **Nothing is saved anywhere** (no database, no localStorage except the light/dark theme). Field lists below were read from objects created by the test in `tests/logic-smoke-test.js`. Collections that were empty in that test show "not created in test".

Suggested Firestore mapping: each top-level collection below becomes a Firestore collection (or a subcollection of the owning user/kitchen).

## `S.radius`
Single value (number).

## `S.size`
Single value (string).

## `S.loc`
Object (not created in test; see `emptyData()` and the functions that write to it).

Keys seen: `name`, `lat`, `lng`, `custom`

## `S.areas`
Array (not created in test; see `emptyData()` and the functions that write to it).

## `S.kitchens`
Map keyed by id:

| field | type |
|---|---|
| `id` | string |
| `n` | string |
| `lat` | number |
| `lng` | number |
| `veg` | number |
| `rating` | number |
| `ratingCount` | number |
| `plans` | array |
| `cap` | number |
| `used` | number |
| `prep` | number |
| `caps` | array |
| `area` | string |
| `active` | boolean |
| `commission` | number |
| `payoutToday` | number |

## `S.kd`
Map keyed by id:

| field | type |
|---|---|
| `key` | string |
| `kid` | string |
| `did` | string |
| `rating` | number |
| `rc` | number |
| `orders` | number |

## `S.T`
Map keyed by id:

| field | type |
|---|---|
| `_max` | number |
| `_meals` | number |
| `dal-tadka` | object |
| `roti` | object |
| `rice` | object |
| `aloo-gobhi` | object |
| `bhindi` | object |

## `S.customers`
Map keyed by id:

| field | type |
|---|---|
| `id` | string |
| `name` | string |
| `phone` | string |
| `email` | string |
| `notify` | object |
| `vegOnly` | boolean |
| `tierOverride` | null |
| `favs` | object |
| `kfavs` | array |
| `addresses` | array |
| `pay` | array |
| `prefsMenu` | object |

## `S.users`
List of records:

| field | type |
|---|---|
| `id` | string |
| `phone` | string |
| `name` | string |
| `email` | string |
| `roles` | array |
| `kid` | string |

## `S.staff`
Array (not created in test; see `emptyData()` and the functions that write to it).

## `S.orders`
List of records:

| field | type |
|---|---|
| `id` | string |
| `cid` | string |
| `who` | string |
| `kid` | string |
| `did` | string |
| `size` | string |
| `lines` | array |
| `units` | number |
| `items` | array |
| `price` | number |
| `km` | number |
| `eta` | number |
| `addr` | object |
| `status` | string |
| `partner` | null |
| `hist` | array |
| `rated` | boolean |
| `day` | string |

## `S.subs`
List of records:

| field | type |
|---|---|
| `id` | string |
| `cid` | string |
| `tier` | string |
| `days` | number |
| `size` | string |
| `done` | number |
| `skipsUsed` | number |
| `pausesUsed` | number |
| `changesUsed` | number |
| `paused` | boolean |
| `slot` | string |
| `addr` | object |
| `start` | number |
| `expiry` | number |
| `menu` | null |
| `premium` | null |
| `custom` | object |

## `S.payments`
List of records:

| field | type |
|---|---|
| `id` | string |
| `cid` | string |
| `what` | string |
| `amt` | number |
| `t` | number |
| `how` | string |
| `state` | string |

## `S.partners`
Object (not created in test; see `emptyData()` and the functions that write to it).

## `S.complaints`
Array (not created in test; see `emptyData()` and the functions that write to it).

## `S.refunds`
Array (not created in test; see `emptyData()` and the functions that write to it).

## `S.promos`
Array (not created in test; see `emptyData()` and the functions that write to it).

## `S.apps`
List of records:

| field | type |
|---|---|
| `id` | string |
| `type` | string |
| `uid` | string |
| `applicant` | object |
| `form` | object |
| `docs` | object |
| `reqSnapshot` | object |
| `status` | string |
| `date` | number |
| `verify` | object |
| `msg` | string |
| `history` | array |

## `S.notes`
Map keyed by id:

| field | type |
|---|---|
| `0` | object |

## `S.docReqs`
Map keyed by id:

| field | type |
|---|---|
| `0` | object |
| `1` | object |
| `2` | object |
| `3` | object |
| `4` | object |
| `5` | object |
| `6` | object |

## `S.chats`
Object (not created in test; see `emptyData()` and the functions that write to it).

## `S.base`
Object (not created in test; see `emptyData()` and the functions that write to it).

Keys seen: `orders`, `subs`, `gmv`, `partners`

## `S.seq`
Single value (number).

## `S.guest`
Object (not created in test; see `emptyData()` and the functions that write to it).

Keys seen: `id`, `name`, `phone`, `email`, `notify`, `vegOnly`, `tierOverride`, `favs`, `kfavs`, `addresses`, `pay`, `prefsMenu`

## `S.auth`
Map keyed by id:

| field | type |
|---|---|
| `id` | string |
| `phone` | string |
| `name` | string |
| `email` | string |
| `roles` | array |
| `kid` | string |

## `S.cust`
Object (not created in test; see `emptyData()` and the functions that write to it).

Keys seen: `id`, `name`, `phone`, `email`, `notify`, `vegOnly`, `tierOverride`, `favs`, `kfavs`, `addresses`, `pay`, `prefsMenu`

## `S.wk`
Map keyed by id:

| field | type |
|---|---|
| `start` | number |
| `days` | array |

## `S.picks`
Map keyed by id:

| field | type |
|---|---|
| `roti` | number |
| `rice` | number |
| `dal` | number |
| `choice` | string |

## Fixed tables in code (not data)

- `TIERS` (Basic 110/70, Pro 130/85, Gold 150/95, Platinum 200/…): name, tagline, full/half price, feature points.
- `RULES`: 7-day plan = 1 skip, 0 pauses, 0 changes. 30-day plan = 4 skips, 2 pauses, 4 changes.
- `STATUS` / `SLABEL` / `ACT`: order steps confirmed, accepted, preparing, ready, assigned, picked, out, delivered, and which role may move each step.
- `SLOTS`: six delivery windows.
- `CAT`: the dish catalogue (name, category, veg flag, emoji, hue, base price).
- `DOC_DEFS`: documents asked from kitchen and delivery partners (all optional unless the admin makes them mandatory).
