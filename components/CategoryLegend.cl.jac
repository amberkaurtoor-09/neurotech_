"""Floating legend. Tapping a row filters that category out of the graph."""

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

def:pub CategoryLegend(hidden: list[str], onToggle: Callable[[str], None]) -> JsxElement {
    return <div className="legend">
        <p className="legend-title">Categories</p>
        {for name in categories() {
            <LegendRow
                key={name}
                name={name}
                off={name in hidden}
                onToggle={onToggle}
            />
        }}
    </div>;
}
