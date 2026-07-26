"""What the shape of the graph says about you.

Everything here is derived from the graph the user already has - no extra
storage, no separate analytics model.
"""

sv import from endpoints { ThoughtView, LinkView }

import from .palette { categories, cat_color }

def:pub Bar(name: str, count: int, total: int) -> JsxElement {
    pct = 0.0 if total == 0 else count / total * 100.0;

    return <div className="bar-row">
        <span className="bar-name">{name}</span>
        <span className="bar-track">
            <span
                className="bar-fill"
                style={{"width": str(pct) + "%", "background": cat_color(name)}}
            ></span>
        </span>
        <span className="bar-val">{str(count)}</span>
    </div>;
}

def:pub Insights(thoughts: list[ThoughtView], links: list[LinkView]) -> JsxElement {
    counts: dict[str, int] = {};
    for t in thoughts {
        counts[t.category] = counts[t.category] + 1 if t.category in counts else 1;
    }

    total = len(thoughts);
    linked: set[str] = set();
    for l in links {
        linked.add(l.source);
        linked.add(l.target);
    }
    isolated = total - len(linked);

    densest = "-";
    best = 0;
    for t in thoughts {
        if t.strength > best {
            best = t.strength;
            densest = t.content;
        }
    }

    return <div className="scroll">
        <p className="section-title">Overview</p>
        <div className="stat-grid">
            <div className="stat">
                <div className="stat-num">{str(total)}</div>
                <div className="stat-lbl">Thoughts</div>
            </div>
            <div className="stat">
                <div className="stat-num">{str(len(links))}</div>
                <div className="stat-lbl">Connections</div>
            </div>
            <div className="stat">
                <div className="stat-num">{str(len(linked))}</div>
                <div className="stat-lbl">Connected</div>
            </div>
            <div className="stat">
                <div className="stat-num">{str(isolated)}</div>
                <div className="stat-lbl">Floating alone</div>
            </div>
        </div>

        <p className="section-title">By category</p>
        {for name in categories() {
            <Bar
                key={name}
                name={name}
                count={counts[name] if name in counts else 0}
                total={total}
            />
        }}

        {if total > 0 {
            <p className="section-title">Strongest hub</p>
            <div className="card">
                <p className="card-text">{densest}</p>
                <p className="card-links">
                    {"Pulled in by " + str(best - 1) + " other thoughts" if best > 1
                     else "Nothing links here yet"}
                </p>
            </div>
        }}
    </div>;
}
