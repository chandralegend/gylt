# GYLT - Complete project handoff

**GetYourLifeTogether**  
Concept, proposal, design and runnable prototype  
Prepared: 6 November 2026

GYLT is an unapologetic accountability coach for the moment a good intention is about to lose to an easier distraction. The concept combines direct AI voice coaching with user-approved, bounded distraction controls. This package contains the work produced so far and a proposed path from the browser mockup to a native product.

## Start here

1. Read **[the project proposal](01-Product/PROJECT-PROPOSAL.pdf)** for the product case, proposed scope and validation plan. The [editable Markdown version](01-Product/PROJECT-PROPOSAL.md) contains the same proposal text.
2. Open **[the screen preview](03-Design/Previews/gylt-screen-overview.jpg)** for the visual direction.
3. Run **[the interactive prototype](04-Prototype/README.md)** using the instructions below.
4. Use the requirements, architecture, roadmap and design specification to plan implementation.

The existing hosted prototype is at **https://gylt-prototype.stekz-3007.chatgpt.site/**. Access remains governed by that Site's existing settings. The ZIP can be run locally without access to the hosted Site.

## What is included

| Folder / file | Contents |
| --- | --- |
| `01-Product/PROJECT-PROPOSAL.pdf` | Formatted, shareable project proposal |
| `01-Product/PROJECT-PROPOSAL.md` | Editable proposal source |
| `01-Product/PRODUCT-REQUIREMENTS.md` | MVP requirements, acceptance criteria and measurement plan |
| `01-Product/CONCEPT-AND-DECISION-LOG.md` | Confirmed direction, recommendations and open decisions |
| `02-Engineering/TECHNICAL-ARCHITECTURE.md` | Native architecture, state model, BYOK, voice and enforcement boundaries |
| `02-Engineering/DEVELOPMENT-ROADMAP.md` | Phased build plan with release gates |
| `03-Design/DESIGN-SPECIFICATION.md` | Screen map, visual system, interaction guidance and adaptation notes |
| `03-Design/design-tokens.json` | Machine-readable values derived from the current mockup |
| `03-Design/Logo-Meadow/` | **Current logo**: the doorway mark and round-stroked wordmark, with SVG, PNG and PDF files, app icon, social card and guidelines |
| `03-Design/Logo-Kit/` | (Earlier pixel logo, kept for reference) |
| `03-Design/Logo-Kit/` | Final logo kit: pixel coach and GYLT wordmark (SVG, PNG), lockups, reversed and one-colour versions, web icons, presentation board, [usage guidelines](03-Design/Logo-Kit/GUIDELINES.md) and the generator script |
| `03-Design/Previews/gylt-screen-overview.jpg` | Screenshot of three key screens in design v2: Today, intervention and app block |
| `04-Prototype/dist/` | The runnable prototype, design v2: HTML, CSS, JavaScript, original SVG artwork, favicon and preview page |
| `04-Prototype/dist-v1-original/` | The original v1 prototype, unchanged from the source commit, for comparison |
| `04-Prototype/` (other files) | README, original hosting manifest and the original v1 screenshot in `exports/` |
| `05-Research/REFERENCES.md` | Design, competitor, platform and voice references, with usage notes |
| `06-Project-Metadata/HOSTING-AND-SOURCE-NOTES.md` | Snapshot provenance, portability notes and known limitations |
| `06-Project-Metadata/SOURCE-MANIFEST.json` | Original source commit and SHA-256 comparison data |
| `06-Project-Metadata/PACKAGE-MANIFEST.json` | Inventory and SHA-256 hashes for the handoff files |
| `06-Project-Metadata/build_proposal_pdf.py` | Optional script to regenerate the proposal PDF from its Markdown source |

### Design v2

