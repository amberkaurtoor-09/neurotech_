"""Detail sheet for the focused graph node.

Replaces the old read-only 'peek': shows what the node connects to and, for
thoughts, offers deletion - so tapping a node is never a dead end.
"""

def:pub NodeSheet(
    kind: str,
    tint: str,
    text: str,
    neighbors: list[str],
    canDelete: bool,
    onDelete: Callable[[], None],
    onClose: Callable[[], None]
) -> JsxElement {
    def close(_e: MouseEvent) {
        onClose();
    }

    def del_(_e: MouseEvent) {
        onDelete();
    }

    return <div className="node-sheet">
        <div className="node-sheet-top">
            <span className="node-kind" style={{"color": tint}}>{kind}</span>
            <button className="node-close" onClick={close} aria-label="Close">&times;</button>
        </div>
        <p className="node-text">{text}</p>
        {if len(neighbors) > 0 {
            <div key="neighbors" className="node-neighbors">
                {for (i, n) in enumerate(neighbors) {
                    <span key={str(i)} className="build-tag">{n}</span>
                }}
            </div>
        }}
        {if canDelete {
            <div key="actions" className="node-actions">
                <button className="node-del" onClick={del_}>Forget this thought</button>
            </div>
        }}
    </div>;
}
