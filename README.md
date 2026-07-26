# neurotech_ — a second brain that turns memories into a graph

A mobile-first **second brain** built with [Jac](https://www.jaseci.org/).
Drop a thought into the composer and the app categorizes it, links it to
related memories, and renders the whole thing as a living, animated knowledge
graph. Repeated concepts accumulate into **skills** with mastery rings, so you
can watch understanding compound over time.

Built for Jac Hacks.

## What it does

- **Composer** — write a thought in plain language; the server categorizes it
  and auto-links it to semantically related nodes.
- **Brain graph** — an interactive force-directed graph of every thought and
  skill. Pan with momentum, tap a node to glide the camera to it, hit **⛶** to
  auto-fit. Edges are bezier curves whose opacity encodes link weight; skill
  nodes wear a mastery progress ring.
- **Feed** — a reverse-chronological stream of thoughts with staggered
  entrances and optimistic submit (the node appears instantly and the server
  reconciles in the background).
- **Skills** — concepts the app has seen repeatedly, each with a rep count and
  a mastery target. Skill edges are accent-tinted in the graph.
- **Node sheet & confirm dialog** — bottom-sheet detail view for any node and a
  reusable confirmation flow for destructive actions.

## Stack

- **Jac** `==0.34.7` — both the server (object-spatial brain in
  `endpoints.sv.jac`) and the client (React components in `components/*.cl.jac`).
- **React 18** + **TypeScript** + **Vite** — client render pipeline, wired
  through Jac's `cl` blocks.
- No external graph library — the camera engine, force layout, and animations
  are hand-rolled for a premium feel.

## Project layout

```
main.jac              # entry point: imports server, mounts client shell
endpoints.sv.jac      # server: Thought/Link/Skill nodes, create/delete, load
frontend.cl.jac       # client shell: tabs, state, handlers
frontend.impl.jac     # client impl: optimistic submit, server calls
components/
  BrainGraph.cl.jac   # graph canvas, camera engine, animated edges/rings
  Composer.cl.jac     # thought input
  Feed.cl.jac         # chronological feed
  Skills.cl.jac       # skills list
  NodeSheet.cl.jac    # bottom-sheet node detail
  ConfirmDialog.cl.jac
  CategoryLegend.cl.jac
  TabBar.cl.jac
  palette.cl.jac      # shared color tokens
global.css            # design system: tokens, animations, skeletons
```

## Run it

Requires the Jac CLI (`pip install jaclang`).

```bash
jac start --dev main.jac
```

Then open `http://localhost:8003/` (or whichever port `jac start` reports).

## Validate

```bash
jac check main.jac      # type-check + lint
```

## Notes

- Thought creation is **optimistic**: the composer closes and the node appears
  immediately, with rollback + error toast if the server call fails.
- The graph camera uses a single shared `requestAnimationFrame` driver for
  both pan inertia and glide-to-node, so any touch instantly cancels in-flight
  animations.
- QA was done with `jac browse` (headless browser snapshots + screenshots).

_Generated with [Devin](https://devin.ai)._
