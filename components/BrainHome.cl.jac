"""Brain home - futuristic first tab.

Hero is the brain visual (teammate art at assets/brain.png). Recent
thoughts sit below. Tap the brain to open the Graph tab.
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
    has query: str = "",
        useFallback: bool = False;

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
    recent = ordered[:8] if len(ordered) > 8 else ordered;

    caption = str(total) + " thoughts · " + str(len(skills)) + " skills";

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

    def artFailed(_e: any) {
        useFallback = True;
    }

    return <div className="scroll brain-home">
        <header className="brain-top compact">
            <p className="brain-mark">Neurotech</p>
        </header>

        {if useFallback {
            <MiniConstellation
                key="fallback"
                nodes={nodes}
                links={links}
                thoughtCount={total}
                skillCount={len(skills)}
                onOpen={openGraph}
            />
        } else {
            <button key="art" className="brain-stage" onClick={openGraph} aria-label="Open graph">
                <div className="brain-stage-void">
                    <img
                        className="brain-visual"
                        src="/static/assets/brain.png"
                        alt="Your second brain"
                        onError={artFailed}
                    />
                    <div className="brain-stage-fog" aria-hidden="true"></div>
                </div>
                <p className="brain-stage-caption">{caption if total > 0 else "Your mind, mapped"}</p>
            </button>
        }}

        {if total == 0 {
            <div key="empty" className="brain-empty">
                <h2>Nothing captured yet</h2>
                <p>Add a thought and it becomes part of your brain.</p>
                <button className="primary-btn" onClick={capture} disabled={busy}>
                    Capture a thought
                </button>
                <button className="text-btn" onClick={demo} disabled={busy}>
                    {"Building…" if busy else "Load demo data"}
                </button>
            </div>
            skip;
        }}

        <section className="home-section">
            <div className="section-row">
                <h2 className="section-label">Recent</h2>
                <label className="search-inline">
                    <input
                        className="search-input"
                        placeholder="Search"
                        value={query}
                        onChange={onQueryChange}
                    />
                </label>
            </div>
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
