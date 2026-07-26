"""Brain home - daily second-brain workspace.

One spectacular moment (the constellation), then quiet utility:
continue + recent thoughts. Graph exploration lives on the Graph tab.
"""

sv import from endpoints { GraphNode, GraphLink, SkillView }

import from .palette { cat_color }
import from .Feed { short_date }
import from .MiniConstellation { MiniConstellation }

def:pub RecentRow(item: GraphNode) -> JsxElement {
    tint = cat_color(item.category);
    title = item.label if item.label else item.detail;

    return <article className="recent-row">
        <span className="recent-dot" style={{"background": tint}} aria-hidden="true"></span>
        <span className="recent-body">
            <span className="recent-title">{title}</span>
            <span className="recent-meta">{item.category + " · " + short_date(item.created_at)}</span>
        </span>
    </article>;
}

def:pub BrainHome(
    nodes: list[GraphNode],
    links: list[GraphLink],
    skills: list[SkillView],
    busy: bool,
    onCapture: Callable[[], None],
    onDemo: Callable[[], None],
    onOpenGraph: Callable[[], None]
) -> JsxElement {
    has query: str = "";

    thoughts = [n for n in nodes if n.kind == "thought"];
    total = len(thoughts);
    q = query.strip().lower();

    filtered = thoughts;
    if q {
        filtered = [
            n for n in thoughts
            if q in n.detail.lower() or q in n.label.lower() or q in n.category.lower()
        ];
    }

    ordered = filtered[::-1];
    recent = ordered[:5] if len(ordered) > 5 else ordered;

    strongest = sorted(skills, key=lambda (s: SkillView) -> float { return 0.0 - s.mastery; });
    contName = "";
    contPct = 0.0;
    if len(strongest) > 0 {
        contName = strongest[0].name;
        contPct = strongest[0].mastery * 100.0;
    }

    def onQueryChange(e: any) {
        query = e.target.value;
    }

    def capture(_e: MouseEvent) {
        onCapture();
    }

    def demo(_e: MouseEvent) {
        onDemo();
    }

    def openGraph(_e: MouseEvent) {
        onOpenGraph();
    }

    return <div className="scroll brain-home">
        <header className="brain-top">
            <p className="brain-mark">Neurotech</p>
            <h1 className="greeting">Good afternoon, Mercedes</h1>
            <label className="search-bar">
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor"
                    strokeWidth="1.8" strokeLinecap="round">
                    <circle cx="11" cy="11" r="7"/>
                    <path d="M20 20l-3.5-3.5"/>
                </svg>
                <input
                    className="search-input"
                    placeholder="Search"
                    value={query}
                    onChange={onQueryChange}
                />
            </label>
        </header>

        <MiniConstellation
            nodes={nodes}
            links={links}
            thoughtCount={total}
            skillCount={len(skills)}
            onOpen={openGraph}
        />

        {if total == 0 {
            <div key="empty" className="brain-empty">
                <h2>Nothing captured yet</h2>
                <p>Add a thought and it becomes a node in the constellation.</p>
                <button className="primary-btn" onClick={capture} disabled={busy}>
                    Capture a thought
                </button>
                <button className="text-btn" onClick={demo} disabled={busy}>
                    {"Building…" if busy else "Load demo data"}
                </button>
            </div>
            skip;
        }}

        {if contName {
            <section key="continue" className="home-section">
                <button className="continue-row" onClick={openGraph}>
                    <div className="continue-head">
                        <span className="continue-kicker">Continue</span>
                        <span className="continue-pct">{str(round(contPct)) + "%"}</span>
                    </div>
                    <span className="continue-name">{contName}</span>
                    <div className="bar-track tall">
                        <span className="bar-fill accent" style={{"width": str(contPct) + "%"}}></span>
                    </div>
                </button>
            </section>
        }}

        <section className="home-section">
            <h2 className="section-label">Recent</h2>
            {if len(recent) == 0 {
                <p className="empty-inline">No matches.</p>
                skip;
            }}
            <div className="recent-list">
                {for n in recent {
                    <RecentRow key={n.id} item={n}/>
                }}
            </div>
        </section>
    </div>;
}
