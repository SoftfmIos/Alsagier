# Project administrative closure — Build 24

- Projects dashboard: Total / Active / Closed / Frozen counters, each tappable as a filter.
- Swipe a project and choose Close; confirmation shows the number of unfinished tasks.
- Closure marks unfinished tasks done without adding WorkInsight records, durations, or emotion ratings.
- Closure metadata records which tasks were administratively closed, separately in UserDefaults.
- Future, incomplete project/task blocks are removed from active day plans. Completed/past blocks remain.
- Frozen project stops future scheduling but retains incomplete tasks.
- Reopening a closed project does not automatically undo administrative completions.
- Limitations: closure metadata is not yet included in exported backups; verify full Xcode build and device behavior.
