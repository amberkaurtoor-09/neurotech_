"""Floating legend. Tapping a row filters that category out of the graph.

Collapsible, because at full size it covers a real chunk of a 375px canvas -
and the corner it sits in is exactly where the force layout likes to put a
cluster.
"""

import from .palette { categories, cat_color }

"""One legend row - own component so the tap closes over its category."""
def:pub LegendRow(name: str, off: bool, onToggle: Callable[[str], None]) -> JsxElement {
    def handle(_e: MouseEvent) {
        onToggle(name);
    }

    return <button
        className={"legend-row off" if off else "legend-row"}
        onClick={handle}
    >
        <span className="legend-swatch" style={{"background": cat_color(name)}}></span>
        <span style={{"textTransform": "capitalize"}}>{name}</span>
    </button>;
}

"""Collapsed form: just the swatches, still tappable as filters."""
def:pub LegendDot(name: str, off: bool, onToggle: Callable[[str], None]) -> JsxElement {
    def handle(_e: MouseEvent) {
        onToggle(name);
    }

    return <button
        className={"legend-dot off" if off else "legend-dot"}
        style={{"background": cat_color(name)}}
        onClick={handle}
        aria-label={name}
    ></button>;
}

def:pub CategoryLegend(
    hidden: list[str],
    open: bool,
    onToggle: Callable[[str], None],
    onExpand: Callable[[], None]
) -> JsxElement {
    def flip(_e: MouseEvent) {
        onExpand();
    }

    return <div className={"legend" if open else "legend closed"}>
        <button className="legend-head" onClick={flip}>
            <span className="legend-title">Categories</span>
            <span className="legend-caret">{"–" if open else "+"}</span>
        </button>
        {if open {
            for name in categories() {
                <LegendRow
                    key={name}
                    name={name}
                    off={name in hidden}
                    onToggle={onToggle}
                />
            }
        } else {
            <div className="legend-dots">
                {for name in categories() {
                    <LegendDot
                        key={name}
                        name={name}
                        off={name in hidden}
                        onToggle={onToggle}
                    />
                }}
            </div>
        }}
    </div>;
}
