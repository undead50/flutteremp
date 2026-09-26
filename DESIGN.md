# Everest Bank Limited E

## Overview

**Product:** Everest Bank Limited E
**URL:** https://omni.ebl-zone.com/
**Surface type:** e-commerce
**Audience:** Consumers and shoppers
**Brand character:** Product-focused shopping experience with a rich, diverse color palette and 3 typefaces.

> **Note:** Surface detection confidence is low. Verify the inferred audience and brand context before relying on this file.

### Design Principles

- Trust signals first — credibility reduces friction more than clever copy.
- Clear path to action — one primary CTA per view, never stacked.
- Speed over polish — perceived performance is part of the design system.

## Colors

| Token | Value | Role |
|-------|-------|------|
| --text-color | `#191B22` | Text Primary |
| --text-xs-color | `#47494E` | Text Primary |
| color-4 | `#5E5F64` | Text Primary |
| color-3 | `#BA131A` | Accent |
| color-6 | `#F8BC2F` | Accent |
| color-5 | `#A4A7B0` | Border |
| color-7 | `#C8CAD0` | Border |
| color-8 | `#FFFFFF` | Text Light |

## Typography

**Font stack:** Source Sans Pro, Inter, sans-serif

| Level | Size | Usage |
|-------|------|-------|
| text-xs | 12px | Captions, metadata |
| text-sm | 14px | Labels, secondary text |
| text-base | 16px | Body text (default) |
| text-lg | 18px | Subheadings, emphasis |
| text-xl | 22px | Section headings |
| text-2xl | 30px | Section headings |

**Weight scale:** 400 · 700
**Line heights:** 31.9px · 23.94px · 24px · 14px · 21px · 20px · 18px · 16px · 13px · 39.9px · 18.4px · 14.4px

## Spacing

**Base unit:** 4px

`space-1: 3px` · `space-2: 4px` · `space-3: 6px` · `space-4: 7px` · `space-5: 8px` · `space-6: 9px` · `space-7: 10px` · `space-8: 12px` · `space-9: 15px` · `space-10: 16px` · `space-11: 18px` · `space-12: 22px` · `space-13: 24px` · `space-14: 28px` · `space-15: 30px` · `space-16: 33px` · `space-17: 40px` · `space-18: 44px` · `space-19: 67px` · `space-20: 192px` · `space-21: 245px`

## Shapes

**Border radius:** `radius-sm: 3px` · `radius-md: 4px` · `radius-lg: 12px` · `radius-xl: 12px 12px 0px 0px` · `radius-full: 12px 12px 3px 3px` · `radius-6: 14px`

## Elevation

- **shadow-sm:** `rgba(0, 0, 0, 0.04) 0px 4px 8px 0px, rgba(0, 0, 0, 0.06) 0px 16px 48px -10px`
- **shadow-md:** `rgba(0, 0, 0, 0.08) 0px 16px 32px 10px`

## Motion

- **duration-fast:** `all`
- **duration-fast:** `transform`
- **duration-fast:** `opacity`
- **duration-fast:** `none`
- **duration-base:** `0.2s ease-in-out`
- **duration-base:** `opacity 0.2s ease-in`
- **duration-base:** `background-color 0.25s cubic-bezier(0.17, 0.67, 0.83, 0.67)`
- **duration-base:** `border 0.25s cubic-bezier(0.17, 0.67, 0.83, 0.67)`
- **duration-base:** `box-shadow 0.25s cubic-bezier(0.17, 0.67, 0.83, 0.67)`
- **duration-base:** `opacity 0.3s`
- **duration-slow:** `transform 0.5s`

## Components

- **Buttons:** 10 detected
- **Links:** 17 detected
- **Inputs:** 1 detected
- **Navigation:** 1 elements
- **Lists:** 5 detected
- **Forms:** 1 detected
- **Images:** 19 detected

## Do's and Don'ts

### Do

- Reference tokens by name, not raw values — agents and developers should use `color.text.primary`, not `#171717`.
- Define all interactive states: default, hover, focus-visible, active, disabled.
- Use the spacing scale for all padding, margin, and gap values.
- Write content in sentence case. Reserve ALL CAPS for acronyms only.
- Test every component at the smallest and largest breakpoint before shipping.

### Don't

- Do not introduce colors outside the extracted palette.
- Do not use arbitrary spacing values — stick to the scale.
- Do not mix border-radius values. Pin to the detected set (3px, 4px, 12px, 12px 12px 0px 0px, 12px 12px 3px 3px, 14px).
- Do not stack more than one primary CTA per viewport.
- Do not use red for non-error UI — reserve it for destructive actions and warnings.
- Do not ship components without defining hover, focus-visible, and disabled states.

## Writing Tone

Persuasive, benefit-driven, trustworthy. Active voice, urgency without pressure.

## Authoring Workflow

When creating or updating a component guideline for this system, follow this sequence:

1. **State the intent** — one sentence on what the component does and why it exists.
2. **Map tokens** — list every color, spacing, typography, and radius token the component uses. No raw values.
3. **Define anatomy** — break the component into named parts (container, label, icon, etc.) with their token assignments.
4. **Specify states** — document every state: default, hover, focus-visible, active, disabled, loading, error, empty.
5. **Describe interactions** — keyboard, pointer, and touch behavior, including edge cases (long content, overflow, truncation).
6. **Add accessibility criteria** — write testable pass/fail checks (e.g. "focus ring must be visible at 3:1 contrast").
7. **List anti-patterns** — concrete examples of misuse with a brief explanation of why each is wrong.
8. **Close with a QA checklist** — a mechanical list of verifiable items (see Definition of Done below).

## Required Output Structure

Every component guideline produced from this system must contain these sections, in order:

1. Overview — purpose, when to use, when not to use.
2. Tokens and foundations — all referenced tokens from the tables above.
3. Anatomy and variants — named parts, variant matrix, responsive behavior.
4. States and interactions — full state table, keyboard/pointer/touch behavior.
5. Accessibility — ARIA attributes, contrast requirements, focus management, screen reader behavior.
6. Content guidelines — copy length, tone, capitalisation, placeholder text rules.
7. Anti-patterns — explicit examples of what not to build, with reasoning.

## Component Requirements

Every component built against this system must:

- Reference only tokens defined in the tables above — no hardcoded hex, px, or font values.
- Define all interactive states: default, hover, focus-visible, active, disabled, loading, error.
- Specify responsive behavior at the smallest and largest supported breakpoint.
- Handle edge cases: empty state, overflow / truncation, maximum content length.
- Include keyboard navigation (Tab, Enter, Escape, Arrow keys where applicable).
- Document ARIA roles, labels, and live-region behavior where relevant.
- Include known page component density: - **Buttons:** 10 detected
- **Links:** 17 detected
- **Inputs:** 1 detected
- **Navigation:** 1 elements
- **Lists:** 5 detected
- **Forms:** 1 detected
- **Images:** 19 detected

## Definition of Done

A component is not complete until every item below is checked:

- Renders correctly in its default state (smoke test).
- All states documented and visually verified (hover, focus, disabled, loading, error, empty).
- All visual values use design tokens — zero hardcoded values.
- Keyboard navigation works without a pointer.
- No critical accessibility violations (contrast, ARIA, focus order).
- Tested at smallest and largest breakpoint.
- Anti-patterns section lists at least one concrete misuse example.
- Documentation covers purpose, usage, props/API, and limitations.
