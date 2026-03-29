# Regatta Scoring & Race Committee Tool

A modern, offline-first iOS/iPadOS app designed specifically for Race Committees. 
The guiding philosophy of this app is simple: **Let the iPad do the math so the RC can watch the boats.**

## Architecture & Monetization Pivot (The "B2B SaaS" Model)

This project operates on a bottom-up SaaS model, targeting yacht clubs and volunteer Race Committees:

*   **Free Tier (The Hook):** The core iOS/iPadOS app is 100% free to download and use. A Principal Race Officer (PRO) or volunteer can add boats, score races, calculate throwouts, and view the final standings directly on the iPad screen. All scoring math runs locally on the device instantly using SwiftData, requiring absolutely **zero cellular connection** out on the water.
*   **Pro Tier (The Club Subscription):** When the RC boat returns to the dock and connects to Wi-Fi, the paywall kicks in for official distribution. A paid club subscription ($10/mo or $99/yr) unlocks:
    1.  **Live Broadcast Mode:** Syncs the local database to the cloud (Supabase/Node.js backend), pushing live standings to a custom web link (e.g., `regattascore.com/halifax-yacht-club`) for competitors to view at the bar.
    2.  **Official Export:** Unlocks one-tap PDF generation (to print and pin to the clubhouse bulletin board) and CSV export.

## How It Works: The Scoring Engine (RRS Appendix A)

This app automatically enforces the World Sailing Racing Rules of Sailing (RRS) — specifically Appendix A (Low Point System). If you see a discrepancy between your manual calculations and the app's results, refer to the logic below:

### 1. The Low Point System & Penalties (Rule A5.2)
When an RC officer toggles a penalty (`DNC`, `DNS`, `DNF`, `RET`, `DSQ`) for a boat, the scoring engine dynamically calculates the score as: **Total Fleet Size + 1**. 
*Note: Because this is dynamic, if a new boat registers late and increases the fleet size, all previous DNF/DNC scores will automatically recalculate to reflect the new `Fleet Size + 1`.*

### 2. Automated Discards / Throwouts (Rule A2.1)
Each boat's series score is the total of her race scores excluding her worst score(s).
When setting up a Regatta, the RC defines the number of "Throwouts". Every time a new race finish is entered, the app recalculates the entire series, sorts every boat's scores, and automatically subtracts the worst *X* scores to calculate the Net Score.

### 3. Series Ties (Rule A8) - *[Currently In Development]*
When two boats have the same Net Score, the app will break the tie based on Rule A8.1 (most 1st places, then 2nd places, etc.). If still tied, it will fall back to Rule A8.2 (whoever beat who in the last race).
