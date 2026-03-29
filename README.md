# Regatta Scoring & Race Committee Tool

A modern, offline-first iOS/iPadOS app designed specifically for Race Committees. 
The guiding philosophy of this app is simple: **Let the iPad do the math so the RC can watch the boats.**

## How It Works: The Scoring Engine (RRS Appendix A)

This app automatically enforces the World Sailing Racing Rules of Sailing (RRS) — specifically Appendix A (Low Point System). If you see a discrepancy between your manual calculations and the app's results, refer to the logic below to understand how the app arrives at its conclusions.

### 1. The Low Point System & Penalties (Rule A5.2)
The app automatically handles fleet-size math for non-finishers so the RC doesn't have to calculate it in their heads. 
When an RC officer toggles a penalty (`DNC`, `DNS`, `DNF`, `RET`, `DSQ`) for a boat, the scoring engine dynamically calculates the score as: **Total Fleet Size + 1**. 
*Note: Because this is dynamic, if a new boat registers late and is added to the regatta, increasing the fleet size, all previous DNF/DNC scores will automatically recalculate to reflect the new `Fleet Size + 1`.*

### 2. Automated Discards / Throwouts (Rule A2.1)
Each boat's series score is the total of her race scores excluding her worst score(s).
When setting up a Regatta, the RC defines the number of "Throwouts". Every time a new race finish is entered, the app recalculates the entire series, sorts every boat's scores, and automatically subtracts the worst *X* scores to calculate the Net Score. The RC never has to manually cross off a bad race.

### 3. Series Ties (Rule A8) - *[Currently In Development]*
*(Note: Tie-breaking logic is actively being implemented in the engine)*
When two boats have the same Net Score, the app will break the tie based on Rule A8.1 (who has the most 1st places, then 2nd places, etc.). If they are still tied, it will fall back to Rule A8.2 (whoever beat who in the last race).

## Architecture & Design
* **Offline-First (SwiftData):** Out on the water, cellular service is notoriously unreliable. All scoring math runs locally on the device instantly. Cloud synchronization (for competitors to view live results at the yacht club bar) happens in the background when an internet connection is restored.
* **Native iOS/iPadOS:** Designed with high-contrast, large tap targets, and responsive `NavigationSplitView` layouts to work flawlessly on a wet iPad screen under heavy glare.
