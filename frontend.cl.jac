"""Neurotech - the app shell.

One stateful component owns the brain and prop-drills it into four dumb
sections (jac-cl-organization's stateful-shell pattern). Handler bodies live
in frontend.impl.jac so this file stays a readable description of the UI.
"""

import "./global.css";

import from .components.BrainGraph { BrainGraph }
import from .components.CategoryLegend { CategoryLegend }
import from .components.TabBar { TabBar }
import from .components.Composer { Composer }
import from .components.Feed { Feed }
import from .components.Insights { Insights }

sv import from endpoints {
    ThoughtView, LinkView, LoadBrain, create_thought, delete_thought
}

def:pub app -> JsxElement {
    has thoughts: list[ThoughtView] = [],
        links: list[LinkView] = [],
        tab: str = "brain",
        hidden: list[str] = [],
        composing: bool = False,
        busy: bool = False,
        loaded: bool = False;

    async can with entry {
        refresh();
    }

    async def refresh -> None;
    async def submit(text: str, cat: str) -> None;
    async def remove(id: str) -> None;

    def choose(name: str) -> None {
        tab = name;
    }

    def toggle(name: str) -> None {
        hidden = [c for c in hidden if c != name] if name in hidden else hidden + [name];
    }

    def pick(_id: str) -> None {
        tab = "feed";
    }

    def openComposer -> None {
        composing = True;
    }

    def closeComposer -> None {
        composing = False;
    }

    visibleCount = len([t for t in thoughts if t.category not in hidden]);

    return <div className="shell">
        <div className="starfield"></div>

        <header className="header">
            <span className="logo">
                <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#fff"
                    strokeWidth="1.9" strokeLinecap="round" strokeLinejoin="round">
                    <path d="M12 5a3 3 0 0 0-3 3 3 3 0 0 0-2 5.2A3 3 0 0 0 9 18a3 3 0 0 0 3 1 3 3 0 0 0 3-1 3 3 0 0 0 2-4.8A3 3 0 0 0 15 8a3 3 0 0 0-3-3Z"/>
                    <path d="M12 5v14"/>
                </svg>
            </span>
            <span>
                <h1 className="brand-name">Neurotech</h1>
                <p className="brand-tag">Your second brain</p>
            </span>
            <button className="icon-btn" aria-label="Notifications">
                <svg width="19" height="19" viewBox="0 0 24 24" fill="none" stroke="currentColor"
                    strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
                    <path d="M18 8A6 6 0 0 0 6 8c0 7-3 8-3 8h18s-3-1-3-8"/>
                    <path d="M13.7 21a2 2 0 0 1-3.4 0"/>
                </svg>
                <span className="dot"></span>
            </button>
        </header>

        <main className="stage">
            {if tab == "brain" {
                <div className="graph-wrap">
                    <BrainGraph
                        thoughts={thoughts}
                        links={links}
                        hidden={hidden}
                        onPick={pick}
                    />
                    {if loaded and len(thoughts) == 0 {
                        <div className="empty">
                            <h2>Your brain is empty</h2>
                            <p>Capture a thought and Neurotech will file it, then wire it to whatever it relates to.</p>
                        </div>
                    }}
                    {if len(thoughts) > 0 {
                        <CategoryLegend hidden={hidden} onToggle={toggle}/>
                        <div className="count-pill"><b>{str(visibleCount)}</b>{" neurons"}</div>
                    }}
                </div>
            }}
            {if tab == "feed" {
                <Feed thoughts={thoughts} links={links} onDelete={remove}/>
            }}
            {if tab == "insights" {
                <Insights thoughts={thoughts} links={links}/>
            }}
            {if tab == "me" {
                <div className="scroll">
                    <p className="section-title">This brain</p>
                    <div className="card">
                        <p className="card-text">
                            {"Every thought is a node on a Jac graph and every connection is a typed edge. "
                             + "Nothing here is a table."}
                        </p>
                        <p className="card-links">
                            {str(len(thoughts)) + " nodes · " + str(len(links)) + " edges"}
                        </p>
                    </div>
                </div>
            }}
        </main>

        <TabBar active={tab} onSelect={choose} onCompose={openComposer}/>

        {if composing {
            <Composer busy={busy} onSubmit={submit} onClose={closeComposer}/>
        }}
    </div>;
}
