"""The brain itself - neurons and synapses drawn straight from the graph.

Positions arrive precomputed from the server walker, so this component is
pure rendering: no layout maths, no animation loop. The "alive" feel is CSS
keyframes on the neurons, which costs nothing and never drops a frame.
"""

sv import from endpoints { ThoughtView, LinkView }

import from .palette { cat_color, neuron_radius }

"""One neuron. Its own component so the click handler closes over its id."""
def:pub Neuron(
    thought: ThoughtView,
    delay: str,
    onPick: Callable[[str], None]
) -> JsxElement {
    def handle(_e: MouseEvent) {
        onPick(thought.id);
    }

    color = cat_color(thought.category);
    r = neuron_radius(thought.strength);

    return <g className="neuron" style={{"animationDelay": delay}} onClick={handle}>
        <circle className="neuron-halo" cx={thought.x} cy={thought.y} r={r * 2.2} fill={color}/>
        <circle className="neuron-core" cx={thought.x} cy={thought.y} r={r} fill={color}/>
    </g>;
}

def:pub BrainGraph(
    thoughts: list[ThoughtView],
    links: list[LinkView],
    hidden: list[str],
    onPick: Callable[[str], None]
) -> JsxElement {
    visible = [t for t in thoughts if t.category not in hidden];

    at: dict[str, ThoughtView] = {};
    for t in visible {
        at[t.id] = t;
    }

    return <svg
        className="graph-svg"
        viewBox="0 0 1000 1000"
        preserveAspectRatio="xMidYMid meet"
    >
        {for (i, l) in enumerate(links) {
            if l.source in at and l.target in at {
                <line
                    key={"l" + str(i)}
                    className="link-line"
                    x1={at[l.source].x}
                    y1={at[l.source].y}
                    x2={at[l.target].x}
                    y2={at[l.target].y}
                    strokeWidth={0.7 + l.weight * 3.5}
                />
            }
        }}
        {for (i, t) in enumerate(visible) {
            <Neuron
                key={t.id}
                thought={t}
                delay={str(i % 7 * 0.42) + "s"}
                onPick={onPick}
            />
        }}
    </svg>;
}
