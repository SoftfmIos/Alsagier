# Build 29 — Intelligent Day Recovery (initial implementation)
- Adds a non-mutating, contextual recovery suggestion on Today when remaining work exceeds remaining capacity.
- Preview lists task names and minutes; only explicit Approve removes future task blocks from today. Tasks stay unfinished and are eligible tomorrow.
- Day-scoped approved move IDs prevent ordinary refresh from rescheduling moved tasks on the same day.
- Revalidates proposal at approval time. Protects prayer, calendar, active/completed work, frozen/closed projects and Work End.
- Shows amber 15-minute finishing grace for an existing final block crossing Work End; does not create new overtime blocks.
- Does NOT yet include recovery undo, smart re-optimization, notification-driven disruption detection, or explicit overtime placement. These need a later iteration and device testing.
- Source syntax parsed on Linux; full iOS compilation and TestFlight verification required.
