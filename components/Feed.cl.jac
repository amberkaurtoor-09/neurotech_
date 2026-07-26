"""Chronological list view - the readable counterpart to the graph."""

sv import from endpoints { ThoughtView, LinkView }

import from .palette { cat_color }

"""Turn an ISO timestamp into something a human reads at a glance."""
def:pub short_date(iso: str) -> str {
    if len(iso) < 16 {
        return "";
    }
    return iso[5:10] + " " + iso[11:16];
}

def:pub ThoughtCard(
    thought: ThoughtView,
    connections: int,
    onDelete: Callable[[str], None]
) -> JsxElement {
    def handle(_e: MouseEvent) {
        onDelete(thought.id);
    }

    tint = cat_color(thought.category);

    return <article className="card">
        <div className="card-top">
            <span className="chip" style={{"background": tint + "26", "color": tint}}>
                {thought.category}
            </span>
            <span className="card-meta">{short_date(thought.created_at)}</span>
            <button className="card-del" onClick={handle}>Forget</button>
        </div>
        <p className="card-text">{thought.content}</p>
        {if connections > 0 {
            <p className="card-links">
                {"Linked to " + str(connections) + (" thought" if connections == 1 else " thoughts")}
            </p>
        }}
    </article>;
}

def:pub Feed(
    thoughts: list[ThoughtView],
    links: list[LinkView],
    onDelete: Callable[[str], None]
) -> JsxElement {
    degree: dict[str, int] = {};
    for l in links {
        degree[l.source] = degree[l.source] + 1 if l.source in degree else 1;
        degree[l.target] = degree[l.target] + 1 if l.target in degree else 1;
    }

    ordered = thoughts[::-1];

    return <div className="scroll">
        <p className="section-title">{str(len(thoughts)) + " thoughts"}</p>
        {if len(thoughts) == 0 {
            <p className="card-links">Nothing captured yet.</p>
            skip;
        }}
        {for t in ordered {
            <ThoughtCard
                key={t.id}
                thought={t}
                connections={degree[t.id] if t.id in degree else 0}
                onDelete={onDelete}
            />
        }}
    </div>;
}
