"""Neurotech - Server-Side Data Layer.

A second brain is literally a graph, so it is stored as one. Each captured
thought is a `Thought` node hanging off `root`; semantic relatedness between
two thoughts is a typed `Link` edge carrying a weight. Nothing here is a
table -- the brain IS the graph, and the UI draws it directly.

`LoadBrain` is a real walker: it traverses out from root, gathers every
thought it enters, and reports the assembled view once on the way out.
Creation and deletion are `def:pub` functions -- they touch the graph but
never traverse it, so per `jac-walker-patterns` they would be "RPC in walker
costume" as walkers.

Everything is `:pub` for now, meaning one shared `root` and no login. Switch
to `:priv` to give every signed-in user their own isolated brain.
"""

import math;
import from datetime { datetime }

glob CANVAS: float = 1000.0;

glob CATEGORIES: list[str] = [
    "idea", "memory", "goal", "learning", "health", "reflection"
];

glob KEYWORDS: dict[str, list[str]] = {
    "goal": ["goal", "want to", "plan to", "by next", "deadline", "ship", "launch", "finish"],
    "memory": ["remember", "yesterday", "last week", "back when", "reminded me", "we met"],
    "learning": ["learned", "read that", "turns out", "til", "discovered", "figured out"],
    "health": ["sleep", "slept", "workout", "run", "ran", "gym", "ate", "tired", "anxious"],
    "reflection": ["i feel", "i think", "wonder", "grateful", "realized", "lately"],
    "idea": ["what if", "idea", "could build", "concept", "imagine"]
};

node Thought {
    has content: str,
        category: str = "idea",
        created_at: str = "",
        strength: int = 1;
}

edge Link: Thought --> Thought {
    has weight: float = 0.5;
}

obj ThoughtView {
    has id: str,
        content: str,
        category: str,
        created_at: str,
        strength: int,
        x: float = 0.0,
        y: float = 0.0;
}

obj LinkView {
    has source: str,
        target: str,
        weight: float;
}

obj BrainView {
    has thoughts: list[ThoughtView] = [],
        links: list[LinkView] = [];
}

"""Project a graph node into a wire-safe view the client can render."""
def to_view(t: Thought, x: float = 0.0, y: float = 0.0) -> ThoughtView {
    return ThoughtView(
        id=jid(t),
        content=t.content,
        category=t.category,
        created_at=t.created_at,
        strength=t.strength,
        x=x,
        y=y
    );
}

"""Lowercase the text down to space-delimited words, padded on both ends.

Padding lets a keyword be matched on word boundaries with a plain `in`, so
"ate" no longer fires on "gr-ate-ful" the way a raw substring search does.
"""
def normalize(text: str) -> str {
    words: list[str] = [];
    for raw in text.lower().split() {
        w = raw.strip(".,!?;:'\"()[]");
        if w {
            words.append(w);
        }
    }
    return " " + " ".join(words) + " ";
}

"""Assign a category by whole-word keyword match; defaults to 'idea'."""
def classify(text: str) -> str {
    low = normalize(text);
    for (cat, words) in KEYWORDS.items() {
        for w in words {
            if f" {w} " in low {
                return cat;
            }
        }
    }
    return "idea";
}

"""Content words of a thought, used for relatedness scoring."""
def tokens(text: str) -> set[str] {
    stop = {
        "this", "that", "with", "from", "have", "been", "were", "they",
        "them", "then", "than", "what", "when", "your", "about", "would",
        "could", "should", "there", "their", "which", "into", "just", "like"
    };
    out: set[str] = set();
    for raw in text.lower().split() {
        w = raw.strip(".,!?;:'\"()[]");
        if len(w) > 3 and w not in stop {
            out.add(w);
        }
    }
    return out;
}

"""Jaccard overlap of two thoughts' content words, 0.0 - 1.0."""
def similarity(a: str, b: str) -> float {
    ta = tokens(a);
    tb = tokens(b);
    if not ta or not tb {
        return 0.0;
    }
    union = len(ta | tb);
    if union == 0 {
        return 0.0;
    }
    return len(ta & tb) / union;
}

"""Capture a thought, auto-categorize it, and wire it to related ones.

The auto-linking is the whole point: the user never draws an edge, so the
brain assembles its own structure as thoughts accumulate.
"""
def:pub create_thought(content: str, category: str = "") -> ThoughtView {
    text = content.strip();
    if not text {
        return ThoughtView(id="", content="", category="idea", created_at="", strength=0);
    }

    existing = [root -->[?:Thought]];
    cat = category if category in CATEGORIES else classify(text);

    fresh = root ++> Thought(
        content=text,
        category=cat,
        created_at=datetime.now().isoformat(),
        strength=1
    );

    for other in existing {
        score = similarity(text, other.content);
        if score >= 0.12 {
            fresh +>:Link(weight=score):+> other;
            other.strength = other.strength + 1;
        }
    }

    return to_view(fresh);
}

