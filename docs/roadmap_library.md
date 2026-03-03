# LipidLog Roadmap Library (Imported 2026-03-03)

Source: `lipidlog app.pdf` in project root.

## MVP Target (Tier 1)
1. Onboarding with focus mode (LDL / TG / Both), demographics, optional targets, medication status.
2. Manual lab entry with date + fasting (photo import placeholder acceptable for MVP).
3. Cholesterol Score engine (0-100): Lab 50 + Behavior 30 + Trend 20.
4. Goal Score and distance-to-go.
5. Daily behavior tracker with medication adherence.
6. Trends dashboard (score + LDL/TG trend visibility + simple habit/lab insights).
7. Weekly summary card.
8. Minimal food guidance with search/swaps guidance.
9. Settings: focus mode/targets/reminders/export.

## Current Delivery Snapshot (as of 2026-03-03)
- Implemented strongly:
  - Onboarding/profile/targets/medication capture.
  - Lab entry (manual), fasting, save/recompute score.
  - Score engine with weighted lab/habit/trend + goal score.
  - Daily habit logging with medication-aware scoring.
  - Patterns screen with score trend + weekly stats + templated insights.
  - Food guidance with searchable category lists.
  - Settings for profile/focus/targets/reminders and data reset.
  - Local notification scheduling for daily habit, medication, and lab-check reminders.
  - Data export as JSON/CSV (copy-to-clipboard workflow).
- Partially implemented:
  - Labs screen has LDL/TG trend chart and photo-import placeholder CTA.
  - Weekly summary exists but only partially surfaced on Home.
- Not implemented yet (MVP gaps):
  - OCR import flow (only placeholder).
  - Dedicated chart views for LDL/TG/Score in a single focused dashboard experience.

## Priority Next Steps (Immediate Impact)
1. Improve trends UX: explicit LDL/TG/Score tabs and clearer correlation statements.
2. Add OCR entry lane scaffold (camera picker + parse placeholder state machine).
3. Upgrade home weekly summary to show actionable "best/worst habits" and trend trajectory.
4. Add reminder management polish (next-trigger preview and per-reminder enable states in onboarding).

## Notes
- The roadmap in the PDF includes post-launch items (Apple Health, OCR full extraction, advanced AI insights, monetization hooks). These are intentionally deferred after MVP completeness.
