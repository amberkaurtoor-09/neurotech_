"""Bottom-sheet capture. Deliberately one field: capture must be frictionless.

Category is optional - leaving it on Auto lets the server classify the
thought and wire it into the graph on its own.
"""

import from .palette { categories, cat_color }

"""One category pill. Own component so the tap closes over its value."""
def:pub CatPick(name: str, label: str, on: bool, onPick: Callable[[str], None]) -> JsxElement {
    def handle(_e: MouseEvent) {
        onPick(name);
    }

    tint = cat_color(name) if name else "#9a9eb0";
    style: dict[str, object] = {
        "borderColor": tint if on else "#262833",
        "background": tint + "26" if on else "transparent",
        "color": tint if on else "#9a9eb0"
    };

    return <button className={"cat-pick on" if on else "cat-pick"} style={style} onClick={handle}>
        {label}
    </button>;
}

def:pub Composer(
    busy: bool,
    onSubmit: Callable[[str, str], None],
    onClose: Callable[[], None]
) -> JsxElement {
    has text: str = "";
    has cat: str = "";

    def edit(e: ChangeEvent) {
        text = e.target.value;
    }

    def pick(name: str) -> None {
        cat = "" if name == cat else name;
    }

    def dismiss(_e: MouseEvent) {
        onClose();
    }

    def send(_e: MouseEvent) {
        if text.strip() {
            onSubmit(text.strip(), cat);
        }
    }

    return <div>
        <div className="backdrop" onClick={dismiss}></div>
        <div className="sheet">
            <div className="grabber"></div>
            <h3>New thought</h3>
            <textarea
                className="composer-input"
                value={text}
                onChange={edit}
                placeholder="What's on your mind?"
                autoFocus={True}
            ></textarea>
            <div className="cat-strip">
                <CatPick name="" label="Auto" on={cat == ""} onPick={pick}/>
                {for name in categories() {
                    <CatPick key={name} name={name} label={name} on={cat == name} onPick={pick}/>
                }}
            </div>
            <button className="primary-btn" onClick={send} disabled={busy or not text.strip()}>
                {"Thinking..." if busy else "Add to brain"}
            </button>
            <p className="hint">
                {"Auto-categorised and linked to related thoughts." if cat == ""
                 else "Filed under " + cat + ", still auto-linked."}
            </p>
        </div>
    </div>;
}
