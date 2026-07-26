"""Bottom navigation with the centre capture button.

Icons are inline SVG rather than an icon package - five glyphs is not worth a
dependency, and inlining keeps the offline bundle self-contained.
"""

"""One tab. Own component so the tap closes over its key."""
def:pub Tab(
    name: str,
    label: str,
    active: bool,
    icon: any,
    onSelect: Callable[[str], None]
) -> JsxElement {
    def handle(_e: MouseEvent) {
        onSelect(name);
    }

    return <button className={"tab on" if active else "tab"} onClick={handle}>
        {icon}
        <span>{label}</span>
    </button>;
}

def:pub TabBar(
    active: str,
    onSelect: Callable[[str], None],
    onCompose: Callable[[], None]
) -> JsxElement {
    def compose(_e: MouseEvent) {
        onCompose();
    }

    brain = <svg width="21" height="21" viewBox="0 0 24 24" fill="none"
        stroke="currentColor" strokeWidth="1.7" strokeLinecap="round" strokeLinejoin="round">
        <path d="M12 5a3 3 0 0 0-3 3 3 3 0 0 0-2 5.2A3 3 0 0 0 9 18a3 3 0 0 0 3 1 3 3 0 0 0 3-1 3 3 0 0 0 2-4.8A3 3 0 0 0 15 8a3 3 0 0 0-3-3Z"/>
        <path d="M12 5v14"/>
    </svg>;

    graph = <svg width="21" height="21" viewBox="0 0 24 24" fill="none"
        stroke="currentColor" strokeWidth="1.7" strokeLinecap="round" strokeLinejoin="round">
        <circle cx="6.5" cy="7" r="2.2"/>
        <circle cx="17.5" cy="6.5" r="2.2"/>
        <circle cx="12" cy="17" r="2.4"/>
        <path d="M8.4 8.4l2.4 6.2M15.6 8.2l-2.2 6.4M8.7 7.2h6.6"/>
    </svg>;

    spark = <svg width="21" height="21" viewBox="0 0 24 24" fill="none"
        stroke="currentColor" strokeWidth="1.7" strokeLinecap="round" strokeLinejoin="round">
        <path d="M12 3l1.9 4.8L18.7 9.7l-4.8 1.9L12 16.4l-1.9-4.8L5.3 9.7l4.8-1.9L12 3Z"/>
        <path d="M19 15l.9 2.2 2.1.8-2.1.8-.9 2.2-.9-2.2-2.1-.8 2.1-.8.9-2.2Z"/>
    </svg>;

    me = <svg width="21" height="21" viewBox="0 0 24 24" fill="none"
        stroke="currentColor" strokeWidth="1.7" strokeLinecap="round">
        <circle cx="12" cy="8" r="3.4"/>
        <path d="M4.5 20a7.5 7.5 0 0 1 15 0"/>
    </svg>;

    return <nav className="tabbar">
        <Tab name="brain" label="Brain" active={active == "brain"} icon={brain} onSelect={onSelect}/>
        <Tab name="graph" label="Graph" active={active == "graph"} icon={graph} onSelect={onSelect}/>
        <button className="fab" onClick={compose} aria-label="Capture">
            <svg width="26" height="26" viewBox="0 0 24 24" fill="none"
                stroke="currentColor" strokeWidth="2.4" strokeLinecap="round">
                <path d="M12 5v14M5 12h14"/>
            </svg>
        </button>
        <Tab name="skills" label="Skills" active={active == "skills"} icon={spark} onSelect={onSelect}/>
        <Tab name="profile" label="Profile" active={active == "profile"} icon={me} onSelect={onSelect}/>
    </nav>;
}
