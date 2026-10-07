# Design: AlmaLinux Work Report Spreadsheet

**Date:** 2026-04-13
**Format:** Microsoft Excel (.xlsx)
**Audience:** Technical stakeholders / grant organizers
**Style:** Layered (summary + detail backup), light visual cues

---

## Workbook Structure: 3 Sheets

### Sheet 1: "Summary"

**Header block (rows 1-4):**
- Row 1: Project — OOSH - AlmaLinux Platform Support
- Row 2: Period — 2026-02-22 to 2026-04-13 (~7 weeks)
- Row 3: Authors — Hannes Nortje, Marcel Donges (assisted by Claude AI)
- Row 4: Total Commits — 250+

**Main table (row 6+):**

| Column | Content |
|--------|---------|
| Work Area | Name of work area (e.g., "Package Manager Support (dnf/yum)") |
| Category | "Core" or "Cross-platform" |
| Commits | Number of commits |
| Files Changed | Number of files |
| Period | Date range |
| Status | "Complete" for all rows |

18 data rows + 1 totals row.

**Formatting:**
- Category "Core": light blue fill
- Category "Cross-platform": light grey fill
- Status "Complete": green fill
- Totals row: bold
- Header row: white text on dark blue background
- Alternating row shading within each category group

---

### Sheet 2: "Work Areas Detail"

**Table columns:**

| Column | Content |
|--------|---------|
| Work Area | Area name |
| Description | One-line summary of the problem |
| What Was Done | Technical summary of the solution |
| Key Commits | Commit hashes or "N commits" |
| Key Files | Files affected |

18 rows matching the summary table. Same category color coding.

---

### Sheet 3: "Platform Matrix"

**Header block (rows 1-2):**
- Row 1: Test Date — 2026-04-13
- Row 2: Release — v1.0.0

**Platform table (row 4+):**

| Column | Content |
|--------|---------|
| Platform | Platform name + version |
| Package Manager | apt-get, dnf, apk, brew, etc. |
| Tier | "must-pass" or "best-effort" |
| Image Size | Docker image size |
| Test Assertions | e.g., "218/219" |
| Pass Rate | e.g., "99.5%" |
| Status | "Pass" or blank |

7 rows (5 must-pass + 2 best-effort).

**Formatting:**
- AlmaLinux row: bold
- Status "Pass": green fill
- Tier "must-pass": light orange fill
- Tier "best-effort": light grey fill
- Footnote: "1 intentional meta-test failure (test framework self-test)"

**Promotion Gate sub-table (below main table):**

| Gate | Requirement | Result |
|------|-------------|--------|
| dev -> stage | All core tests pass | Passed |
| stage -> prod | All must-pass platforms pass | Passed (5/5) |

---

## Implementation

- Generator: Python script using openpyxl
- Output: `docs/reports/2026-04-13-almalinux-work-report.xlsx`
- Replaces existing raw-XML generator
