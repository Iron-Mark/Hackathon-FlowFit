# Families / Kids audience options (decision memo)

Last updated: 2026-08-27

**Owner decision required.** This memo does not assert COPPA, Google Play
Families, or Apple Kids Category compliance. It frames choices so store
declarations and product work can proceed.

Living checklist scaffold:
[STORE_SUBMISSION_CHECKLIST.md](STORE_SUBMISSION_CHECKLIST.md)
(Children's Audience section). Privacy posture:
[PRIVACY_DATA_MAP.md](PRIVACY_DATA_MAP.md). Brand constraints:
[brand-voice.md](brand-voice.md).

## What already ships

| Control | Reality |
| --- | --- |
| `/age-gate` | Self-attested only; splits 7-12 Buddy path from 13+ survey |
| Parent-supervise copy | Landing, auth, account-control surfaces tell a parent/guardian to create and supervise the account |
| Verifiable parental consent (VPC) | Not implemented |
| Play Designed for Families / Apple Kids Category | Not enrolled |
| Package ID | `com.msiazondev.flowfit` (unchanged by this decision) |

## Option A — Parent-supervised wellness (no child-directed claim)

**Position:** Market and declare the app for parents/guardians and teens (13+),
with a child using the app only under parental supervision. Do **not** claim
the app is directed primarily to children under 13. Do **not** enroll in Play
Families or Apple Kids Category for the first public release.

| Pros | Cons |
| --- | --- |
| Matches current engineering (self-attested gate, no VPC) | Must avoid "for kids" / primary child-audience store and landing claims |
| Fastest path to Play internal → production | If reviewers treat content as child-directed anyway, extra scrutiny |
| Lower immediate COPPA/Families build cost | Kids-mode UX still exists; copy must stay parent-framed |

**If chosen, do next**

1. Record the decision in issue #10 and the store checklist Families block.
2. Keep listing and landing copy parent-supervise framed (already largely done).
3. Set Play target audience to 13+ (or mixed adult + teen per Play UI) without
   Families enrollment.
4. Revisit VPC / Families only if you later market to children under 13.

## Option B — Child-directed / Families enrollment

**Position:** Treat ages 7-12 as a primary audience and enroll in Google Play
Designed for Families and/or Apple Kids Category.

| Pros | Cons |
| --- | --- |
| Aligns with kids-mode product intent | Requires verifiable parental consent before collecting personal data from children |
| Clear store audience signal | Extra Play Families / Apple Kids questionnaires and policies |
| | Likely schema + UX work (`guardians`, `parental_consent`, retention) |
| | Counsel review before public claims |

**If chosen, do next**

1. Legal/counsel: COPPA §312.5 / relevant parental-consent method.
2. Implement VPC before child data collection (not just a checkbox).
3. Complete Families / Kids Category declarations and data minimization review.
4. Hold public production until VPC and store forms are done; internal testing
   can stay limited and labeled.

## Option C — Defer public; ship internal only under Option A posture

Use Option A declarations for **internal testing** only. Keep production
blocked until Option A is confirmed in writing or Option B engineering starts.

## Recommendation (engineering, not legal)

For the **first Play internal testing upload**, Option A (or C) fits what the
app actually implements today. Option B should wait until VPC and counsel are
funded. **This is not legal advice.**

## Decision record (fill when decided)

| Field | Value |
| --- | --- |
| Decision date | |
| Chosen option | A / B / C |
| Decided by | |
| Counsel involved? | yes / no |
| Play target audience set to | |
| Families / Kids enrollment | none / Play / Apple / both |
| Follow-up tickets | |

After recording, update
[STORE_SUBMISSION_CHECKLIST.md](STORE_SUBMISSION_CHECKLIST.md) Children's
Audience checkboxes and comment on
[issue #10](https://github.com/Iron-Mark/Hackathon-FlowFit/issues/10).
