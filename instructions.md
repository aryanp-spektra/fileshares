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
- [ ] Confirm you have Teams access and can create a channel named **Contoso Sales Alerts** (needed for Challenge 5)
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

**Time budget to test against:** 40 min

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

Every quote you produce must include: product SKU, unit price, quantity, line total, GST at 10%, and a final total amount (line total plus GST).

Maintain a professional, concise tone appropriate for B2B sales correspondence at all times. Do not use casual language, emojis, or overly enthusiastic phrasing.
```
- [ ] Click **Save**

### 3.3 Disable irrelevant system topics
- [ ] Go to **Topics** → **System** (tab/filter for system topics)
- [ ] Your tenant's exact topic list may vary slightly, but disable any topic that lets the agent answer general/off-topic questions or handle things irrelevant to a scoped B2B quoting agent — commonly: **Conversational boosting** (general knowledge/web-answer fallback), **Sign in** (not needed, no external auth in this lab), and **Start over** (optional, disable if present and not essential). Click into each, use the **enable/disable toggle** (not delete).
- [ ] **Keep enabled:** Fallback, Escalate, Goodbye — these three must stay on
- [ ] Confirm at least 3 topics are now disabled

### 3.4 Create the Quote Request topic
- [ ] Go to **Topics** → click **+ Add a topic** → **From blank**
- [ ] Name it exactly: `Quote Request`
- [ ] In the **Trigger phrases** panel, click **+ Add trigger phrase** and add all 10 of these (paste one at a time):
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
- [ ] In the topic canvas, click **+** below the trigger phrases node → **Add a node** → **Message**. Set the message text to:
```
Thanks for reaching out to Contoso Supplies Ltd! I'm pulling up live pricing from our catalog now - one moment.
```
- [ ] Click **+** again → **Ask a question**. Set the question text to:
```
Could you confirm the exact product name (or SKU) and the quantity you'd like a quote for?
```
- [ ] Under that question node's response settings, choose **Identify** → **User's entire response** (or "Multiple choice"/"User's entire response" depending on UI version) and save the response into a new variable — name it `ProductRequest` (Text). This is the variable you'll map into the Challenge 3 action call.
- [ ] Click **Save**

### 3.5 Test in the canvas
- [ ] Open the **Test your agent** / **Test bot** panel (usually a chat icon top-right)
- [ ] Send these 5 messages one at a time and confirm the Quote Request topic fires for all of them (the first 3 are exact/near-exact trigger phrases, the last 2 are deliberately NOT in your trigger list, to test generalization):
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
- [ ] If any of the first 5 miss, add a close variant of that phrasing to your trigger phrase list and retest immediately — don't move on with a known gap, since Challenge 4's email trigger accuracy depends on this topic being reliable.

---

## 4. Challenge 03 — SharePoint Pricing Action with Power Automate

**Time budget to test against:** 35 min

### 4.1 Create the flow and trigger
- [ ] Go to `https://make.powerautomate.com`, confirm the environment (top right) matches your ODL environment
- [ ] Click **+ Create** → **Automated cloud flow**
- [ ] In the trigger search box, search `Copilot Studio` and select **When Copilot Studio calls a flow** (this may show as "Run a flow from Copilot Studio" or "When an agent calls this flow" depending on version — pick whichever one references Copilot Studio, not "Manually trigger a flow")
- [ ] Skip the trigger-name popup or name the flow `Q2C - Pricing Lookup`
- [ ] On the trigger card, click **+ Add an input** → choose **Text** → name it `ProductKeyword`
- [ ] Click **+ Add an input** again → choose **Number** → name it `Quantity`

