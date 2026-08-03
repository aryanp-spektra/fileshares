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

**Time budget to test against:** 30 min (this now includes site/list creation from Section 1.3 onward — confirm the full 30 minutes actually covers all of the below, not just the original data-entry steps)

### 2.1 Map the Q2C process (5 min)
- [ ] Write down the 5 manual steps a Contoso salesperson performs today, email-to-payment. **Keep this — you need it again in Challenge 6, Step 8.**

### 2.2 Create the Product Catalog list (3 min)
- [ ] On the Contoso Q2C Site, **New > List > Blank list**, name it exactly `Product Catalog`
- [ ] Add these four columns, matching type and name exactly:

| Column Name | Column Type | Notes |
|---|---|---|
| SKU | Single line of text | |
| ProductName | Single line of text | |
| UnitPrice | Currency | |
| GSTPercent | Number | No decimals needed |

- [ ] Leave the default **Title** column in place (rename/hide, don't delete)
- [ ] **Checkpoint:** open List settings > Columns, confirm all four types are correct before adding data

### 2.3 Create the Invoice Tracker list (4 min)
- [ ] **New > List > Blank list**, name it exactly `Invoice Tracker`
- [ ] Add these five columns in order:

| Column Name | Column Type | Notes |
|---|---|---|
| CustomerName | Single line of text | |
| InvoiceNumber | Single line of text | |
| Amount | Currency | |
| DueDate | Date and Time | Set format to **Date Only** |
| Status | Choice | Exactly three choices: `Open`, `Resolved`, `Paid` |

- [ ] **Checkpoint:** confirm Status has exactly three choices with no typos, and DueDate is Date Only — a stray time component can break the "overdue" comparison logic in Challenge 5

### 2.4 Load the data (4 min)
- [ ] Open `Q2C-Lab-Source-Data.xlsx`, go to the **Product Catalog** tab
- [ ] Select only the 5 data rows (not the header), copy
- [ ] In SharePoint, open the Product Catalog list, switch to **Quick Edit**, click the first empty cell, paste, commit, switch back to standard view
- [ ] Repeat for the **Invoice Tracker** tab into the Invoice Tracker list

Reference data (already in the workbook, shown here for verification):

| SKU | ProductName | UnitPrice | GSTPercent |
|---|---|---|---|
| CS-001 | Office Chair Pro | 299.00 | 10 |
| CS-002 | Adjustable Standing Desk | 649.00 | 10 |
| CS-003 | Laptop Stand | 89.00 | 10 |
| CS-004 | Wireless Keyboard | 119.00 | 10 |
| CS-005 | 27-inch Monitor | 489.00 | 10 |

| CustomerName | InvoiceNumber | Amount | DueDate | Status |
|---|---|---|---|---|
| Acme Corp | INV-2025-001 | 2450.00 | 2025-06-01 | Open |
| BlueSky Ltd | INV-2025-002 | 890.00 | 2025-06-15 | Open |
| NovaTech Inc | INV-2025-003 | 3200.00 | 2025-07-01 | Open |

### 2.5 Verify (2 min)
- [ ] Product Catalog: exactly 5 rows, UnitPrice showing currency formatting
- [ ] Invoice Tracker: exactly 3 rows, DueDate showing as plain date, Status = `Open` on all three (blank/red Status means a Choice-option mismatch — check for trailing spaces or case differences)
- [ ] Run a manual filter on Product Catalog (e.g. ProductName contains "Chair") and confirm the correct row returns — this is your smoke test for the Challenge 3 OData filter
- [ ] Note the internal column name for ProductName and GSTPercent (edit the column, check the URL) — needed verbatim for Challenge 3's filter expressions

**VALIDATE:** the Invoice Tracker DueDates are fixed in the past (2025) — confirm they still read as "overdue" whenever you run this. They will, since today's date is always later; this is a deliberate hardcode, not a bug.

**If something goes wrong:**
- Currency symbol missing after paste → column was created as Number, not Currency; fix the type
- Status blank/error on paste → Choice option text doesn't exactly match pasted text
- DueDate shows a timestamp → format wasn't set to Date Only before pasting

---

## 3. Challenge 02 — Copilot Studio Agent Foundation

**Time budget to test against:** 40 min

- [ ] Create blank agent (not "Create with AI") named **Contoso Q2C Assistant**
- [ ] Paste in system instructions covering all 5 required points (scope to Contoso sales, Q2C-only, must retrieve SharePoint pricing before quoting, must include SKU/unit price/qty/line total/GST 10%/total, professional B2B tone)
- [ ] Open System topics, disable (not delete) at least 3 irrelevant ones, keep Fallback/Escalate/Goodbye enabled
- [ ] Create **Quote Request** topic with ≥8 trigger phrases covering varied phrasing (procurement-formal vs. casual)
- [ ] Build the 2-node flow: acknowledgment message → question node for missing details
- [ ] Test in canvas with 5 prompts — include at least 2 phrases you did NOT add as triggers, to genuinely test generalization
- [ ] Confirm it does **not** fire on "what is your return policy" and "I need IT support"

**VALIDATE:** if any of your 5 test prompts miss, add the phrasing and retest now — Challenge 4's email-trigger accuracy depends on this topic being reliable.

---

## 4. Challenge 03 — SharePoint Pricing Action with Power Automate

**Time budget to test against:** 35 min

- [ ] Create cloud flow with trigger **Run a flow from Copilot Studio** (confirm the exact label in your environment — may show as "When an agent calls this flow")
- [ ] Define inputs: ProductKeyword (Text), Quantity (Number)
- [ ] Get items on Product Catalog with `substringof('keyword', ProductName)` OData filter
- [ ] Condition: `length(body('Get_items')?['value'])` greater than 0
- [ ] Yes branch — Compose **LineTotal**: `mul(body('Get_items')?['value'][0]?['UnitPrice'], triggerBody()?['Quantity'])`
- [ ] Compose **GSTAmount**: `mul(outputs('LineTotal'), div(body('Get_items')?['value'][0]?['GSTPercent'], 100))`
- [ ] No branch: friendly "Product not found" response
- [ ] Respond to Copilot Studio with all 6 values

**VALIDATE — run this exact manual test and confirm the numbers:**

| Input | Value |
|---|---|
| ProductKeyword | `Office Chair` |
| Quantity | `3` |

Expected output: **SKU = CS-001, UnitPrice = 299.00, LineTotal = 897.00, GSTAmount = 89.70**

- [ ] Test a zero-match keyword (e.g. `Widget`) and confirm the fallback message returns, not an error
- [ ] Register the flow as a callable action on the Quote Request topic; confirm it appears in the "Call a flow" picker
- [ ] Map ProductKeyword/Quantity to conversation variables
- [ ] Add the formatted Message node (Product Name, SKU, Unit Price, Quantity, Line Total, GST Amount, Total)
- [ ] Test end-to-end in canvas with 3 product keywords including one non-match

---

## 5. Challenge 04 — Outlook Trigger and AI-Drafted Quote Reply

**Time budget to test against:** 45 min — tightest budget relative to step count (7 multi-part steps); time yourself honestly.

- [ ] Automated cloud flow, trigger: **When a new email arrives (V3)**, monitoring the lab inbox
- [ ] Condition: Subject OR Body contains `quote` / `pricing` / `quotation` (case-insensitive via `toLower()`)

### 5.1 Required content fix — anti-loop condition

The original design also checked that the sender email does **not** contain the monitored inbox address, to stop the flow re-triggering on its own output. **Drop this condition.** It conflicts with the confirmed test methodology (self-send to the same inbox) and isn't actually protecting against anything real: this flow only ever creates a **Draft**, never an auto-Send, and a Draft never lands back in the Inbox to re-trigger the "new email arrives" trigger. Build the condition as just the keyword check (Subject/Body contains quote/pricing/quotation) with no sender exclusion.

- [ ] Confirm the condition is built as keyword-only, no sender-address exclusion
- [ ] False branch: Terminate (Succeeded) — cleanly exits on non-quote emails

### 5.2 Continue the build
- [ ] Parse SenderName/SenderEmail from trigger output
- [ ] Get items on Product Catalog again (inline — the Challenge 3 flow can't be reused as a child flow since it uses a different trigger type)
- [ ] Compose LineTotal/GSTAmount using the same expressions, stored into Initialize Variable actions
- [ ] AI Builder "Create text with GPT using a prompt" action — confirm this actually runs and returns text before building the rest around it
- [ ] Create a draft (V2) — To: sender, Subject: `Quote Ref: [ref] - Contoso Supplies Ltd`, Body: AI output

**VALIDATE — live end-to-end test:**

1. Start a stopwatch
2. **Send the test email from the account to itself** (confirmed methodology — same monitored inbox as both sender and recipient): Subject `Quote Request - Office Chairs`, body mentioning "Office Chair Pro" and a quantity (e.g. "3")
3. Watch Power Automate run history — confirm it triggers at all (this proves the condition fix above works), and note whether the connector's polling interval affects timing
4. Stop the stopwatch when the draft appears in Outlook Drafts
5. Confirm: correct recipient, quote reference present, pricing table has the right SKU/price/line total/GST, valid-until date, delivery timeline, payment terms, signature block

Note: since recipient = sender = monitored inbox in this test, double-check the draft's "To" field genuinely reflects dynamic parsing of the sender from the trigger output, rather than coincidentally looking correct.

**Issues to watch for specifically:**
- Draft body quality — read it as if you were the customer. Note anything that reads like generic AI filler.
- Whether "When a new email arrives (V3)" polling delay pushes you past the 60-second target in the success criteria.

---

## 6. Challenge 05 — Proactive Invoice Follow-up and Payment Confirmation

**Time budget to test against:** 35 min — tight given 3 sub-flows (scheduled checker, child flow, HTTP webhook) plus Adaptive Card design.

- [ ] Scheduled flow, daily 8:00 AM recurrence
- [ ] Get items: Status eq Open
- [ ] Filter Array: `less(item()?['DueDate'], utcNow())` (safer than an OData date filter — confirm this works, SharePoint OData date/timezone handling is a known trap)
- [ ] Days overdue calc: `div(sub(ticks(utcNow()), ticks(items('Apply_to_each')?['DueDate'])), 864000000000)`
- [ ] Build Adaptive Card (Customer Name bold, Invoice Number, Amount, Days past due, 2 buttons) — build/preview in adaptivecards.io/designer first
- [ ] Post using **"Post adaptive card and wait for a response"** (not the plain post action)

**VALIDATE — highest-risk item in the lab, test as-built first per your call:**

- [ ] Trigger the flow manually with all 3 overdue records present
- [ ] **Confirm explicitly whether card #2 posts before or after you respond to card #1.** If "wait for a response" sits inside the same `Apply to each` sequentially, card #2 won't appear until you respond to (or time out on) card #1. Observe actual behavior first — if this is what happens, decide then whether to redesign (post all 3 cards without blocking, handle responses via a separate trigger) or document it as intended sequential behavior.
- [ ] Click **Mark Resolved** on one card — confirm the correct SharePoint row updates (verify by ID, not just visually)
- [ ] Click **Draft Reminder Email** on another — confirm the child flow fires and an Outlook draft appears
- [ ] Confirm the child flow is **published** before testing (unpublished child flows won't appear in the picker)
- [ ] Build the HTTP-triggered payment webhook flow, copy the generated POST URL immediately (confirm it's really only shown once)

**VALIDATE webhook test (do this now, not just in Challenge 6):**

```powershell
Invoke-WebRequest -Uri "[your-flow-url]" -Method POST -ContentType "application/json" -Body '{"InvoiceNumber":"INV-2025-001","CustomerName":"Acme Corp"}'
```

- [ ] Confirm Invoice Tracker record updates to Paid
- [ ] Confirm confirmation email draft created
- [ ] Confirm Teams "Payment Received" message posts

---

## 7. Challenge 06 — End-to-End Testing, Refinement, and Deployment

**Time budget to test against:** 35 min

- [ ] Full cycle test again from a cold state: self-send test email → time to Outlook draft. Record actual seconds/minutes.
- [ ] Manually trigger Challenge 5's scheduled flow, confirm all 3 cards post (re-verify the blocking behavior under real conditions), confirm buttons work
- [ ] Re-run the payment webhook simulation with a different invoice (e.g. INV-2025-002) to confirm it's not hardcoded to one record
- [ ] Run 3 real iterations of AI prompt refinement on the Challenge 4 compose step — document the before/after text for each iteration
- [ ] Test the email parser against at least 2 different formats: a bullet list of products, and a casual unstructured request. Note where the "raw body to AI" approach holds up vs. where it doesn't.
- [ ] Publish agent to Teams — time how long it actually takes to appear (doc says 1-3 minutes, flag if longer)
- [ ] DM the agent in Teams with a phrase not in your trigger list, confirm topic behavior
- [ ] Fill in the before/after table from your Challenge 1 process map and your measured cycle time

**Final sign-off — all must be true before you consider the content shippable:**

- [ ] Full cycle completes within 3 minutes of test email being sent (or you've documented why not, e.g. connector polling delay)
- [ ] Quote draft is something you would genuinely send to a customer
- [ ] All 3 Adaptive Cards appear and both buttons work as documented
- [ ] Payment webhook simulation works for at least 2 different invoices
- [ ] Agent is live and responsive in Teams

---

## Issues Found (fill in as you go)

| Challenge | Issue | Severity | Notes |
|---|---|---|---|
| | | | |

## Known Risks — Current Status

1. **Adaptive Card "wait for a response" may block sequential posting across the 3 overdue invoices (Challenge 5) — open, test first.** Perform the test as currently designed, observe actual behavior, then decide whether a redesign is needed.
2. ~~AI Builder credits~~ — **Resolved.** Covered by the Copilot Studio + base Office 365 license every participant gets.
3. ~~SharePoint site provisioning~~ — **Resolved.** Site and lists are now built by the participant in Sections 1.3 and 2 above, using manual column creation + Quick Edit paste from the provided workbook. No import-wizard type-mismatch risk.
4. ~~External test email deliverability~~ — **Resolved, with a required fix applied.** Participants self-send to their own monitored inbox. The anti-loop condition that would have blocked this is removed per Section 5.1 above.
5. Challenges 4 and 5 have the tightest time budgets relative to step count — time yourself honestly rather than assuming the stated minutes hold up.
