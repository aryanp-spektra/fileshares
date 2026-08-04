# Q2C AI Agent (Track 1 – Microsoft 365) — End-to-End Test Instructions

**Purpose:** a single run-through script to build and validate the entire lab yourself, start to finish, before it ships to Microsoft. Follow it in order — Challenges 3→6 depend on state built in earlier ones. Check off each `[ ]` as you go, and log anything that breaks under **Issues Found** at the bottom rather than quietly working around it — the point is to catch what a cold participant would hit.

**Supporting files for this run-through:**
- `Q2C-Lab-Source-Data.xlsx` (or the two standalone CSVs) — source data for both SharePoint lists, used in Section 2 below

**Estimated total time:** ~4 hours if you hit no blockers (220 min of challenge content + setup/sign-in overhead). Budget more on your first pass since you're also hunting for content issues, not just executing.

---

## 0. Pre-Flight Environment Checklist

Confirm these before touching Challenge 1. If any fail, everything downstream fails silently or confusingly.

- [ ] Sandbox VM provisions cleanly; lab guide and Environment tab both load
- [ ] M365 sign-in with `AzureAdUserEmail` + Temporary Access Pass works first try (test the "Stay signed in? No" branch too)
- [ ] Power Platform admin center shows the ODL environment already provisioned (not the default environment)
- [ ] Confirm whether the S2S app user step is actually needed on a fresh sandbox, or whether it's already configured — the doc currently treats `sandboxailabs1001.onmicrosoft.com/cloudlabs.ai` / `cloudlabssandbox.onmicrosoft.com/cloudlabs.ai/` as conditionally present. If it's inconsistent across sandboxes, flag it.
- [ ] Copilot Studio license active, `https://copilotstudio.microsoft.com` loads, ODL environment selectable
- [x] **AI Builder / "Create text with GPT using a prompt" credits** — confirmed covered by the Copilot Studio + base Office 365 license every participant gets. Run one throwaway flow with just this action to smoke-test it resolves in practice, but this is no longer an open risk.
- [ ] Confirm `Q2C-Lab-Source-Data.xlsx` (or the CSVs) is present in the VM image for participants to use in Section 2
- [ ] Confirm you have Teams access — Challenge 4/5 alerts now post as 1:1 DMs to the salesperson rather than to a shared channel, so no channel needs to be pre-created
- [ ] Confirm you're ready to self-send test emails to your own monitored inbox (not from an external account) — this is the confirmed test methodology and it changes a required condition in Challenge 4 (see Section 4)

---

## 1. Getting Started — Sign-In, Environment Activation, Site Creation

### 1.1 Sign in to Microsoft 365
- [ ] Open Edge on the JumpVM, go to `https://www.office.com`
- [ ] Sign in with the provided email, enter the Temporary Access Pass, decline "Stay signed in?"

### 1.2 Activate the Power Platform environment
- [ ] Go to `https://admin.powerplatform.microsoft.com`, select **Manage > Environments > ODL_User [DeploymentID]'s Environment**
- [ ] Under **S2S apps > See all**, check if the required app is already listed; if not, add it via **+ New app user** per the doc's steps, assign **System Administrator** under Security roles
- [ ] Note: environment provisioning can take up to 15 minutes — a portal error here is expected/normal, retry after a moment

### 1.3 Create the Contoso Q2C Site
*(This replaces the old "pre-provisioned site" assumption — participants build this themselves now.)*

- [ ] From the M365 portal, open **SharePoint**, click **+ Create site > Team site**
- [ ] Name it exactly: `Contoso Q2C Site`
- [ ] Click **Finish**, wait for provisioning
- [ ] Copy the site URL from the address bar into Notepad — you'll need the exact address for Power Automate connections in later challenges

### 1.4 Confirm Copilot Studio access
- [ ] Go to `https://copilotstudio.microsoft.com`, confirm the top-right environment selector shows your ODL environment (not the default one)

**Time check:** this whole section should take under 10 minutes. If site provisioning or environment activation drags past 15 minutes, note it as a lab-day risk — participants sitting idle during a 6-hour event waiting on Azure/M365 backend provisioning is a real facilitation problem.

---

## 2. Challenge 01 — Business Context and SharePoint Data Foundation

**Time budget to test against:** 30 min (now includes site/list creation via CSV import — this method is faster than manual creation, so confirm the 30-minute budget has slack rather than being consumed entirely)

### 2.1 Map the Q2C process (5 min)
- [ ] Write down the 5 manual steps a Contoso salesperson performs today, email-to-payment. **Keep this — you need it again in Challenge 6, Step 8.**

### 2.2 Create the Product Catalog list via CSV import (2 min)

