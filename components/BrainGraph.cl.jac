"""The graph view - Obsidian's map, sized for a thumb.

Two node kinds share one canvas: thoughts (small, coloured by category) and
skills (larger, ringed, always labelled). Tapping a node focuses it - its
neighbours stay lit, everything else dims - which is how you actually read a
graph on a 375px screen, where showing every label at once is noise.

Positions arrive precomputed from the server walker, so this component is
pure rendering: no layout maths, no animation loop.
"""

sv import from endpoints { GraphNode, GraphLink }

import from .palette { cat_color, node_radius }

"""Clip a label to something that fits beside a node on a phone."""
def:pub trim(text: str, limit: int) -> str {
    if len(text) <= limit {
        return text;
    }
    return text[:limit].strip() + "...";
}

def:pub GraphNodeMark(
    item: GraphNode,
    dim: bool,
    lit: bool,
    labelled: bool,
    onPick: Callable[[str], None]
) -> JsxElement {
    def handle(_e: MouseEvent) {
        onPick(item.id);
    }

    skill = item.kind == "skill";
    color = "#c9d1ff" if skill else cat_color(item.category);
    r = node_radius(item.kind, item.strength);

    klass = "gnode";
    if dim {
        klass = "gnode dim";
    }
    if lit {
        klass = "gnode lit";
    }

    return <g className={klass} onClick={handle}>
        {if lit {
            <circle className="gnode-glow" cx={item.x} cy={item.y} r={r * 2.4} fill={color}/>
        }}
        <circle
            className={"gnode-core skill" if skill else "gnode-core"}
            cx={item.x}
            cy={item.y}
            r={r}
            fill={"#171a2e" if skill else color}
            stroke={color}
            strokeWidth={4.0 if skill else 0.0}
        />
        {if labelled {
            <text
                className={"glabel skill" if skill else "glabel"}
                x={item.x}
                y={item.y + r + 26}
                textAnchor="middle"
                fill={color}
            >
                {trim(item.label, 17 if skill else 22)}
            </text>
        }}
    </g>;
}

def:pub BrainGraph(
    nodes: list[GraphNode],
    links: list[GraphLink],
    hidden: list[str],
    focus: str,
    onPick: Callable[[str], None],
    onClear: Callable[[], None]
) -> JsxElement {
    def clear(_e: MouseEvent) {
        onClear();
    }

    visible = [n for n in nodes if n.kind == "skill" or n.category not in hidden];

    at: dict[str, GraphNode] = {};
    for n in visible {
        at[n.id] = n;
    }

    shown = [l for l in links if l.source in at and l.target in at];

    # Neighbourhood of the focused node, so focus lights a whole cluster.
    # `focused` is tracked as its own bool rather than testing `len(near)`:
    # len() of a dict compiles to `undefined` in the browser, so the guard
    # silently never fires and no highlight class is ever applied.
    near: dict[str, bool] = {};
    focused = False;

    if focus and focus in at {
        near[focus] = True;
        focused = True;
        for l in shown {
            if l.source == focus {
                near[l.target] = True;
            }
            if l.target == focus {
                near[l.source] = True;
            }
        }
    }

    return <svg
        className="graph-svg"
        viewBox="0 0 1000 1700"
        preserveAspectRatio="xMidYMid meet"
    >
        <rect x="0" y="0" width="1000" height="1700" fill="transparent" onClick={clear}/>

        {for (i, l) in enumerate(shown) {
            <line
                key={"l" + str(i)}
                className={"glink lit" if focused and l.source in near and l.target in near
                           else ("glink dim" if focused else "glink")}
                x1={at[l.source].x}
                y1={at[l.source].y}
                x2={at[l.target].x}
                y2={at[l.target].y}
                strokeWidth={2.6 if l.kind == "builds" else 1.2 + l.weight * 2.4}
                strokeDasharray={"7 6" if l.kind == "builds" else "0"}
            />
        }}

        {for n in visible {
            <GraphNodeMark
                key={n.id}
                item={n}
                dim={focused and n.id not in near}
                lit={focused and n.id == focus}
                labelled={n.kind == "skill" or (focused and n.id in near)}
                onPick={onPick}
            />
        }}
    </svg>;
}
