"""Detail sheet for the focused graph node.

Glass bottom sheet: title, connection count, related chips, and a primary
Open Collection CTA - plus forget for thoughts.
"""

def:pub NodeSheet(
    title: str,
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

    ncount = len(neighbors);

    return <div className="node-sheet">
        <div className="sheet-handle"></div>
        <div className="node-sheet-top">
            <span className="node-kind" style={{"color": tint}}>{kind}</span>
            <button className="node-close" onClick={close} aria-label="Close">&times;</button>
        </div>
        <h3 className="node-title">{title}</h3>
        <p className="node-conn">
            {str(ncount) + (" connected thoughts" if ncount != 1 else " connected thought")}
        </p>
        {if text {
            <p className="node-text">{text}</p>
        }}
        {if ncount > 0 {
            <div key="neighbors" className="node-neighbors">
                <span className="node-chip-label">Related</span>
                {for (i, n) in enumerate(neighbors) {
                    <span key={str(i)} className="build-tag">{n}</span>
                }}
            </div>
        }}
        <div className="node-actions">
            <button className="primary-btn sheet-cta" onClick={close}>Open Collection</button>
            {if canDelete {
                <button key="del" className="node-del" onClick={del_}>Forget</button>
            }}
        </div>
    </div>;
}
