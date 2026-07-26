"""Category palette, shared by every client component.

Kept in one place so the legend, the neurons, the feed chips and the insight
bars can never drift out of sync. Mirrors the --cat-* tokens in global.css.
"""

glob CATEGORY_ORDER: list[str] = [
    "idea", "memory", "goal", "learning", "health", "reflection"
];

glob CAT_COLORS: dict[str, str] = {
    "idea": "#7d8cf0",
    "memory": "#d97ba2",
    "goal": "#cfa356",
    "learning": "#5cb894",
    "health": "#58aec4",
    "reflection": "#a488d9"
};

"""The canonical category order.

Exposed as a function rather than importing the `glob` directly: globs are
module-local in the client bundle, so a cross-file `import { CATEGORY_ORDER }`
compiles but has no matching JS export and dies at bundle time.
"""
def:pub categories() -> list[str] {
    return CATEGORY_ORDER;
}

"""Colour for a category, falling back to the idea indigo for unknowns."""
def:pub cat_color(name: str) -> str {
    if name in CAT_COLORS {
        return CAT_COLORS[name];
    }
    return "#7d8cf0";
}

"""Node radius. Skills read as hubs; thoughts grow with how often they connect."""
def:pub node_radius(kind: str, strength: int) -> float {
    capped = strength if strength < 8 else 8;
    if kind == "skill" {
        return 24.0 + capped * 2.6;
    }
    return 13.0 + capped * 2.8;
}