The prototype was redesigned after the original export, following the Appllama app-design skill: the iOS type ramp in place of 8–10 px labels, a single coral accent and one warm grey family, a stated corner-radius rule, 44 px controls, light and dark mode, a session screen with large numerals and round controls, one label per intent, and quieter motion. The flow, copy voice, artwork and prototype boundaries are unchanged. One behaviour was added: an active session can switch back from the minimum to the full walk, keeping elapsed time, as the architecture requires. See [the design specification](03-Design/DESIGN-SPECIFICATION.md) for the full before-and-after.

The v1 screenshot remains in `04-Prototype/exports/`; the preview in the design folder shows v2.

## Run the prototype locally

Requirements: a current browser and Python 3. There is **no build step, package install, API key or paid service required**.

1. Extract the ZIP.
2. Open a terminal in the extracted `GYLT/04-Prototype` folder.
3. Run:

```bash
python3 -m http.server 8000 --bind 127.0.0.1 --directory dist
```

On Windows, use `py -m http.server 8000 --bind 127.0.0.1 --directory dist` if `python3` is not available.

4. Open **http://localhost:8000/** in your browser.
5. Stop the server with **Ctrl+C** when finished.

Useful views:

| URL | What it opens |
| --- | --- |
| `http://localhost:8000/` | Interactive app with desktop review controls, or a full mobile viewport |
| `http://localhost:8000/?view=overview` | Six-screen visual overview |
| `http://localhost:8000/?screen=coach` | Persona, tone, voice and provider setup concept |
| `http://localhost:8000/?screen=blocked` | Simulated distraction block |
| `http://localhost:8000/mobile-preview.html` | Isolated 390 x 844 mobile preview |

Use an HTTP server as above rather than opening `index.html` as a local file, so browser storage and navigation behave consistently. To reset the demo fully, clear this localhost site's browser storage. The demo preference key is `gylt-concept-v1`; the review theme choice is `gylt-theme`. To see the original design, serve `dist-v1-original` instead of `dist`.

## A short review walkthrough

Start the evening walk from Today. Choose the full commitment or the minimum, begin the timer, pause and resume, then switch to the minimum and back to the full walk while preserving elapsed time. Finish with a self-reported result and try the extra five minutes. Review the app-block screen, the change-plan options, protected app selection, personas, tone and device voice. Use the Light/Dark button in the desktop header to check both themes.

There are eight navigable screens. The overview displays six selected screens; the preview JPEG shows three. Some screens scroll inside the phone frame.

## What works in this version

Browser navigation, a foreground session timer, pause/resume, switching between the full walk and the minimum with elapsed time kept, light and dark mode, honest full/minimum completion labels, explicit pause/reschedule/override choices, protected app selection, custom commitment configuration, tone/persona choices and preference persistence. Device speech is available where the browser supports speech synthesis and after the user interacts with it.

## What is still proposed

Native app restrictions, reliable scheduled interventions, persistent session recovery, absolute restriction expiry, sensor-backed evidence, real AI/TTS provider connections, secure key storage, billing and production analytics. Coach copy is scripted, provider setup is illustrative, and progress history contains sample data. No API keys are collected or sent by this prototype. No health, camera, microphone or location data is collected.

The documents distinguish confirmed product direction from recommendations. Launch platform, pricing, timeline, target segment and voice rights have not been approved. The roadmap is a sequence of work and decision gates, not a delivery commitment.

## Source and handoff status

`04-Prototype/dist-v1-original/` matches source commit `fd2b94f07b80924c1a197ca1d3e86bc11c92cbe5` byte for byte. `04-Prototype/dist/` is design v2, made after the export and not yet committed to that source or deployed. The existing hosted Site was not changed and still shows v1. The archive contains the source files and original assets, with no dependency on a source-host account or repository history to run locally.

Project documents are editable Markdown; design tokens are JSON; artwork is SVG. The original hosting manifest is included as a reference to the current project. For a new deployment, configure a new host to serve `04-Prototype/dist` and create its own project settings.

To regenerate the PDF after editing the proposal, install ReportLab in your authoring environment (`python3 -m pip install reportlab`) and run `python3 06-Project-Metadata/build_proposal_pdf.py` from the `GYLT` folder. This optional document-authoring dependency is not needed to run the app.

