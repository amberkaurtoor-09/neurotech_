"""Hero constellation for the Brain home.

A compact, breathing projection of the real graph — the one spectacular
moment. Tapping opens the full Graph tab.
"""

sv import from endpoints { GraphNode, GraphLink }

import from .palette { cat_color }
import from .BrainGraph { edge_path }

def:pub MiniConstellation(
    nodes: list[GraphNode],
    links: list[GraphLink],
    thoughtCount: int,
    skillCount: int,
    onOpen: Callable[[MouseEvent], None]
) -> JsxElement {
    # Prefer a mixed handful: skills as hubs, thoughts as satellites.
    skills = [n for n in nodes if n.kind == "skill"];
    thoughts = [n for n in nodes if n.kind == "thought"];
    pick: list[GraphNode] = [];
    for s in skills {
        if len(pick) >= 4 {
            break;
        }
        pick = pick + [s];
    }
    for t in thoughts {
        if len(pick) >= 14 {
            break;
        }
        pick = pick + [t];
    }

    ids: dict[str, bool] = {};
    for n in pick {
        ids[n.id] = True;
    }

    edges = [l for l in links if l.source in ids and l.target in ids];
    # Cap filaments so the hero stays airy.
    if len(edges) > 18 {
        edges = edges[:18];
    }

    min_x = 1.0e9;
    min_y = 1.0e9;
    max_x = -1.0e9;
    max_y = -1.0e9;
    for n in pick {
        if n.x < min_x {
            min_x = n.x;
        }
        if n.y < min_y {
            min_y = n.y;
        }
        if n.x > max_x {
            max_x = n.x;
        }
        if n.y > max_y {
            max_y = n.y;
        }
    }

    pad = 48.0;
    span_x = max_x - min_x;
    span_y = max_y - min_y;
    if span_x < 80.0 {
        span_x = 80.0;
    }
    if span_y < 80.0 {
        span_y = 80.0;
    }

    vw = 360.0;
    vh = 280.0;
    sx = (vw - pad * 2.0) / span_x;
    sy = (vh - pad * 2.0) / span_y;
    scale = sx if sx < sy else sy;

    pos_x: dict[str, float] = {};
    pos_y: dict[str, float] = {};
    for n in pick {
        pos_x[n.id] = pad + (n.x - min_x) * scale;
        pos_y[n.id] = pad + (n.y - min_y) * scale;
    }

    caption = str(thoughtCount) + " thoughts · " + str(skillCount) + " skills linked";
    empty = len(pick) == 0;

    return <button className="constellation" onClick={onOpen} aria-label="Open graph">
        <div className="constellation-void">
            {if empty {
                <svg key="empty" className="constellation-svg" viewBox="0 0 360 280" aria-hidden="true">
                    <circle className="c-node breath" cx="120" cy="130" r="4"/>
                    <circle className="c-node breath d2" cx="200" cy="100" r="6"/>
                    <circle className="c-node breath d3" cx="250" cy="170" r="3.5"/>
                    <circle className="c-node breath d1" cx="160" cy="190" r="3"/>
                    <path className="c-edge breath" d="M120 130 Q170 90 200 100"/>
                    <path className="c-edge breath d2" d="M200 100 Q240 140 250 170"/>
                    <path className="c-edge breath d3" d="M120 130 Q140 180 160 190"/>
                </svg>
            } else {
                <svg key="live" className="constellation-svg" viewBox={"0 0 " + str(vw) + " " + str(vh)} aria-hidden="true">
                    {for (i, l) in enumerate(edges) {
                        <path
                            key={l.source + "-" + l.target}
                            className={"c-edge breath d" + str(i % 4)}
                            d={edge_path(pos_x[l.source], pos_y[l.source], pos_x[l.target], pos_y[l.target])}
                            fill="none"
                        />
                    }}
                    {for (i, n) in enumerate(pick) {
                        skill = n.kind == "skill";
                        r = 6.5 if skill else (3.2 + n.strength * 0.35);
                        if r > 5.5 and not skill {
                            r = 5.5;
                        }
                        <g key={n.id} className={"c-mark breath d" + str(i % 4)}>
                            {if skill {
                                <circle
                                    key="halo"
                                    className="c-halo"
                                    cx={pos_x[n.id]}
                                    cy={pos_y[n.id]}
                                    r={r * 2.2}
                                />
                            }}
                            <circle
                                className={"c-node hub" if skill else "c-node"}
                                cx={pos_x[n.id]}
                                cy={pos_y[n.id]}
                                r={r}
                                fill={("#5B8CFF" if skill else cat_color(n.category))}
                            />
                        </g>
                    }}
                </svg>
            }}
            <div className="constellation-fog" aria-hidden="true"></div>
        </div>
        <p className="constellation-caption">{caption if not empty else "Your mind, mapped"}</p>
    </button>;
}
