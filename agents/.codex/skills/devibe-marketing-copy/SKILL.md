---
name: devibe-marketing-copy
description: Improve vague, generic, buzzword-heavy, or “vibe-coded” marketing-site copy through a temporary interactive browser review flow. Use when Codex should inspect a website, draft 5–10 lettered alternatives for each visible copy block, let the user swap choices live in movable viewport-aware popovers, produce a copyable selection handoff, then bake the chosen wording into the site and completely remove the temporary picker.
---

# Devibe Marketing Copy

Turn copy review into a reversible two-phase workflow: interactive selection first, permanent cleanup after the user returns the generated choice list.

## 1. Inspect and define scope

- Read repository instructions and inspect the site structure, package manager, current worktree, and existing preview setup.
- Preserve unrelated changes. Never overwrite another agent’s work.
- Identify visible marketing copy blocks: hero headings and ledes, section headings, calls to action, captions, feature titles, and explanatory paragraphs.
- Exclude navigation, legal text, image alt text, metadata, and functional UI labels unless the user asks to review them.
- Treat the request for an interactive review as authorization to run a local preview. Reuse an existing server when possible; otherwise bind a minimal server to `127.0.0.1` on an available port. Do not expose it to the network.

## 2. Write alternatives

- Keep the exact existing wording as option A.
- Provide 5 options by default and never fewer than 5 or more than 10.
- Label options sequentially A–J.
- Preserve factual meaning and product constraints. Do not invent features, outcomes, compatibility, privacy claims, or availability.
- Prefer specific subjects and verbs, plain language, and short sentences. Remove empty intensifiers, generic transformation language, canned contrasts, and unsupported superlatives.
- Make alternatives meaningfully different, not shallow synonym swaps. Vary emphasis or structure while keeping the same claim.
- Preserve required inline markup such as `<code>`, `<em>`, and intentional line breaks.

## 3. Install the temporary picker

Copy [assets/devibe-picker.css](assets/devibe-picker.css) and [assets/devibe-picker.js](assets/devibe-picker.js) into the site’s public asset location. Use conspicuous temporary names so removal is reliable.

Adapt the page or component with:

1. A unique `data-devibe-key="..."` on each selectable copy block.
2. A temporary stylesheet reference.
3. A `window.__DEVIBE_COPY__` object before the picker script:

```html
<script>
  window.__DEVIBE_COPY__ = {
    "hero-title": {
      label: "Hero title",
      options: [
        "Current headline",
        "Alternative headline",
        "...at least five total..."
      ]
    }
  };
</script>
<script src="devibe-picker.js" defer></script>
```

- For frameworks, express the same data and behavior idiomatically rather than forcing inline globals when CSP or hydration makes them unsuitable.
- Keep all review code isolated from production behavior and easy to delete.
- Do not add dependencies for this temporary UI.

## 4. Verify and hand off

- Run syntax, formatting, lint, or type checks appropriate to the changed files. Do not run a full build unless needed for verification or explicitly requested.
- Open the local page with the available browser-control skill when possible.
- Verify that every marked block has 5–10 options, selecting an option changes the visible copy, the output updates, and no console errors occur.
- Verify both panels can be dragged. Confirm the choice popover opens at the target’s top-right by default, flips or clamps inside narrow viewports, and remains usable with keyboard input.
- Leave the preview open and give the user its local URL. Ask them to return the full text from the “Copy choices” box.
- Stop after this phase. Do not guess the user’s choices.

## 5. Apply the returned choices

When the user returns lines shaped like `key: C — Selected phrase`:

- Treat the letter as authoritative and cross-check the supplied phrase against that option.
- Replace the source copy while preserving the chosen inline markup.
- Remove every temporary marker, config object, stylesheet/script reference, and copied picker asset.
- Search the repository for `devibe`, `data-devibe-key`, and `__DEVIBE_COPY__`; no temporary review hooks may remain.
- Reload the preview and verify the chosen copy, valid structure, and absence of console errors.
- Keep the local server running unless the user asks to stop it.
- Commit or push only when explicitly requested.

## Recovery

- If the user changes scope during review, update only the affected option set and preserve their other selections when feasible.
- If the page cannot be served or controlled in a browser, complete static validation and state the exact unverified interaction rather than claiming visual success.
- If existing site architecture makes the bundled assets unsuitable, reproduce the same interaction contract with the site’s native components and keep it equally removable.
