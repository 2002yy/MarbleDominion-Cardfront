# P0-05B4 Save Compatibility Cleanup

Audited source commit: `b75192484c2543d46a8390918c84a3798f176ace`
Branch: `audit/p0-04e-auto-spawn`
Target step: **P0-05B4 — Save Compatibility Cleanup**
Decision: **GO / NO CURRENT RUNTIME SCHEMA MIGRATION REQUIRED**

## Goal

Prevent retired Stronghold numeric rewards from re-entering authority through save/restore compatibility while keeping this checkpoint scoped to the runtime that actually exists.

## Repository reality audit

The P0 planning contract describes a future `CardfrontRuntimeSnapshot` boundary with `supports`, territory claims, pending volley and pending choice data. The current branch does **not** yet contain an implemented `CardfrontRuntimeSnapshot` / Cardfront save-restore pipeline matching that planned schema.

Searches for the planned runtime snapshot surface and its expected fields did not locate an implemented persistence class or restore path. Therefore this checkpoint does not invent a new save framework merely to satisfy a planning placeholder.

## Compatibility rule frozen here

When Cardfront persistence is implemented later:

- missing new fields may receive neutral defaults;
- historical Stronghold reward values must **not** be mapped into Support ownership, Support operational state, Support connectivity, Draft size, attack level, or volley count;
- derived Support connectivity must be recomputed from authoritative topology + ownership/claim + operational state;
- derived deployment legality must be recomputed from current authoritative state;
- runtime numeric IDs must not become persistent identity authority.

Explicit forbidden migration:

```text
old stronghold bonus snapshot
  -> Support state
  -> connectivity / deployment / combat authority
```

## Runtime cleanup bound to this checkpoint

`CardfrontRoundDirector` now:

- stores `current_stronghold_status`, not `current_stronghold_bonuses`;
- exposes `get_stronghold_status()`;
- samples through `sample_status()`;
- fixes formal Draft offer size to the three-choice contract instead of deriving it from Stronghold data;
- does not feed Stronghold reward values into AI live valuation;
- does not pass volley plans through a Stronghold reward mutation seam.

This removes the live names and paths most likely to be mistaken for future persistence authority.

## Regression / evidence

- Current Cardfront persistence implementation matching the planned runtime snapshot: **not present**.
- Save schema changed by this checkpoint: **NO**.
- Old Stronghold reward -> Support migration introduced: **NO**.
- Derived Support connectivity persisted as authority: **NO**.
- Production runtime still exposes status-only Stronghold observation: **YES**.

## Mandatory audit fields

```text
Stable IDs introduced/changed? NO
Runtime numeric IDs used as persistent identity? NO new use
Territory capture touched? NO
Creature movement legality touched? NO
Deployment four-consumer authority touched? NO
Derived Support connectivity persisted as authority? NO
Legacy Stronghold reward restore path found? NO
Save compatibility impact? NONE in current runtime; future rule frozen above
P1/P2 leakage? NONE
```

## Non-goals

- creating a new save manager;
- defining a complete persistence schema ahead of its implementation checkpoint;
- serializing connectivity caches;
- converting historical Stronghold numeric values into Support semantics.

## Exit gate

**PASS.** There is no current Cardfront persistence path capable of restoring retired Stronghold reward authority, and the live runtime naming/consumer paths have been cut so a future save implementation has a clear authority boundary.

Only allowed next step: **P0-05B5 — Global Legacy Search Gate**.
