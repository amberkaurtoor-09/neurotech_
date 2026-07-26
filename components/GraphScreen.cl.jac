"""Graph tab — cinematic full-bleed knowledge map."""

sv import from endpoints { GraphNode, GraphLink, SkillView }

import from .BrainGraph { BrainGraph }
import from .CategoryLegend { CategoryLegend }
import from .NodeSheet { NodeSheet }

def:pub GraphScreen(
    nodes: list[GraphNode],
    links: list[GraphLink],
    skills: list[SkillView],
    hidden: list[str],
    focus: str,
    legendOpen: bool,
    busy: bool,
    peekTitle: str,
    peekKind: str,
    peekTint: str,
    peekText: str,
    peekNeighbors: list[str],
    peekIsThought: bool,
    onPick: Callable[[str], None],
    onClear: Callable[[], None],
    onToggle: Callable[[str], None],
    onExpandLegend: Callable[[], None],
    onDelete: Callable[[], None],
    onCapture: Callable[[MouseEvent], None]
) -> JsxElement {
    thoughts = [n for n in nodes if n.kind == "thought"];

    def expandLegend(_e: MouseEvent) {
        onExpandLegend();
    }

    return <div className="graph-screen cinematic">
        <div className="graph-chrome slim">
            <div className="graph-chrome-top">
                <div>
                    <h2 className="graph-title">Your brain</h2>
                    <p className="graph-metrics">
                        {str(len(thoughts)) + " thoughts · " + str(len(skills)) + " skills · " + str(len(links)) + " links"}
                    </p>
                </div>
                <div className="graph-tools">
                    <button className="icon-btn glass" aria-label="Filter" onClick={expandLegend}>
                        <svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor"
                            strokeWidth="1.8" strokeLinecap="round">
                            <path d="M4 6h16M7 12h10M10 18h4"/>
                        </svg>
                    </button>
                </div>
            </div>
        </div>

        <div className="graph-stage">
            <div className="graph-depth-fog" aria-hidden="true"></div>
            <div className="graph-stage-inner">
                <BrainGraph
                    nodes={nodes}
                    links={links}
                    skills={skills}
                    hidden={hidden}
                    focus={focus}
                    onPick={onPick}
                    onClear={onClear}
                />
                {if len(thoughts) == 0 {
                    <div key="empty" className="empty graph-empty">
                        <h2>No nodes yet</h2>
                        <p>Capture a thought, then fly the map as it grows.</p>
                        <button className="ghost-btn" onClick={onCapture} disabled={busy}>
                            Capture a thought
                        </button>
                    </div>
                }}
                {if len(thoughts) > 0 {
                    <CategoryLegend
                        key="legend"
                        hidden={hidden}
                        open={legendOpen}
                        onToggle={onToggle}
                        onExpand={onExpandLegend}
                    />
                }}
                {if peekTitle {
                    <NodeSheet
                        key="sheet"
                        title={peekTitle}
                        kind={peekKind}
                        tint={peekTint}
                        text={peekText}
                        neighbors={peekNeighbors}
                        canDelete={peekIsThought}
                        onDelete={onDelete}
                        onClose={onClear}
                    />
                }}
            </div>
        </div>
    </div>;
}
