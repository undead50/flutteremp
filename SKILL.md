---
name: design-system-everest-bank-limited-e
description: >
  Apply the Everest Bank Limited E design system when building or updating UI.
  Use when creating components, choosing colors or typography,
  or reviewing designs for e-commerce interfaces.
---

# Everest Bank Limited E — Design System Skill

## When to Use

- Building new UI components for Everest Bank Limited E.
- Reviewing or updating existing component styles.
- Choosing colors, typography, or spacing for e-commerce pages.
- Checking designs against the extracted token set.

## Context

- **Product:** Everest Bank Limited E — https://omni.ebl-zone.com/
- **Surface:** e-commerce
- **Audience:** Consumers and shoppers
- **Character:** Product-focused shopping experience with a rich, diverse color palette and 3 typefaces.

## Tokens

### Colors

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

### Typography

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

### Spacing

**Base unit:** 4px

`space-1: 3px` · `space-2: 4px` · `space-3: 6px` · `space-4: 7px` · `space-5: 8px` · `space-6: 9px` · `space-7: 10px` · `space-8: 12px` · `space-9: 15px` · `space-10: 16px` · `space-11: 18px` · `space-12: 22px` · `space-13: 24px` · `space-14: 28px` · `space-15: 30px` · `space-16: 33px` · `space-17: 40px` · `space-18: 44px` · `space-19: 67px` · `space-20: 192px` · `space-21: 245px`

### Shapes

**Border radius:** `radius-sm: 3px` · `radius-md: 4px` · `radius-lg: 12px` · `radius-xl: 12px 12px 0px 0px` · `radius-full: 12px 12px 3px 3px` · `radius-6: 14px`

### Elevation

- **shadow-sm:** `rgba(0, 0, 0, 0.04) 0px 4px 8px 0px, rgba(0, 0, 0, 0.06) 0px 16px 48px -10px`
- **shadow-md:** `rgba(0, 0, 0, 0.08) 0px 16px 32px 10px`

### Motion

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

## Component Inventory

- **Buttons:** 10 detected
- **Links:** 17 detected
- **Inputs:** 1 detected
- **Navigation:** 1 elements
- **Lists:** 5 detected
- **Forms:** 1 detected
- **Images:** 19 detected

## Constraints

### Always

- Use tokens from the tables above — do not introduce new values.
- Include hover, focus-visible, and disabled states for interactive elements.
- Follow the 4px spacing grid.
- Meet WCAG 2.2 AA contrast minimums.

### Never

- Do not introduce colors outside the extracted palette.
- Do not use arbitrary spacing values — stick to the scale.
- Do not mix border-radius values. Pin to the detected set (3px, 4px, 12px, 12px 12px 0px 0px, 12px 12px 3px 3px, 14px).
- Do not stack more than one primary CTA per viewport.
- Do not use red for non-error UI — reserve it for destructive actions and warnings.
- Do not ship components without defining hover, focus-visible, and disabled states.

## Tone

Persuasive, benefit-driven, trustworthy. Active voice, urgency without pressure.

## Authoring Workflow

When creating or documenting a component for this system:

1. State intent — one sentence on purpose.
2. Map tokens — list every token the component uses.
3. Define anatomy — named parts with token assignments.
4. Specify states — default, hover, focus-visible, active, disabled, loading, error, empty.
5. Describe interactions — keyboard, pointer, touch, edge cases.
6. Add a11y criteria — testable pass/fail checks.
7. List anti-patterns — concrete misuse examples.
8. Close with the Definition of Done checklist.

## Output Structure

Component guidelines must contain, in order:

1. Overview (purpose, when to use, when not to use)
2. Tokens and foundations
3. Anatomy, variants, responsive behavior
4. States and interactions
5. Accessibility (ARIA, contrast, focus, screen reader)
6. Content guidelines (copy rules, tone)
7. Anti-patterns with reasoning

## Component Requirements

- Reference only tokens from the tables above.
- Define all states: default, hover, focus-visible, active, disabled, loading, error.
- Handle edge cases: empty, overflow, truncation, max content.
- Include keyboard navigation behavior.
- Document ARIA roles and labels.

## Definition of Done

- Default state renders (smoke test).
- All states visually verified.
- Zero hardcoded visual values — tokens only.
- Keyboard navigation works without pointer.
- No critical a11y violations.
- Tested at min and max breakpoint.
- At least one anti-pattern documented.
- Purpose, usage, and limitations documented.
