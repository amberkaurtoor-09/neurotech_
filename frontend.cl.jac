"""Neurotech - the app shell.

One stateful component owns the brain and prop-drills it into the sections
(jac-cl-organization's stateful-shell pattern). Handler bodies live in
frontend.impl.jac so this file stays a readable description of the UI.
"""

import "./global.css";

import from .components.BrainGraph { BrainGraph }
import from .components.CategoryLegend { CategoryLegend }
import from .components.TabBar { TabBar }
import from .components.Composer { Composer }
import from .components.Feed { Feed }
import from .components.Skills { Skills }

sv import from endpoints {
    GraphNode, GraphLink, SkillView, LoadBrain,
    create_thought, delete_thought, seed_demo, reset_brain
}

def:pub app -> JsxElement {
    has nodes: list[GraphNode] = [],
        links: list[GraphLink] = [],
        skills: list[SkillView] = [],
        tab: str = "brain",
        hidden: list[str] = [],
        focus: str = "",
        composing: bool = False,
        legendOpen: bool = False,
        busy: bool = False,
        loaded: bool = False;

    async can with entry {
        refresh();
    }

    async def refresh -> None;
    async def submit(text: str, cat: str) -> None;
    async def remove(id: str) -> None;
    async def loadDemo -> None;
    async def wipe -> None;

    def choose(name: str) -> None {
        tab = name;
        focus = "";
    }

    def toggle(name: str) -> None {
        hidden = [c for c in hidden if c != name] if name in hidden else hidden + [name];
    }

    def pickNode(id: str) -> None {
        focus = "" if id == focus else id;
    }

    def clearFocus -> None {
        focus = "";
    }

    def flipLegend -> None {
        legendOpen = not legendOpen;
    }

    def openComposer -> None {
        composing = True;
    }

    def closeComposer -> None {
        composing = False;
    }

    thoughts = [n for n in nodes if n.kind == "thought"];
    visible = [n for n in thoughts if n.category not in hidden];

    # Flattened to plain strings rather than an Optional node: a type guard
    # inside a JSX slot does not narrow across the slot boundary (E1099).
    peekKind = "";
    peekText = "";
    for n in nodes {
        if n.id == focus {
            peekKind = "Skill" if n.kind == "skill" else n.category;
            peekText = n.detail;
        }
    }

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
                        nodes={nodes}
                        links={links}
                        hidden={hidden}
                        focus={focus}
                        onPick={pickNode}
                        onClear={clearFocus}
                    />
                    {if loaded and len(thoughts) == 0 {
                        <div className="empty">
                            <h2>Your brain is empty</h2>
                            <p>Capture a thought and Neurotech wires it to related memories and the skills it builds.</p>
                            <button className="ghost-btn" onClick={loadDemo} disabled={busy}>
                                {"Building..." if busy else "Load a demo brain"}
                            </button>
                        </div>
                    }}
                    {if len(thoughts) > 0 {
                        <CategoryLegend
                            hidden={hidden}
                            open={legendOpen}
                            onToggle={toggle}
                            onExpand={flipLegend}
                        />
                        <div className="count-pill">
                            <b>{str(len(visible))}</b>{" thoughts · "}<b>{str(len(skills))}</b>{" skills"}
                        </div>
                    }}
                    {if peekText {
                        <div className="peek">
                            <span className="peek-kind">{peekKind}</span>
                            <p className="peek-text">{peekText}</p>
                        </div>
                    }}
                </div>
            }}
            {if tab == "feed" {
                <Feed nodes={nodes} links={links} onDelete={remove}/>
            }}
            {if tab == "skills" {
                <Skills nodes={nodes} links={links} skills={skills}/>
            }}
            {if tab == "me" {
                <div className="scroll">
                    <p className="section-title">This brain</p>
                    <div className="card">
                        <p className="card-text">
                            {"Every thought is a node on a Jac graph. Relatedness is a typed Link edge, "
                             + "and a Builds edge points at the skill a memory moved forward. "
                             + "Nothing here is a table."}
                        </p>
                        <p className="card-links">
                            {str(len(nodes)) + " nodes · " + str(len(links)) + " edges"}
                        </p>
                    </div>
                    <p className="section-title">Danger zone</p>
                    <button className="ghost-btn wide" onClick={wipe} disabled={busy}>
                        Erase this brain
                    </button>
                </div>
            }}
        </main>

        <TabBar active={tab} onSelect={choose} onCompose={openComposer}/>

        {if composing {
            <Composer busy={busy} onSubmit={submit} onClose={closeComposer}/>
        }}
    </div>;
}