"""Force-directed layout over a 1000x1000 space.

Deterministic on purpose: seeded by phyllotaxis rather than an RNG, so the
same brain lays out identically on every load and neurons don't teleport
between refreshes. Linked thoughts pull together, everything else pushes
apart, and gravity keeps the cluster centered.
"""
def layout(ids: list[str], links: list[LinkView]) -> dict[str, list[float]] {
    pos: dict[str, list[float]] = {};
    n = len(ids);
    center = CANVAS / 2.0;

    if n == 0 {
        return pos;
    }
    if n == 1 {
        pos[ids[0]] = [center, center];
        return pos;
    }

    spread = CANVAS * 0.30;
    for (i, tid) in enumerate(ids) {
        angle = 2.399963 * i;
        r = spread * math.sqrt((i + 1.0) / n);
        pos[tid] = [center + r * math.cos(angle), center + r * math.sin(angle)];
    }

    repel = CANVAS * CANVAS * 0.055;
    rest = CANVAS * 0.16;
    margin = CANVAS * 0.09;
    steps = 240;

    for step in range(steps) {
        cool = 1.0 - (step / steps);
        push: dict[str, list[float]] = {};
        for tid in ids {
            push[tid] = [0.0, 0.0];
        }

        for i in range(n) {
            for j in range(i + 1, n) {
                a = ids[i];
                b = ids[j];
                dx = pos[a][0] - pos[b][0];
                dy = pos[a][1] - pos[b][1];
                d2 = dx * dx + dy * dy;
                if d2 < 1.0 {
                    dx = 1.0 + i;
                    dy = 1.0 + j;
                    d2 = dx * dx + dy * dy;
                }
                d = math.sqrt(d2);
                f = repel / d2;
                ux = dx / d;
                uy = dy / d;
                push[a][0] = push[a][0] + ux * f;
                push[a][1] = push[a][1] + uy * f;
                push[b][0] = push[b][0] - ux * f;
                push[b][1] = push[b][1] - uy * f;
            }
        }

        for l in links {
            if l.source in pos and l.target in pos {
                dx = pos[l.target][0] - pos[l.source][0];
                dy = pos[l.target][1] - pos[l.source][1];
                d = math.sqrt(dx * dx + dy * dy);
                if d > 0.001 {
                    f = (d - rest) * (0.6 + l.weight);
                    ux = dx / d;
                    uy = dy / d;
                    push[l.source][0] = push[l.source][0] + ux * f;
                    push[l.source][1] = push[l.source][1] + uy * f;
                    push[l.target][0] = push[l.target][0] - ux * f;
                    push[l.target][1] = push[l.target][1] - uy * f;
                }
            }
        }

        cap = CANVAS * 0.05 * cool + 0.5;
        for tid in ids {
            vx = (push[tid][0] + (center - pos[tid][0]) * 0.035) * 0.016;
            vy = (push[tid][1] + (center - pos[tid][1]) * 0.035) * 0.016;
            mag = math.sqrt(vx * vx + vy * vy);
            if mag > cap {
                vx = vx / mag * cap;
                vy = vy / mag * cap;
            }
            pos[tid] = [
                max(margin, min(CANVAS - margin, pos[tid][0] + vx)),
                max(margin, min(CANVAS - margin, pos[tid][1] + vy))
            ];
        }
    }

    return pos;
}

"""Forget a thought. Deleting the node cascades to all of its links."""
def:pub delete_thought(id: str) -> bool {
    target = jobj(id);
    if isinstance(target, Thought) {
        del target;
        return True;
    }
    return False;
}

walker:pub LoadBrain {
    """Traverse the brain and report its nodes plus its edges as one view."""

    has found: list[Thought] = [],
        reports: list[BrainView] = [];

    can start with Root entry {
        visit [-->[?:Thought]];
    }

    can gather with Thought entry {
        self.found.append(here);
    }

    can assemble with Root exit {
        links: list[LinkView] = [];
        ids: list[str] = [];

        for t in self.found {
            ids.append(jid(t));
            for other in [t ->:Link:->] {
                weight = 0.5;
                for e in [edge t ->:Link:-> other] {
                    weight = e.weight;
                }
                links.append(
                    LinkView(source=jid(t), target=jid(other), weight=weight)
                );
            }
        }

        pos = layout(ids, links);
        thoughts: list[ThoughtView] = [];

        for t in self.found {
            tid = jid(t);
            px = CANVAS / 2.0;
            py = CANVAS / 2.0;
            if tid in pos {
                px = pos[tid][0];
                py = pos[tid][1];
            }
            thoughts.append(to_view(t, px, py));
        }

        report BrainView(thoughts=thoughts, links=links);
    }
}