### 4.2 Get the product
- [ ] Click **+ New step**, search `SharePoint`, choose **Get items**
- [ ] **Site Address**: select your Contoso Q2C Site from the dropdown (or paste the URL you saved earlier)
- [ ] **List Name**: `Product Catalog`
- [ ] Click **Show advanced options** → in **Filter Query**, paste:
```
substringof(triggerBody()?['ProductKeyword'], ProductName)
```
*(If your internal column name for ProductName came through differently during Challenge 1's data load, e.g. `ProductName0`, use that exact internal name here instead.)*

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
- [ ] Run and confirm the output: **SKU = CS-001, UnitPrice = 299, LineTotal = 897, GSTAmount = 89.7, Total = 986.7**
- [ ] Run again with `ProductKeyword` = `Widget`, `Quantity` = `1` — confirm the No-branch fallback message returns instead of an error

### 4.6 Register the action in Copilot Studio
- [ ] Go back to Copilot Studio → open **Contoso Q2C Assistant** → **Quote Request** topic
- [ ] Click **+** after the question node → **Add an action** → **Call an action** (or "Call a flow")
- [ ] Select your `Q2C - Pricing Lookup` flow (if it doesn't appear, confirm it's in the same environment and uses the Copilot Studio trigger, then refresh)
- [ ] Map **ProductKeyword** → the `ProductRequest` variable captured earlier
- [ ] Map **Quantity** → if you didn't capture a separate quantity variable, set this to a fixed value of `1` for now (acceptable per the lab's own guidance — you can extend to proper quantity-parsing later)

### 4.7 Display the result
- [ ] Add a **Message** node after the action call. Set the message to (using the topic's dynamic content picker to insert each `{}` placeholder from the flow's outputs):
```
Here's your pricing:

**Product:** {ProductName}
**SKU:** {SKU}
**Unit Price:** ${UnitPrice}
**Quantity:** {Quantity}
**Line Total:** ${LineTotal}
**GST (10%):** ${GSTAmount}
**Total:** ${Total}
```
- [ ] Save

### 4.8 Test end-to-end in canvas
- [ ] Open Test bot, run a conversation: trigger Quote Request, answer the product/quantity question with `Office Chair Pro, 3`, confirm the formatted card shows SKU CS-001 and the numbers from 4.5
- [ ] Repeat with `27-inch Monitor, 2` and confirm correct pricing
- [ ] Repeat with `Gizmo, 1` and confirm the friendly not-found message

---

## 5. Challenge 04 — Outlook Trigger and AI-Drafted Quote Reply

**Time budget to test against:** 45 min

### 5.1 Create the trigger
- [ ] `https://make.powerautomate.com` → **+ Create** → **Automated cloud flow**
- [ ] Search `Office 365 Outlook`, select trigger **When a new email arrives (V3)**
- [ ] Name the flow `Q2C - Quote Request Handler`
- [ ] Folder: **Inbox** (default)

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

### 5.4 Look up pricing inline
- [ ] Add **Get items** (SharePoint) → Site: Contoso Q2C Site, List: `Product Catalog`
- [ ] Filter Query (advanced options) — same pattern as Challenge 3, but matching against the email body since there's no structured ProductKeyword input here. For the first working version, hardcode a test product name to prove the pipeline end-to-end, e.g.:
```
substringof('Office Chair', ProductName)
```
*(Note: this is a simplification for getting the flow working — Challenge 6 revisits proper multi-format parsing. Document this as a known limitation of the first build, not a bug.)*
- [ ] Add **Compose** `LineTotal`: `mul(body('Get_items')?['value'][0]?['UnitPrice'], 3)` *(hardcode Quantity=3 for the first test pass, matching your test email)*
- [ ] Add **Compose** `GSTAmount`: `mul(outputs('LineTotal'), div(body('Get_items')?['value'][0]?['GSTPercent'], 100))`
- [ ] Add **Compose** `Total`: `add(outputs('LineTotal'), outputs('GSTAmount'))`
- [ ] Add **Compose** `QuoteRef`, value:
```
concat('CSQ-', formatDateTime(utcNow(), 'yyyyMMdd'), '-', substring(replace(guid(),'-',''), 0, 4))
```
- [ ] Add **Compose** `ValidUntil`, value:
```
formatDateTime(addDays(utcNow(), 30), 'MMMM dd, yyyy')
```

