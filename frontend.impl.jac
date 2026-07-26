"""Neurotech - frontend handler implementations.

Each handler spawns the `LoadBrain` walker or calls a `def:pub` endpoint and
folds the result back into client state. No fetch, no client SDK, no
serializers - the same call shape the server uses.

State is rebound rather than mutated (`thoughts = view.thoughts`, never
`thoughts.append(...)`), because `has` fields are React state and in-place
mutation would not re-render.
"""

impl app.refresh -> None {
    result = root spawn LoadBrain();
    if result.reports {
        view = result.reports[0];
        thoughts = view.thoughts;
        links = view.links;
    }
    loaded = True;
}

impl app.submit(text: str, cat: str) -> None {
    if not text.strip() {
        return;
    }
    busy = True;
    _ = await create_thought(text, cat);

    reloaded = root spawn LoadBrain();
    if reloaded.reports {
        view = reloaded.reports[0];
        thoughts = view.thoughts;
        links = view.links;
    }

    busy = False;
    composing = False;
}

impl app.remove(id: str) -> None {
    _ = await delete_thought(id);

    reloaded = root spawn LoadBrain();
    if reloaded.reports {
        view = reloaded.reports[0];
        thoughts = view.thoughts;
        links = view.links;
    }
}
