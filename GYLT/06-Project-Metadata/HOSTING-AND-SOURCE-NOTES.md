# Hosting and source notes

Export prepared: 6 November 2026.

## Source snapshot

- Project: GYLT - You said you would.
- Hosted preview: https://gylt-prototype.stekz-3007.chatgpt.site/
- Source commit: `fd2b94f07b80924c1a197ca1d3e86bc11c92cbe5`
- Source format: static HTML, CSS, JavaScript and SVG.
- Build command: none.
- Static root: `04-Prototype/dist/` within this package (design v2).
- Original v1 static root: `04-Prototype/dist-v1-original/`.
- Original tracked source files: 9.

The six original `dist/` files are reproduced byte for byte under `04-Prototype/dist-v1-original/`, and the original screenshot and `.openai/hosting.json` are unchanged. `SOURCE-MANIFEST.json` records their SHA-256 hashes at those paths. The original README was replaced by the v2 README; its hash in the manifest refers to the export-time version. `04-Prototype/dist/` now holds design v2, made after the export; it has not been committed to the source repository or deployed. Git history, host authentication material and temporary development files are not part of the portable project handoff.

The hosting manifest identifies the already-created Site. It is a provenance reference, not a credential, and is not used when running the local Python server. To deploy a new copy, use a static host with `dist/` as its document root and create that host's own project configuration.

## Reproducing the design

The app uses system fonts and local SVG assets. No external font service, icon package, JavaScript framework or npm dependency is required. The custom coach character and interface icon paths are embedded in `app.js`; the sneaker illustration is in `dist/assets/stride.svg`; the favicon is in `dist/assets/favicon.svg`.

Desktop review controls and the phone frame are part of the same application. Narrow screens use the mobile layout. The app has eight navigable screens; `?view=overview` renders six selected screens. `03-Design/Previews/gylt-screen-overview.jpg` captures the first three v2 overview screens; `04-Prototype/exports/gylt-screen-overview.jpg` is the original v1 capture. It is a review image, not an editable Figma file. Editable visual sources are the CSS, SVG and JavaScript, supported by the design specification and token JSON.

## State and data

Preference persistence uses the browser's local storage under `gylt-concept-v1`; the desktop review theme choice uses `gylt-theme`. Active session state is in memory and is not a production recovery implementation. The app uses a fixed sample evening for parts of its calendar and schedule presentation. Weekly history is illustrative; completion is self-reported.

The prototype contains no AI or paid TTS integration and no key-entry form. Browser speech synthesis depends on the device/browser's available voices and requires user interaction. No other app is blocked, and no native health, camera, microphone or location integration runs.

## Verification and limits

The interactive mockup was previously checked for its main session flow, pause/resume, preservation of elapsed time when switching to the minimum, completion labels, extra-time continuation, protected app settings, provider preview, custom commitment configuration and mobile layout. JavaScript syntax validation passed.

Design v2 was checked in a browser at 375 × 812 in light and dark mode and in the desktop review shell and overview: the full walk flow (start, minimum switch with elapsed time kept, finish sheet, self-reported completion), sheets, tabs and the block screen, with no console errors. `index.html` references `app.css?v=10` and `app.js?v=10` (v10 adds the pixel logo kit) so browsers fetch the new files instead of cached v1 assets; bump the number when the files change.

Export verification compares every source file with the recorded commit, checks the ZIP inventory and integrity, and checks the proposal PDF's layout and text. These checks establish handoff integrity and prototype behavior. They are not native-platform certification, store approval, a formal accessibility audit or evidence of a successful real-world pilot.

## Suggested first engineering action

Read the architecture and roadmap, then validate the restriction/expiry/override contract on one target OS before investing in broad native UI implementation. Preserve the clear separation between user-approved rules and the coach's language generation.