### 5.5 Generate the quote with AI Builder
- [ ] Add step: search `AI Builder`, select **Create text with GPT using a prompt**
- [ ] Paste this into the prompt field, replacing each `[[...]]` with the matching dynamic content token from the picker (click into the prompt box, then use "Add dynamic content" to insert each value at that exact spot):
```
Write a professional B2B sales quote reply email from Contoso Supplies Ltd.

Address the email to [[SenderName]].

Include a formatted quote table with these exact values - do not alter any numbers:
- Product: [[ProductName from Get items]]
- SKU: [[SKU from Get items]]
- Quantity: 3
- Unit Price: $[[UnitPrice from Get items]]
- Line Total: $[[LineTotal]]
- GST (10%): $[[GSTAmount]]
- Grand Total: $[[Total]]

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

### 5.6 Create the Outlook draft
- [ ] Add **Create a draft (V2)** (Office 365 Outlook connector)
- [ ] **To**: `variables('SenderEmail')`
- [ ] **Subject**: 
```
concat('Quote Ref: ', outputs('QuoteRef'), ' - Contoso Supplies Ltd')
```
- [ ] **Body**: the text output from the AI Builder action in 5.5
- [ ] Save the flow, turn it on

### 5.7 Live end-to-end test
- [ ] Start a stopwatch
- [ ] From the monitored inbox account, **send an email to itself**: Subject `Quote Request - Office Chairs`, Body: `Hi, could I get a quote for 3 Office Chair Pro units? Thanks.`
- [ ] Watch Power Automate → **Run history** for this flow, confirm it triggers (proves the condition fix in 5.2 works)
- [ ] Stop the stopwatch when the draft appears in Outlook Drafts (`https://outlook.office.com` → Drafts folder)
- [ ] Open the draft, confirm: correct recipient, quote reference present and formatted like `CSQ-YYYYMMDD-XXXX`, pricing table shows SKU CS-001 / $299 / qty 3 / $897 line total / $89.70 GST / $986.70 total, valid-until date ~30 days out, Net 30 terms, 5-7 day delivery, signature block present
- [ ] Read the draft as if you were the customer — would you send this?

---

## 6. Challenge 05 — Proactive Invoice Follow-up and Payment Confirmation

**Time budget to test against:** 35 min

### 6.1 Create a Teams channel for alerts
- [ ] In Microsoft Teams, go to an existing team (or create one), click **+ Add channel**, name it `Contoso Sales Alerts`

### 6.2 Build the scheduled checker flow
- [ ] Power Automate → **+ Create** → **Scheduled cloud flow**, name `Q2C - Overdue Invoice Checker`
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
- [ ] Post as: Flow bot (or your choice); Post in: **Channel**; Team: your team; Channel: `Contoso Sales Alerts`
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
        { "title": "Amount:", "value": "$@{items('Apply_to_each')?['Amount']}" },
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
Write a polite, professional payment reminder email for [[CustomerName]] regarding overdue invoice [[InvoiceNumber]] for $[[Amount]]. Keep it courteous but clear that payment is due. Close with a Contoso Supplies Ltd signature block. Do not threaten any action - just a friendly, professional nudge.
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
- [ ] Add **Post message in a chat or channel** (Teams): Channel `Contoso Sales Alerts`, Message: `Payment received for invoice @{triggerBody()?['InvoiceNumber']} from @{triggerBody()?['CustomerName']}. Thank you!`
- [ ] Save. Click into the trigger card and **copy the generated HTTP POST URL immediately** — it's shown once.

### 6.7 Test everything
- [ ] Manually run the scheduled checker flow, confirm cards post in `Contoso Sales Alerts` for the genuinely overdue rows from your 15-row Invoice Tracker dataset (8 rows should qualify — confirm it's 8, not 10, not 15)
- [ ] Click **Mark Resolved** on one card, confirm the matching SharePoint row updates
- [ ] Click **Draft Reminder Email** on another, confirm a draft appears in Outlook
- [ ] Test the webhook:
```powershell
Invoke-WebRequest -Uri "[your-flow-url]" -Method POST -ContentType "application/json" -Body '{"InvoiceNumber":"INV-2025-001","CustomerName":"Acme Corp"}'
```
- [ ] Confirm the matching Invoice Tracker row updates to `Paid`, a confirmation draft/email appears, and a Teams message posts

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
5. **Challenge 4's inline pricing lookup (5.4) is hardcoded to one product/quantity for the first working build**, matching the lab's own stated approach of getting a single-product version working before generalizing. Genuine multi-format, multi-product parsing is explicitly deferred to Challenge 6 (7.4) — confirm this progression reads clearly to a participant and doesn't feel like a shortcut you're hiding.
6. Dataset scaled to 15/15 rows with a deliberate overdue/not-due/resolved/paid mix — use this to verify Challenge 5's filter logic for real, not just confirm data loaded.
