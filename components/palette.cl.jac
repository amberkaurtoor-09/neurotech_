"""Category palette, shared by every client component.

Kept in one place so the legend, the neurons, the feed chips and the insight
bars can never drift out of sync. Mirrors the --cat-* tokens in global.css.
"""

glob CATEGORY_ORDER: list[str] = [
    "idea", "memory", "goal", "learning", "health", "reflection"
];

glob CAT_COLORS: dict[str, str] = {
    "idea": "#8b7cf6",
    "memory": "#f472b6",
    "goal": "#fbbf24",
    "learning": "#34d399",
    "health": "#22d3ee",
    "reflection": "#c084fc"
};

"""The canonical category order.

Exposed as a function rather than importing the `glob` directly: globs are
module-local in the client bundle, so a cross-file `import { CATEGORY_ORDER }`
compiles but has no matching JS export and dies at bundle time.
"""
def:pub categories() -> list[str] {
    return CATEGORY_ORDER;
}

"""Colour for a category, falling back to the idea violet for unknowns."""
def:pub cat_color(name: str) -> str {
    if name in CAT_COLORS {
        return CAT_COLORS[name];
    }
    return "#8b7cf6";
}

"""Node radius. Skills read as hubs; thoughts grow with how often they connect."""
def:pub node_radius(kind: str, strength: int) -> float {
    capped = strength if strength < 8 else 8;
    if kind == "skill" {
        return 24.0 + capped * 2.6;
    }
    return 13.0 + capped * 2.8;
}