*(Confirmed working method — SharePoint's native "Import from CSV" creates the list and populates all rows in one step, no manual data entry needed.)*

- [ ] On the Contoso Q2C Site, **New > List > From CSV** (may also show as **Import Spreadsheet** depending on your tenant's UI version)
- [ ] Upload `Product-Catalog-Data.csv`, confirm the first row is treated as headers, name the list `Product Catalog`
- [ ] Let it import — all 15 rows should populate automatically

**Fix up column types after import (do not skip this):**
- [ ] Check **UnitPrice** — CSV import commonly infers this as plain **Number**, not **Currency**. Edit the column, change type to Currency if needed.
- [ ] Check **GSTPercent** — should come in as Number correctly; confirm no decimal formatting issues.
- [ ] Check **SKU** and **ProductName** — should both import as Single line of text; confirm neither was misread as Number (SKU values like "CS-001" usually import correctly as text, but worth a glance).

### 2.3 Create the Invoice Tracker list via CSV import (3 min)

- [ ] **New > List > From CSV**, upload `Invoice-Tracker-Data.csv`, name the list `Invoice Tracker`
- [ ] Let it import — all 15 rows should populate

**Fix up column types after import (critical — CSV import will not create a Choice column on its own):**
- [ ] Check **Amount** — likely imports as plain Number; change to Currency if needed
- [ ] Check **DueDate** — should auto-detect as a date column; confirm the format is **Date Only**, not Date and Time
- [ ] **Status will import as plain Single line of text, not Choice.** Edit the Status column, change its type to **Choice**, and add exactly these three options: `Open`, `Resolved`, `Paid`. Since the imported text values already match these exactly, they'll map cleanly to the new choice options — you shouldn't need to re-enter any data.
- [ ] Confirm CustomerName and InvoiceNumber imported as Single line of text

**Checkpoint:** open List settings > Columns on both lists and confirm every type matches the spec before moving on — this is the one step in the CSV-import method that's easy to skip and will bite you later (e.g. a Number instead of Currency won't break Challenge 3's math, but a Status column that's still plain text instead of Choice fails Challenge 1's success criteria and is worth fixing for correctness even though the Power Automate filters would technically still work against plain text).

### 2.4 Data reference (already loaded via the CSV import above — no manual entry needed)

Product Catalog now has **15 rows**:

| SKU | ProductName | UnitPrice | GSTPercent |
|---|---|---|---|
| CS-001 | Office Chair Pro | 299.00 | 10 |
| CS-002 | Adjustable Standing Desk | 649.00 | 10 |
| CS-003 | Laptop Stand | 89.00 | 10 |
| CS-004 | Wireless Keyboard | 119.00 | 10 |
| CS-005 | 27-inch Monitor | 489.00 | 10 |
| CS-006 | Wireless Mouse | 49.00 | 10 |
| CS-007 | LED Desk Lamp | 39.00 | 10 |
| CS-008 | Under-Desk Cable Tray | 29.00 | 10 |
| CS-009 | Ergonomic Footrest | 59.00 | 10 |
| CS-010 | Monitor Arm Mount | 79.00 | 10 |
| CS-011 | Noise-Cancelling Headset | 199.00 | 10 |
| CS-012 | HD Webcam 1080p | 69.00 | 10 |
| CS-013 | Whiteboard 4x3 ft | 149.00 | 10 |
| CS-014 | 3-Drawer Filing Cabinet | 229.00 | 10 |
| CS-015 | Conference Room Speakerphone | 349.00 | 10 |

Invoice Tracker now has **15 rows**, deliberately mixed so Challenge 5's overdue-filter logic actually gets exercised rather than trivially passing:

| CustomerName | InvoiceNumber | Amount | DueDate | Status | Why it's in the mix |
|---|---|---|---|---|---|
| Acme Corp | INV-2025-001 | 2450.00 | 2025-06-01 | Open | Overdue — should alert |
| BlueSky Ltd | INV-2025-002 | 890.00 | 2025-06-15 | Open | Overdue — should alert |
| NovaTech Inc | INV-2025-003 | 3200.00 | 2025-07-01 | Open | Overdue — should alert |
| Harborview Logistics | INV-2025-004 | 1275.50 | 2025-08-10 | Open | Overdue — should alert |
| Meridian Retail Group | INV-2025-005 | 4100.00 | 2025-09-05 | Open | Overdue — should alert |
| Crestline Manufacturing | INV-2025-006 | 675.25 | 2025-10-20 | Open | Overdue — should alert |
| Pinecrest Consulting | INV-2025-007 | 2980.00 | 2025-11-30 | Open | Overdue — should alert |
| Suncoast Media | INV-2025-008 | 1520.00 | 2026-01-15 | Open | Overdue — should alert |
| Oakridge Partners | INV-2026-009 | 990.00 | 2026-12-01 | Open | **Not yet due** — must NOT alert |
| Westfield Traders | INV-2026-010 | 3350.00 | 2027-01-15 | Open | **Not yet due** — must NOT alert |
| Vantage Solutions | INV-2025-011 | 1800.00 | 2025-05-01 | Resolved | Already handled — must NOT alert |
| Brightwave Tech | INV-2025-012 | 2200.00 | 2025-06-10 | Resolved | Already handled — must NOT alert |
| Lakeshore Supplies | INV-2025-013 | 675.00 | 2025-07-22 | Paid | Already paid — must NOT alert |
| Ironforge Industries | INV-2025-014 | 5400.00 | 2025-08-01 | Paid | Already paid — must NOT alert |
| Coastal Devices Inc | INV-2025-015 | 1125.75 | 2025-09-15 | Paid | Already paid — must NOT alert |

**This changes Challenge 5's validation meaningfully:** with only 3 all-overdue-all-Open rows in the original dataset, a broken filter (e.g. one that ignores Status entirely, or ignores the date comparison entirely) would still happen to produce the "right" result by accident. With this 15-row mix, a broken filter will visibly over-fire (alerting on future-dated or already-Resolved/Paid invoices) or under-fire — so use this as your real correctness test for Challenge 5's Get Items + Filter Array logic, not just the original 3-row set.

### 2.5 Verify (2 min)
- [ ] Product Catalog: exactly 15 rows, UnitPrice showing currency formatting after your type fix-up
- [ ] Invoice Tracker: exactly 15 rows, DueDate showing as plain date, Status showing as a proper Choice field (not plain text) with the correct value on every row
- [ ] Run a manual filter on Product Catalog (e.g. ProductName contains "Chair") and confirm the correct row returns — this is your smoke test for the Challenge 3 OData filter
- [ ] Note the internal column name for ProductName and GSTPercent (edit the column, check the URL) — needed verbatim for Challenge 3's filter expressions

**VALIDATE:** the Invoice Tracker dataset now includes both overdue AND not-yet-due Open records, plus Resolved/Paid ones. Confirm your Challenge 5 filter logic (once built) correctly identifies only the 8 genuinely overdue rows — not all 10 Open rows, and not all 15 rows. This is a real correctness test, not just a data-loaded check.

**If something goes wrong:**
- Currency symbol missing after import → column imported as Number, not Currency; fix the type (expected — do this for both UnitPrice and Amount)
- Status shows as free text with no dropdown → you skipped converting it to a Choice column post-import; this is expected behavior from CSV import, not a bug, and needs the manual fix in 2.3
- DueDate shows a timestamp → format wasn't set to Date Only; fix the column format, existing values should re-render correctly
- Row count doesn't match (14 or 16 instead of 15) → check whether the header row got imported as a data row, or whether a blank trailing row exists in the CSV

---

## 3. Challenge 02 — Copilot Studio Agent Foundation

**Time budget to test against:** 40 min — this now includes building a small Agent Flow (Section 3.4) for the dynamic product list, which is real added time versus the original design. Time this section specifically and flag if 40 minutes no longer covers it.

### 3.1 Create the agent
- [ ] Go to `https://copilotstudio.microsoft.com`, confirm the environment selector (top right) shows your ODL environment
- [ ] Click **+ Create** (left nav) or **New agent**
- [ ] You'll be offered "Describe" (AI-scaffolded) vs a blank/skip option — **choose to skip AI generation and create a blank/empty agent.** The exact button label varies by tenant version (may read "Skip to configure", "Create blank agent", or a small "Skip" link near the description box) — look for whichever path does NOT ask you to describe the bot in a paragraph first.
- [ ] Set **Name**: `Contoso Q2C Assistant`
- [ ] Set **Description** (paste exactly):
```
Handles inbound sales quote requests for Contoso Supplies Ltd, retrieves live pricing from SharePoint, and supports the quote-to-cash workflow.
```
- [ ] Click **Create**

### 3.2 Write the system instructions
- [ ] Open the agent, go to **Settings** (or the agent's overview page) → find the **Instructions** field
- [ ] Paste exactly:
```
You are the Contoso Q2C Assistant, representing Contoso Supplies Ltd's sales team.

Your job is strictly limited to handling inbound quote requests. You do not answer general knowledge questions, provide customer support, discuss unrelated topics, or engage in small talk beyond a brief acknowledgment. If a request falls outside quoting products for Contoso Supplies Ltd, politely redirect the person to contact support instead.

Before drafting or referencing any pricing information, you must retrieve live data from the SharePoint Product Catalog. Never estimate, guess, or recall pricing from memory - always look it up.

Every quote you produce must include: product SKU, unit price, quantity, line total, GST at 18%, and a final total amount (line total plus GST). Prices are in Indian Rupees (₹).

Maintain a professional, concise tone appropriate for B2B sales correspondence at all times. Do not use casual language, emojis, or overly enthusiastic phrasing.
```
- [ ] Click **Save**

### 3.3 Disable irrelevant system topics
- [ ] Go to **Topics** → **System** (tab/filter for system topics)
- [ ] Your tenant's exact topic list may vary slightly, but disable any topic that lets the agent answer general/off-topic questions or handle things irrelevant to a scoped B2B quoting agent — commonly: **Conversational boosting** (general knowledge/web-answer fallback), **Sign in** (not needed, no external auth in this lab), and **Start over** (optional, disable if present and not essential). Click into each, use the **enable/disable toggle** (not delete).
- [ ] **Keep enabled:** Fallback, Escalate, Goodbye — these three must stay on
- [ ] Confirm at least 3 topics are now disabled

### 3.4 Build the "Get Product Names" flow (dynamic option list — do this before creating the topic)

This flow fetches the live product list from SharePoint so the question's options are never manually typed or maintained — no copy-pasting 15 names, and it stays correct automatically if the catalog changes later.

- [ ] In Copilot Studio → **Contoso Q2C Assistant** → **Flows** → **+ Add a flow** → **Build from scratch**
- [ ] Trigger: **Run a flow from Copilot** (no inputs needed — this flow takes none)
- [ ] Name it `Q2C - Get Product Names`
- [ ] Add step: SharePoint **Get items** → Site: your Contoso Q2C Site, List: `Product Catalog` — leave **Filter Query** blank so it returns all 15 rows
- [ ] Add step: search `Select` (Data Operation connector), add the **Select** action
  - **From**: `body('Get_items')?['value']`
  - Switch the map to enter a value manually, set it to: `item()?['ProductName']` (use your exact internal column name if it differs from Challenge 1)
- [ ] Add step: **Respond to Copilot Studio** → **+ Add an output** → Name: `ProductNames`, Type: **Table** (may show as "List" depending on your version) → Value: the output of the Select step
- [ ] **Save and Publish this flow** — it won't be selectable from the topic in the next section until it's published
- [ ] *(If your Agent Flows designer doesn't expose the Select action or Table output type yet, build this same flow in classic Power Automate instead — same trigger, same logic, it'll still appear in Copilot Studio's "Call an action" picker.)*

**Note for the shipped lab:** this adds a small flow-building step inside what was originally scoped as Challenge 2 (a Copilot Studio-only challenge), slightly overlapping with Challenge 3's own flow-building content. Worth deciding whether to keep it here, or move this specific flow into Challenge 3 and have Challenge 2 reference it — either works, but the challenge docs should be explicit about which challenge owns this step so participants aren't confused about where it belongs.

### 3.5 Create the Quote Request topic
- [ ] Go to **Topics** → click **+ Add a topic** → **From blank**
- [ ] Name it exactly: `Quote Request`
- [ ] **Important — Copilot Studio's current default:** a freshly created agent uses **Generative AI orchestration**, not Classic. Under this mode, the topic's trigger node reads **"The agent chooses"** instead of "User says a phrase," and there's no trigger-phrases panel at all — you write a **Description** instead, which the AI uses semantically to decide when to fire the topic. If your topic *does* show a trigger-phrases panel, your agent is on Classic orchestration instead (check Settings → Generative AI → Orchestration) — in that case skip to the Classic-mode alternative below.
- [ ] Click the trigger node at the top of the canvas, find the **Description** field, and paste:
```
This topic handles inbound requests where someone is asking for pricing, a cost estimate, or a formal quote on one or more products - for example, asking how much something costs, requesting a quotation, asking to be sent pricing, or asking what a bulk order would run them. Trigger this topic whenever the user is asking about product pricing or requesting a quote, rather than asking something unrelated to cost (like support, returns, or general questions).
```
- [ ] Save

**If your agent is on Classic orchestration instead** (trigger-phrases panel is visible): click **+ Add trigger phrase** and add all 10 of these (paste one at a time):
```
I need a quote for
Can you send me pricing for
How much does this cost
I'd like to get a quotation for
Could you quote me for
What's the price of
I want to request pricing on
Please provide a quote for
Can I get costs for
Need pricing info for
```

- [ ] In the topic canvas, click **+** below the trigger node → **Add a node** → **Message**. Set the message text to:
```
Thanks for reaching out to Contoso Supplies Ltd! I'm pulling up live pricing from our catalog now - one moment.
```

**Why two separate questions, not one:** a single free-text answer like "Office Chair Pro, 3" can't be reliably split back into a product name and a quantity downstream — there's no clean way to know where the name ends and the number begins. Asking two questions instead solves this cleanly, and using the **Number** entity type for quantity gets you free input validation (non-numeric answers get auto-rejected and re-prompted) instead of having to parse and validate it yourself.

- [ ] Click **+** after the message node → **Add an action** → **Call an action** → select the `Q2C - Get Product Names` flow you built in Section 3.4 (no inputs to map, since it takes none)
- [ ] Rename its output variable to `ProductList` (this should come through as a Table type, matching the Select action's output from that flow)
- [ ] Click **+** → **Ask a question**. Set the question text to:
```
Which product would you like a quote for?
```
- [ ] Under **Identify**, choose **Options from a list variable** (not "Multiple choice options" — this is what binds the buttons to your live flow output instead of a manually typed list). Select `ProductList` as the source.
- [ ] This renders as clickable buttons generated fresh from SharePoint every time the topic runs — no manual typing, and it solves the exact-match problem the same way a static list would, since a button click can't produce a typo or paraphrase. If the catalog changes later (a product added/removed/renamed), the options update automatically the next time this runs — nothing to maintain.
- [ ] Save the response into a variable named `ProductName`

**Check the variable's type before mapping it downstream:** open the Variables panel and look at `ProductName`'s type. If it shows as plain **Text**, you can map it straight into the Challenge 3 flow's `ProductKeyword` input with no extra step. If it shows as a choice/option-set type instead (this can happen depending on how "Options from a list variable" is implemented in your tenant version), apply the same fix as a static Multiple Choice list would need: add a **Set a variable** step using a Power Fx formula, e.g. set a new Text variable `ProductNameText` to `Text(ProductName)`, and map that converted variable into the flow instead of the raw one. Don't assume either way — check it live, since getting this wrong surfaces as a cryptic "Input variable is of incorrect type" error later in Challenge 3's action call, not here.

**Note for the shipped lab:** using a dynamic, SharePoint-bound options list means Challenge 2 now depends on a small flow being built first — worth deciding whether challenge-2.md should own this flow-building step directly, or whether it's cleaner to have participants build `Q2C - Get Product Names` as an early part of Challenge 3 instead and just reference it from Challenge 2. Either works technically; the docs should be explicit about which challenge owns it so participants aren't confused about where this step belongs.

- [ ] Click **+** → **Ask a question** again. Set the question text to:
```
And how many units would you like?
```
- [ ] Under this question's response settings, change the entity type to **Number** (not "User's entire response") — this is what guarantees the value is a valid number before it ever reaches your flow. Save into a new variable named `Quantity` (Number)
- [ ] Click **Save**


### 3.6 Test in the canvas
- [ ] Open the **Test your agent** / **Test bot** panel (usually a chat icon top-right)
- [ ] Send these 5 messages one at a time and confirm the Quote Request topic fires for all of them (on Generative orchestration, the AI is matching against your Description's meaning, not exact phrases — so these deliberately include wording that doesn't literally appear in the description, to test real semantic matching, not just keyword overlap):
```
I need a quote for office chairs
Can you send me pricing for a standing desk
What would 5 monitors cost me?
Do you have a price list I could look at?
I'm trying to figure out what a bulk order would run me
```
- [ ] Then send these 2 and confirm the topic does **NOT** fire:
```
What is your return policy?
I need IT support with my laptop
```
- [ ] If any of the first 5 miss: on Generative orchestration, revise the Description to more clearly cover that scenario (rather than adding a "trigger phrase," since there isn't one) and retest. On Classic orchestration, add the missed phrasing to your trigger phrase list. Either way, don't move on with a known gap — Challenge 4's email trigger accuracy depends on this topic being reliable.

---

## 4. Challenge 03 — SharePoint Pricing Action with an Agent Flow

**Time budget to test against:** 35 min

**Build location — build this natively inside Copilot Studio, not the Power Automate portal.** Copilot Studio now has **Agent Flows**: built, edited, and run directly in the Copilot Studio designer, consuming Copilot Studio capacity rather than a separate Power Automate license. Agent flows that use the "Run a flow from Copilot" trigger are exactly the pattern this challenge needs, and they can be added as callable tools directly on a topic — no separate portal, no separate licensing model to explain to participants. This also means challenge-3.md's instructions to "open Power Automate" are outdated and should be revised before shipping.

### 4.1 Create the agent flow and trigger
- [ ] In Copilot Studio, open **Contoso Q2C Assistant** → left nav → **Flows** (or **Agent flows**, naming may vary slightly by tenant version)
- [ ] Click **+ Add a flow** / **New flow** → **Build from scratch** (or ask Copilot to draft it via natural language — either path lands in the same designer)
- [ ] Choose the trigger **Run a flow from Copilot** (may also read "When an agent calls the flow")
- [ ] Name the flow `Q2C - Pricing Lookup`
- [ ] On the trigger card, add input **ProductKeyword** (Text) and **Quantity** (Number)

*(If your tenant's Agent Flows designer doesn't yet expose the SharePoint "Get items" action or the expression editor you need, fall back to building this in classic Power Automate at `https://make.powerautomate.com` using the same trigger type — the flow will still surface correctly in Copilot Studio's "Call an action" picker either way, since both are Copilot-Studio-callable flows under the hood.)*

### 4.2 Get the product
- [ ] Click **+ New step**, search `SharePoint`, choose **Get items**
- [ ] **Site Address**: select your Contoso Q2C Site from the dropdown (or paste the URL you saved earlier)
- [ ] **List Name**: `Product Catalog`
- [ ] Click **Show advanced options** → in **Filter Query**, paste:
```
substringof(triggerBody()?['ProductKeyword'], ProductName)
```
*(If your internal column name for ProductName came through differently during Challenge 1's data load, e.g. `ProductName0`, use that exact internal name here instead.)*

**On exact matching:** `substringof()` requires the value passed in to literally appear as a substring inside `ProductName` — it doesn't do fuzzy or synonym matching. SharePoint's OData layer is generally case-insensitive for this comparison (so "office chair" matches "Office Chair Pro"), but confirm this in your own test rather than assuming — test with a deliberately different-case input (e.g. `OFFICE CHAIR`) in 4.5 and see if it still matches. If your tenant's SharePoint list happens to be case-sensitive, you'd need to wrap both sides in `tolower()` — note this as something to check live, not something to pre-emptively code around without confirming it's actually needed.

### 4.3 Handle the match / no-match branch
- [ ] Click **+ New step** → **Condition**
- [ ] Click **Edit in advanced mode**, paste:
```
@greater(length(body('Get_items')?['value']), 0)
```
- [ ] **In the Yes branch**, add a **Compose** action, rename it `LineTotal`, set Inputs to:
```
mul(body('Get_items')?['value'][0]?['UnitPrice'], triggerBody()?['Quantity'])
```
- [ ] Add another **Compose**, rename it `GSTAmount`, set Inputs to:
```
mul(outputs('LineTotal'), div(body('Get_items')?['value'][0]?['GSTPercent'], 100))
```
- [ ] Add a third **Compose**, rename it `Total`, set Inputs to:
```
add(outputs('LineTotal'), outputs('GSTAmount'))
```
- [ ] **In the No branch**, add a **Respond to Copilot Studio** action (see 4.4) with a single text output, e.g. `Message` = `Sorry, we couldn't find a matching product in our catalog. Could you double-check the product name or SKU?`

### 4.4 Respond to Copilot Studio (Yes branch)
- [ ] Add a **Respond to Copilot Studio** action inside the Yes branch
- [ ] Add these outputs, mapping each to the matching dynamic content/expression:

| Output name | Type | Value |
|---|---|---|
| SKU | Text | `body('Get_items')?['value'][0]?['SKU']` |
| ProductName | Text | `body('Get_items')?['value'][0]?['ProductName']` |
| UnitPrice | Number | `body('Get_items')?['value'][0]?['UnitPrice']` |
| Quantity | Number | `triggerBody()?['Quantity']` |
| LineTotal | Number | `outputs('LineTotal')` |
| GSTAmount | Number | `outputs('GSTAmount')` |
| Total | Number | `outputs('Total')` |

- [ ] Save the flow

### 4.5 Manual test — confirm exact numbers
- [ ] Click **Test** (top right) → **Manually** → **Save & Test**
- [ ] Enter `ProductKeyword` = `Office Chair`, `Quantity` = `3`
- [ ] Run and confirm the output: **SKU = CS-001, UnitPrice = 299, LineTotal = 897, GSTAmount = 161.46, Total = 1058.46** (GST is now 18%, matching the confirmed Microsoft reference — not the earlier 10% used in initial drafts)
- [ ] Run again with `ProductKeyword` = `Widget`, `Quantity` = `1` — confirm the No-branch fallback message returns instead of an error

### 4.6 Register the action in Copilot Studio
- [ ] Go back to Copilot Studio → open **Contoso Q2C Assistant** → **Quote Request** topic
- [ ] Click **+** after the second question node → **Add an action** → **Call an action** (or "Call a flow")
- [ ] Select your `Q2C - Pricing Lookup` flow (if it doesn't appear, confirm it's in the same environment and uses the Copilot Studio trigger, then refresh)
- [ ] Map **ProductKeyword** → `ProductName` if it came through as plain Text in Challenge 2's type check, or → `ProductNameText` if you had to add the conversion step (see Challenge 2, Section 3.5) — use whichever one is actually Text type in your build
- [ ] Map **Quantity** → the `Quantity` variable captured in Challenge 2's second question (this now arrives as a real number, already validated by the Number entity type — no fixed/default value needed)

### 4.7 Display the result
- [ ] Add a **Message** node after the action call. Set the message to (using the topic's dynamic content picker to insert each `{}` placeholder from the flow's outputs):
```
Here's your pricing:

**Product:** {ProductName}
**SKU:** {SKU}
**Unit Price:** ₹{UnitPrice}
**Quantity:** {Quantity}
**Line Total:** ₹{LineTotal}
**GST (18%):** ₹{GSTAmount}
**Total:** ₹{Total}
```
- [ ] Save

### 4.8 Test end-to-end in canvas
- [ ] Open Test bot, run a conversation: trigger Quote Request, click the **Office Chair Pro** button when asked, answer the quantity question with `3`, confirm the formatted card shows SKU CS-001 and the numbers from 4.5
- [ ] Also test what happens if you answer the quantity question with something non-numeric like `a few` — confirm the Number entity re-prompts instead of passing bad data through to the flow
- [ ] Repeat with `27-inch Monitor, 2` and confirm correct pricing
- [ ] Repeat with `Gizmo, 1` and confirm the friendly not-found message

---

## 5. Challenge 04 — Outlook Trigger, Confirmation, Multi-Item Pricing, and AI-Drafted Quote Reply

**Time budget to test against:** 45 min originally — this challenge now has real added scope (a confirmation step, multi-item parsing and a pricing loop) versus the original single-product design. Time yourself honestly and expect this may need more than 45 minutes; flag it if so rather than rushing past incomplete testing.

**Build location — try natively in Copilot Studio Agent Flows first, but verify reliability before committing.** Agent Flows support event-based triggers including new-email arrival, and building here keeps everything in one designer, matching the current product experience. However, real-world reports flag that Copilot Studio's Outlook event triggers are still preview-grade in some tenants and can batch or fire non-deterministically. **Recommended approach for your feasibility check:** build it in Agent Flows first, run the live test in 5.9, and if the trigger doesn't fire reliably within a reasonable window, rebuild the same logic as a classic Power Automate cloud flow at `https://make.powerautomate.com` using the identical "When a new email arrives (V3)" trigger — that path is mature and well-tested. Document which path you land on, since it affects how challenge-4.md should be worded for participants.

### 5.1 Create the trigger
- [ ] In Copilot Studio → **Contoso Q2C Assistant** → **Flows** → **+ Add a flow** → trigger: search `Outlook` and select **When a new email arrives** (or the closest equivalent Agent Flow trigger)
- [ ] Name the flow `Q2C - Quote Request Handler`
- [ ] Folder: **Inbox** (default)
- [ ] **Fallback if this trigger isn't reliable or isn't available in Agent Flows in your tenant:** build the same flow at `https://make.powerautomate.com` → **+ Create** → **Automated cloud flow** → search `Office 365 Outlook` → trigger **When a new email arrives (V3)** — every step below works identically regardless of which builder you're in, since the underlying trigger/action fields are the same.

### 5.2 Quote-detection condition (keyword-only — no sender exclusion)
- [ ] Add **Condition** action right after the trigger
- [ ] Click **Edit in advanced mode**, paste:
```
@or(contains(toLower(triggerOutputs()?['body/subject']), 'quote'), contains(toLower(triggerOutputs()?['body/subject']), 'pricing'), contains(toLower(triggerOutputs()?['body/subject']), 'quotation'), contains(toLower(triggerOutputs()?['body/body']), 'quote'), contains(toLower(triggerOutputs()?['body/body']), 'pricing'), contains(toLower(triggerOutputs()?['body/body']), 'quotation'))
```
- [ ] **Do not add a sender-exclusion condition.** (This flow only ever creates a Draft, never auto-sends, so there's no real loop risk — and a sender exclusion would block the confirmed self-send test method.)
- [ ] **False branch:** add a **Terminate** action, set Status = `Succeeded`
- [ ] **True branch:** continue with the steps below

### 5.3 Capture sender details
- [ ] Add **Initialize variable**: name `SenderEmail`, type String, value = dynamic content **From** (email address field from the trigger)
- [ ] Add **Initialize variable**: name `SenderName`, type String, value = expression:
```
@triggerOutputs()?['body/from']
```
*(If your connector exposes a separate display-name field, use that instead for a cleaner name — check the dynamic content picker for a "From Name" field first.)*

### 5.4 NEW — Confirmation card before acting (matches the confirmed reference)
This is new scope: rather than jumping straight from detection to drafting, post a confirmation card to the salesperson and wait for approval first — the same "Post adaptive card and wait for a response" pattern you'll also use in Challenge 5, just targeted at a person instead of a channel.

- [ ] Add **Post adaptive card and wait for a response** (Microsoft Teams connector)
- [ ] **Post as**: Flow bot; **Post in**: **Chat with Flow bot** (1:1, matching the same DM pattern used in Challenge 5's overdue alerts)
- [ ] **Recipient**: the salesperson's own account (same monitored inbox owner, for lab testing purposes)
- [ ] Card JSON (paste into the raw JSON view, inserting dynamic content for the bracketed tokens):
```json
{
  "type": "AdaptiveCard",
  "$schema": "http://adaptivecards.io/schemas/adaptive-card.json",
  "version": "1.4",
  "body": [
    {
      "type": "TextBlock",
      "text": "New quote request detected",
      "weight": "Bolder",
      "size": "Medium"
    },
    {
      "type": "TextBlock",
      "text": "@{variables('SenderName')} has requested a quote. Shall I check pricing and draft a reply?",
      "wrap": true
    }
  ],
  "actions": [
    { "type": "Action.Submit", "title": "Approve", "data": { "action": "approve" } },
    { "type": "Action.Submit", "title": "View Catalog", "data": { "action": "view_catalog" } }
  ]
}
```
- [ ] Add **Condition** after this action, advanced mode:
```
@equals(body('Post_adaptive_card_and_wait_for_a_response')?['data']?['action'], 'approve')
```
- [ ] **No branch:** add a **Terminate** action (Status = Succeeded) — if not approved, stop here rather than drafting anything
- [ ] **Yes branch:** continue with the steps below

### 5.5 Extract line items with AI (multi-item parsing — replaces the old single hardcoded product)
This is the real scope change from the original single-product design: the confirmed reference shows a customer asking for multiple products in one email (e.g. 20 chairs + 5 desks), so the flow needs to pull out a list, not one hardcoded item.

- [ ] Add step: search `AI Builder`, select **Create text with GPT using a prompt**
- [ ] Prompt (insert the email body as dynamic content at `[[EMAIL BODY]]`):
```
Extract every product and quantity mentioned in the email below. Respond with ONLY a JSON array, no other text, in this exact format: [{"product":"<product name as mentioned>","quantity":<number>}]. If no quantity is mentioned for an item, use 1.

Email body:
[[EMAIL BODY]]
```
- [ ] Add **Parse JSON** (Data Operation connector) → **Content**: the AI Builder action's text output → **Schema**: click **Generate from sample** and paste:
```json
[{"product":"Office Chair Pro","quantity":3}]
```
- [ ] Add **Initialize variable**: `Subtotal` (Number), initial value `0`
- [ ] Add **Initialize variable**: `LineItemsSummary` (Array), initial value: empty array `[]`
- [ ] Add **Apply to each** → Output: the Parse JSON action's body

### 5.6 Inside the loop — look up each item and accumulate totals
- [ ] Add **Get items** (SharePoint) → List: `Product Catalog`, Filter Query:
```
substringof(item()?['product'], ProductName)
```
- [ ] Add **Condition**: `@greater(length(body('Get_items')?['value']), 0)`
- [ ] **Yes branch:**
  - Add **Compose** `LineTotal`: `mul(body('Get_items')?['value'][0]?['UnitPrice'], item()?['quantity'])`
  - Add **Set variable**: `Subtotal` = `add(variables('Subtotal'), outputs('LineTotal'))`
  - Add **Append to array variable**: `LineItemsSummary`, value:
```
concat(body('Get_items')?['value'][0]?['ProductName'], ' x ', string(item()?['quantity']), ' @ ₹', string(body('Get_items')?['value'][0]?['UnitPrice']), ' = ₹', string(outputs('LineTotal')))
```
  - **No branch:** Append to array variable `LineItemsSummary`, value: `concat('Could not find a catalog match for: ', item()?['product'])` — so a mismatched item shows up visibly in the quote review rather than silently vanishing

- [ ] **After the loop ends**, add **Compose** `GSTAmount`: `mul(variables('Subtotal'), 0.18)` *(simplification: this applies a flat 18% at the order level rather than per-line GSTPercent, since every catalog item currently carries the same rate — flag this as a simplification if the catalog ever has mixed GST rates in the future)*
- [ ] Add **Compose** `Total`: `add(variables('Subtotal'), outputs('GSTAmount'))`
- [ ] Add **Compose** `LineItemsText`: `join(variables('LineItemsSummary'), '\n')`
- [ ] Add **Compose** `QuoteRef`, value:
```
concat('CSQ-', formatDateTime(utcNow(), 'yyyyMMdd'), '-', substring(replace(guid(),'-',''), 0, 4))
```
- [ ] Add **Compose** `ValidUntil`, value:
```
formatDateTime(addDays(utcNow(), 30), 'MMMM dd, yyyy')
```

### 5.7 Generate the quote with AI Builder
- [ ] Add step: search `AI Builder`, select **Create text with GPT using a prompt**
- [ ] Prompt (insert dynamic content at each `[[...]]`):
```
Write a professional B2B sales quote reply email from Contoso Supplies Ltd.

Address the email to [[SenderName]].

Include a formatted quote table using these exact line items - do not alter any numbers:
[[LineItemsText]]

Then show:
- Subtotal: ₹[[Subtotal]]
- GST (18%): ₹[[GSTAmount]]
- Grand Total: ₹[[Total]]

Include:
- Quote Reference Number: [[QuoteRef]]
- Valid Until: [[ValidUntil]]
- Delivery timeline: 5-7 business days
- Payment terms: Net 30 days

Close with a professional signature block reading:
Best regards,
Contoso Supplies Ltd Sales Team

Tone: professional, concise, confident - like an experienced B2B salesperson, not a generic chatbot. Do not use exclamation points or overly casual language.
```
- [ ] Save the AI output into a variable or reference its output directly in the next step

### 5.8 Create the Outlook draft
- [ ] Add **Create a draft (V2)** (Office 365 Outlook connector)
- [ ] **To**: `variables('SenderEmail')`
- [ ] **Subject**: 
```
concat('Quote Ref: ', outputs('QuoteRef'), ' - Contoso Supplies Ltd')
```
- [ ] **Body**: the text output from the AI Builder action in 5.7
- [ ] Save the flow, turn it on

### 5.9 Live end-to-end test
- [ ] Start a stopwatch
- [ ] From the monitored inbox account, **send an email to itself** with a multi-item request, matching the confirmed reference scenario: Subject `Quote Request - Office Furniture`, Body: `Hi, could I get a quote for 3 Office Chair Pro and 2 Adjustable Standing Desk? Thanks.`
- [ ] Watch Power Automate → **Run history**, confirm it triggers
- [ ] Confirm the Teams confirmation card appears in your 1:1 chat with Flow bot — click **Approve**
- [ ] Confirm the flow continues past the confirmation condition and completes
- [ ] Stop the stopwatch when the draft appears in Outlook Drafts
- [ ] Open the draft, confirm: correct recipient, quote reference formatted like `CSQ-YYYYMMDD-XXXX`, **both** line items present (Office Chair Pro x3 and Adjustable Standing Desk x2) with correct per-line math, correct Subtotal/GST(18%)/Total across both items, valid-until date ~30 days out, Net 30 terms, 5-7 day delivery, signature block present
- [ ] Also test rejecting the confirmation card (click nothing / a hypothetical "reject" if you add one, or just don't approve) and confirm the flow correctly stops without drafting anything
- [ ] Read the draft as if you were the customer — would you send this?

---

## 6. Challenge 05 — Proactive Invoice Follow-up and Payment Confirmation

**Time budget to test against:** 35 min

**Build location:** same guidance as Challenge 4 — try Agent Flows natively in Copilot Studio first for the scheduled checker (recurrence triggers are a documented, supported Agent Flow trigger type, less exotic than the Outlook event trigger), and fall back to classic Power Automate at `https://make.powerautomate.com` if you hit a wall with the Adaptive Card action or the child-flow/HTTP-webhook pieces not being available in your tenant's Agent Flows designer yet.

**Design change — matches the confirmed reference:** overdue-invoice alerts now post as a **1:1 Teams DM to the salesperson** (same "Chat with Flow bot" pattern used in Challenge 4's confirmation card), not to a shared `Contoso Sales Alerts` channel. This means the channel-creation step from earlier drafts is no longer needed — skip it. (The Teams channel limit research from earlier is now moot for this specific alert, though it's still good to know it was never a real constraint.)

### 6.2 Build the scheduled checker flow
- [ ] Try first in Copilot Studio: **Contoso Q2C Assistant** → **Flows** → **+ Add a flow** → trigger: **Schedule** / **Recurrence**, name `Q2C - Overdue Invoice Checker`
- [ ] **Fallback:** Power Automate → **+ Create** → **Scheduled cloud flow**, same name
- [ ] Starting: today's date, Repeat every `1` `Day`, at `08:00`
- [ ] Add **Get items** (SharePoint) → List: `Invoice Tracker`, Filter Query:
```
Status eq 'Open'
```
- [ ] Add **Filter array**:
  - **From**: `body('Get_items')?['value']`
  - **Condition** (advanced mode): 
```
@less(item()?['DueDate'], utcNow())
```
- [ ] Add **Apply to each** → Output from previous step: the Filter array's output

### 6.3 Inside the loop — days overdue + Adaptive Card
- [ ] Add **Compose** `DaysOverdue`, value:
```
div(sub(ticks(utcNow()), ticks(items('Apply_to_each')?['DueDate'])), 864000000000)
```
- [ ] Add **Post adaptive card and wait for a response** (Microsoft Teams connector)
- [ ] **Post as**: Flow bot; **Post in**: **Chat with Flow bot** (1:1, matching the confirmed reference — not a channel); **Recipient**: the salesperson's own account
- [ ] Switch the Adaptive Card field to raw JSON entry and paste (insert each `@{...}` token via dynamic content, or type them directly if the field accepts raw expressions):
```json
{
  "type": "AdaptiveCard",
  "$schema": "http://adaptivecards.io/schemas/adaptive-card.json",
  "version": "1.4",
  "body": [
    {
      "type": "TextBlock",
      "text": "@{items('Apply_to_each')?['CustomerName']}",
      "weight": "Bolder",
      "size": "Medium"
    },
    {
      "type": "FactSet",
      "facts": [
        { "title": "Invoice Number:", "value": "@{items('Apply_to_each')?['InvoiceNumber']}" },
        { "title": "Amount:", "value": "₹@{items('Apply_to_each')?['Amount']}" },
        { "title": "Days Overdue:", "value": "@{outputs('DaysOverdue')}" }
      ]
    }
  ],
  "actions": [
    {
      "type": "Action.Submit",
      "title": "Draft Reminder Email",
      "data": { "action": "draft_reminder" }
    },
    {
      "type": "Action.Submit",
      "title": "Mark Resolved",
      "data": { "action": "mark_resolved" }
    }
  ]
}
```

### 6.4 Handle the button response
- [ ] Add **Condition** after the Post-card action, advanced mode:
```
@equals(body('Post_adaptive_card_and_wait_for_a_response')?['data']?['action'], 'draft_reminder')
```
- [ ] **Yes branch:** add **Run a Child Flow** (build the child flow first — see 6.5 — then it appears in this picker once published). Map inputs `CustomerName`, `InvoiceNumber`, `Amount` from `items('Apply_to_each')`.
- [ ] Below that, add another **Condition**:
```
@equals(body('Post_adaptive_card_and_wait_for_a_response')?['data']?['action'], 'mark_resolved')
```
- [ ] **Yes branch:** add **Update item** (SharePoint) → List: `Invoice Tracker`, **Id**: `items('Apply_to_each')?['ID']`, **Status**: `Resolved`

### 6.5 Build the child flow (Draft Reminder Email)
- [ ] New flow → **Instant cloud flow** → trigger: **Manually trigger a flow**, name `Q2C - Draft Payment Reminder`
- [ ] Add inputs: `CustomerName` (Text), `InvoiceNumber` (Text), `Amount` (Number)
- [ ] Add **AI Builder: Create text with GPT using a prompt**:
```
Write a polite, professional payment reminder email for [[CustomerName]] regarding overdue invoice [[InvoiceNumber]] for ₹[[Amount]]. Keep it courteous but clear that payment is due. Close with a Contoso Supplies Ltd signature block. Do not threaten any action - just a friendly, professional nudge.
```
- [ ] Add **Create a draft (V2)**: To: (use the monitored inbox's own address as a test placeholder), Subject: `concat('Payment Reminder - Invoice ', triggerBody()['text_1'])` *(adjust field name to match your actual InvoiceNumber input)*, Body: AI output
- [ ] **Save and Publish** the child flow — it will not appear in the parent flow's picker until published

### 6.6 Build the payment webhook simulation flow
- [ ] New flow → **Automated cloud flow** → trigger: **When an HTTP request is received**, name `Q2C - Payment Webhook`
- [ ] Request Body JSON Schema:
```json
{
  "type": "object",
  "properties": {
    "InvoiceNumber": { "type": "string" },
    "CustomerName": { "type": "string" }
  }
}
```
- [ ] Add **Get items** (SharePoint) → List: `Invoice Tracker`, Filter Query:
```
concat("InvoiceNumber eq '", triggerBody()?['InvoiceNumber'], "'")
```
*(Build this as an expression in the Filter Query field, not plain text — it needs to evaluate the concat.)*
- [ ] Add **Update item**: Id: `first(body('Get_items')?['value'])?['ID']`, Status: `Paid`
- [ ] Add **Send an email (V2)**: To: (test placeholder / monitored inbox), Subject: `concat('Payment Received - Invoice ', triggerBody()?['InvoiceNumber'])`, Body: `Thank you, we've received your payment for invoice ` + InvoiceNumber + `.`
- [ ] Add **Post message in a chat or channel** (Teams): Post in **Chat**, recipient: the salesperson's own account (matching the DM pattern used elsewhere), Message: `Payment received for invoice @{triggerBody()?['InvoiceNumber']} from @{triggerBody()?['CustomerName']}. Thank you!`
- [ ] Save. Click into the trigger card and **copy the generated HTTP POST URL immediately** — it's shown once.

### 6.7 Test everything
- [ ] Manually run the scheduled checker flow, confirm cards post in your 1:1 Teams chat for the genuinely overdue rows from your 15-row Invoice Tracker dataset (8 rows should qualify — confirm it's 8, not 10, not 15)
- [ ] Click **Mark Resolved** on one card, confirm the matching SharePoint row updates
- [ ] Click **Draft Reminder Email** on another, confirm a draft appears in Outlook
- [ ] Test the webhook:
```powershell
Invoke-WebRequest -Uri "[your-flow-url]" -Method POST -ContentType "application/json" -Body '{"InvoiceNumber":"INV-2025-001","CustomerName":"Acme Corp"}'
```
- [ ] Confirm the matching Invoice Tracker row updates to `Paid`, a confirmation draft/email appears, and a Teams message posts

### 6.8 NEW — Follow-up topic for ad hoc requests (matches the confirmed reference's conversational follow-up)

The confirmed reference shows the salesperson asking Copilot an ad hoc follow-up after payment lands — "please also send a payment acknowledgement to Priya" — rather than everything happening in one fixed automated pipeline. True open-ended agentic follow-up is out of scope for a beginner-level hackathon, but this is approximated cleanly by adding **one more topic** to the same Copilot Studio agent, so the user experience still feels conversational even though it's deterministic underneath, like everything else in this build.

- [ ] In Copilot Studio → **Contoso Q2C Assistant** → **Topics** → **+ Add a topic** → **From blank**
- [ ] Name it `Send Payment Acknowledgement`
- [ ] Click the trigger node's **Description** field, paste:
```
This topic handles requests to send a payment acknowledgement or receipt to a customer for a specific invoice - for example, when someone asks to notify a customer that their payment has been received, or asks to send an acknowledgement for an invoice.
```
- [ ] Add a **Question** node: text `Which invoice number is this for?`, save response into variable `InvoiceNumberForAck` (Text)
- [ ] Build a small supporting flow `Q2C - Send Payment Acknowledgement` (same pattern as earlier flows: trigger **Run a flow from Copilot**, input `InvoiceNumber` Text) that does:
  - **Get items** (SharePoint) → List: `Invoice Tracker`, Filter Query: `concat("InvoiceNumber eq '", triggerBody()?['InvoiceNumber'], "'")`
  - **Send an email (V2)**: To: (test placeholder / monitored inbox), Subject: `concat('Payment Acknowledgement - Invoice ', triggerBody()?['InvoiceNumber'])`, Body: a short acknowledgement referencing the customer name and amount from the retrieved record
  - **Respond to Copilot Studio**: output `Confirmation` (Text) = `concat('Sent a payment acknowledgement for invoice ', triggerBody()?['InvoiceNumber'], '.')`
- [ ] Back in the topic, add **Call an action**, select this flow, map `InvoiceNumber` → `InvoiceNumberForAck`
- [ ] Add a **Message** node using the flow's `Confirmation` output, e.g. `{Confirmation}`
- [ ] Test: publish, then in Test bot or Teams, type something like *"please send a payment acknowledgement for INV-2025-001"* and confirm the topic fires and the flow completes

---

## 7. Challenge 06 — End-to-End Testing, Refinement, and Deployment

**Time budget to test against:** 35 min

### 7.1 Full cycle test
- [ ] Start a timer, self-send a quote request email (same format as 5.7), stop the timer when the draft appears
- [ ] Cross-check pricing against your Product Catalog data

### 7.2 Re-verify invoice alerts and payment
- [ ] Manually trigger the scheduled flow, confirm all 8 genuinely-overdue cards post (and the other 7 rows correctly do NOT alert)
- [ ] Re-run the webhook with a second invoice, e.g.:
```powershell
Invoke-WebRequest -Uri "[your-flow-url]" -Method POST -ContentType "application/json" -Body '{"InvoiceNumber":"INV-2025-002","CustomerName":"BlueSky Ltd"}'
```

### 7.3 Refine the AI prompt — 3 documented iterations
- [ ] **Iteration 1:** adjust the 5.5 prompt to explicitly request a markdown table format instead of a plain list, re-test, compare
- [ ] **Iteration 2:** add a line instructing a specific tone, e.g. "Write like a senior Contoso account manager who has worked with this client before — warm but efficient", re-test, compare
- [ ] **Iteration 3:** add explicit Contoso terms language: "Always state: Net 30 payment terms, 5-7 business day delivery, quote valid for 30 days from issue", re-test, compare
- [ ] Save the before/after text for each iteration somewhere you can hand to Microsoft as a worked example

### 7.4 Tune the email parser
- [ ] Send 2 more test emails in different formats — a bullet list of products, and a casual unstructured sentence — and note how the current (hardcoded-for-testing) parsing logic from 5.4 holds up. Document what would need to change for real multi-format parsing (this is where you'd swap the hardcoded product-match for genuine raw-body-to-AI extraction, per the original design intent).

### 7.5 Publish to Teams
- [ ] Copilot Studio → **Contoso Q2C Assistant** → **Channels**
- [ ] Select **Microsoft Teams** → **Turn on Teams**
- [ ] Set app name/icon if prompted, click **Publish** (top right of the agent, publish the agent itself first if you haven't already)
- [ ] Wait 1-3 minutes, then in Teams: **Apps** → search `Contoso Q2C Assistant` → **Add** → open chat

### 7.6 Test in Teams
- [ ] DM the agent: `Can you help me understand pricing on a bulk order?` (not in your trigger list) — confirm whether Quote Request fires; if it misses, add the phrase back in Copilot Studio

### 7.7 Measure before/after
- [ ] Pull up your Challenge 1 process map, fill in: manual step → what the agent does now → time saved, for each of the 5 steps
- [ ] Record your actual measured cycle time from 7.1 against the "15-30 min manual" baseline claim

**Final sign-off:**
- [ ] Full cycle under 3 minutes (or documented why not)
- [ ] Quote draft is genuinely send-ready
- [ ] All 8 overdue cards post correctly, non-overdue rows correctly excluded
- [ ] Webhook works for 2+ invoices
- [ ] Agent live and responsive in Teams

---

## Issues Found (fill in as you go)

| Challenge | Issue | Severity | Notes |
|---|---|---|---|
| | | | |

## Known Risks — Current Status

1. **Adaptive Card "wait for a response" may block sequential posting across overdue invoices (Challenge 5) — open, test first.** Observe actual behavior in 6.7, decide on redesign only if it's genuinely sequential-blocking.
2. ~~AI Builder credits~~ — **Resolved**, covered by license.
3. ~~SharePoint provisioning~~ — **Resolved**, CSV import method with post-import column-type fix-up.
4. ~~Test email methodology~~ — **Resolved**, self-send with the sender-exclusion condition removed from Challenge 4 (Section 5.2 above).
5. ~~Challenge 4's inline pricing lookup was hardcoded to one product/quantity~~ — **Resolved.** Challenge 4 now does genuine multi-item extraction (AI Builder JSON parsing + Apply-to-each loop, Sections 5.5/5.6) instead of deferring this to Challenge 6. This is real added scope versus the original design — confirmed with you and built in, not deferred.
6. Dataset scaled to 15/15 rows with a deliberate overdue/not-due/resolved/paid mix — use this to verify Challenge 5's filter logic for real, not just confirm data loaded.
7. **Content mismatch confirmed live: challenge-2.md's "trigger phrases" instructions assume Classic orchestration, but a freshly created agent defaults to Generative AI orchestration**, where topics use a semantic Description field instead — there's no trigger-phrases panel at all unless you manually switch modes. Section 3.5 above now covers both paths, but challenge-2.md itself should be updated before shipping so participants aren't confused when the UI doesn't match the doc.
8. **Content mismatch confirmed live: challenge-3/4/5.md send participants to the Power Automate portal, but Copilot Studio now has native Agent Flows** built directly in the Copilot Studio designer, consuming Copilot Studio capacity rather than a separate Power Automate license. Challenge 3's pattern (Run a flow from Copilot trigger) is explicitly documented as a supported Agent Flow tool pattern — build it natively. Challenges 4/5 use less common trigger types (Outlook email arrival, scheduled recurrence) where Agent Flow support is either newer or has reported reliability caveats in preview — build natively first, but keep classic Power Automate as a tested fallback if the event trigger misbehaves. All three challenge docs should be revised to lead with the native path rather than sending participants straight to a separate portal.
9. ~~Teams channel creation limit~~ — **Checked, and now moot.** Current documented limit is 1,000 channels per team, so it was never a real constraint — and it's a non-issue either way now that Challenge 4/5 alerts moved to 1:1 Teams DMs instead of a shared channel, matching the confirmed reference.
10. **Design fix applied: Challenge 2's product question is now bound to a live SharePoint-fetched list ("Options from a list variable") via a small new flow (`Q2C - Get Product Names`), instead of free text or a manually-typed static list.** This solves the exact-match problem (button click, no typo possible) with zero manual maintenance if the catalog changes. It does add a real scope question worth resolving before shipping: this flow-building step now sits inside Challenge 2, slightly overlapping with Challenge 3's own flow content — decide whether Challenge 2 owns it directly or whether it should be introduced as an early part of Challenge 3 instead. Also confirm live whether the resulting `ProductName` variable comes through as plain Text or a choice-type needing the `Text()` conversion fix — don't assume either way.
11. **GST corrected from 10% to 18%, currency changed from $ to ₹**, matching the confirmed Microsoft reference exactly. This touched the data files, the Copilot Studio system instructions, every worked example number in Challenges 3/4, and every message/prompt template. Re-verify no stray 10%/$ references were missed if you make further edits to this doc.
12. **New: Challenge 4 now includes a confirmation Adaptive Card (1:1 Teams DM, Approve/View Catalog) before pricing lookup or drafting begins**, matching the confirmed reference's "shall I check pricing and draft a quote?" step. This reuses the same "Post adaptive card and wait for a response" pattern from Challenge 5, just targeted at a person instead of a channel — no new technique, but real added build and test time.
13. **New: Challenge 5 now includes a follow-up conversational topic ("Send Payment Acknowledgement", Section 6.8)** approximating the confirmed reference's ad hoc "please also send an acknowledgement" moment. This is a deterministic topic-plus-flow, not true open-ended agentic reasoning — good enough to feel conversational without requiring custom engine agent complexity, but worth being explicit with participants that it's a fixed, invokable topic rather than the agent improvising freely.
14. **PDF quote attachment was explicitly descoped per your decision** — the confirmed reference's "Attach quote PDF" button is not built. If Microsoft specifically checks for this, flag it now rather than at final review; otherwise this is a reasonable, deliberate cut given the hackathon's time budget.
15. **Net effect on Challenge 4's time budget:** between the confirmation card, multi-item parsing/loop, and the extra AI Builder call, Challenge 4 is meaningfully bigger than its original 45-minute scope. Time your actual build-and-test pass for this challenge specifically and be honest about whether 45 minutes is still realistic for a beginner participant, or whether the time budget or challenge structure needs to change.
