"""Chronological list view - the readable counterpart to the graph."""

sv import from endpoints { GraphNode, GraphLink }

import from .palette { cat_color }

"""Turn an ISO timestamp into something a human reads at a glance."""
def:pub short_date(iso: str) -> str {
    if len(iso) < 16 {
        return "";
    }
    return iso[5:10] + " " + iso[11:16];
}

def:pub ThoughtCard(
    item: GraphNode,
    index: int,
    peers: int,
    builds: list[str],
    onDelete: Callable[[str], None]
) -> JsxElement {
    def handle(_e: MouseEvent) {
        onDelete(item.id);
    }

    tint = cat_color(item.category);

    # Staggered entrance, capped so a long feed doesn't feel sluggish.
    delay = index * 45;
    if delay > 450 {
        delay = 450;
    }

    return <article className="card enter" style={{"animationDelay": str(delay) + "ms"}}>
        <div className="card-top">
            <span className="chip" style={{"background": tint + "26", "color": tint}}>
                {item.category}
            </span>
            <span className="card-meta">{short_date(item.created_at)}</span>
            <button className="card-del" onClick={handle}>Forget</button>
        </div>
        <p className="card-text">{item.detail}</p>
        {if len(builds) > 0 {
            <div className="build-strip">
                {for name in builds {
                    <span key={name} className="build-tag">{name}</span>
                }}
            </div>
        }}
        {if peers > 0 {
            <p className="card-links">
                {"Linked to " + str(peers) + (" thought" if peers == 1 else " thoughts")}
            </p>
        }}
    </article>;
}

def:pub Feed(
    nodes: list[GraphNode],
    links: list[GraphLink],
    onDelete: Callable[[str], None]
) -> JsxElement {
    label: dict[str, str] = {};
    for n in nodes {
        label[n.id] = n.label;
    }

    peers: dict[str, int] = {};
    builds: dict[str, list[str]] = {};
    for l in links {
        if l.kind == "builds" {
            name = label[l.target] if l.target in label else "";
            builds[l.source] = builds[l.source] + [name] if l.source in builds else [name];
        } else {
            peers[l.source] = peers[l.source] + 1 if l.source in peers else 1;
            peers[l.target] = peers[l.target] + 1 if l.target in peers else 1;
        }
    }

    thoughts = [n for n in nodes if n.kind == "thought"];
    ordered = thoughts[::-1];

    return <div className="scroll">
        <p className="section-title">{str(len(thoughts)) + " thoughts"}</p>
        {if len(thoughts) == 0 {
            <p className="card-links">Nothing captured yet.</p>
            skip;
        }}
        {for (i, t) in enumerate(ordered) {
            <ThoughtCard
                key={t.id}
                item={t}
                index={i}
                peers={peers[t.id] if t.id in peers else 0}
                builds={builds[t.id] if t.id in builds else []}
                onDelete={onDelete}
            />
        }}
    </div>;
}
