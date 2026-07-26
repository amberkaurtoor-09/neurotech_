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
import from .components.NodeSheet { NodeSheet }
import from .components.ConfirmDialog { ConfirmDialog }
import from .components.palette { cat_color }

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
        loaded: bool = False,
        error: str = "",
        confirmWipe: bool = False,
        pendingDelete: str = "";

    async can with entry {
        refresh();
    }

    async def refresh -> None;
    async def submit(text: str, cat: str) -> None;
    async def confirmDelete -> None;
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

    def askRemove(id: str) -> None {
        pendingDelete = id;
    }

    def cancelDelete -> None {
        pendingDelete = "";
    }

    def askWipe(_e: MouseEvent) -> None {
        confirmWipe = True;
    }

    def cancelWipe -> None {
        confirmWipe = False;
    }

    def startHere(_e: MouseEvent) -> None {
        composing = True;
    }

    def dismissError(_e: MouseEvent) -> None {
        error = "";
    }

    thoughts = [n for n in nodes if n.kind == "thought"];
    visible = [n for n in thoughts if n.category not in hidden];

    # Flattened to plain strings rather than an Optional node: a type guard
    # inside a JSX slot does not narrow across the slot boundary (E1099).
    peekKind = "";
    peekText = "";
    peekTint = "#c9d1ff";
    peekIsThought = False;
    for n in nodes {
        if n.id == focus {
            peekKind = "Skill" if n.kind == "skill" else n.category;
            peekText = n.detail;
            peekIsThought = n.kind == "thought";
            if n.kind == "thought" {
                peekTint = cat_color(n.category);
            }
        }
    }

    # Labels of everything the focused node connects to.
    labelOf: dict[str, str] = {};
    for n in nodes {
        labelOf[n.id] = n.label;
    }
    peekNeighbors: list[str] = [];
    if focus {
        for l in links {
            if l.source == focus and l.target in labelOf {
                peekNeighbors = peekNeighbors + [labelOf[l.target]];
            } elif l.target == focus and l.source in labelOf {
                peekNeighbors = peekNeighbors + [labelOf[l.source]];
            }
        }
    }

    def deleteFocused -> None {
        pendingDelete = focus;
    }

    return <div className="shell">
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

        {if error {
            <div key="toast" className="toast" role="alert">
                <span>{error}</span>
                <button className="toast-dismiss" onClick={dismissError}>Dismiss</button>
            </div>
        }}

        <main className="stage">
            {if not loaded {
                <div key="loading" className="skeleton-stage" aria-label="Loading">
                    <span className="skel-node" style={{"left": "28%", "top": "22%", "width": "46px", "height": "46px"}}></span>
                    <span className="skel-node" style={{"left": "58%", "top": "30%", "width": "30px", "height": "30px", "animationDelay": "120ms"}}></span>
                    <span className="skel-node" style={{"left": "42%", "top": "44%", "width": "22px", "height": "22px", "animationDelay": "240ms"}}></span>
                    <span className="skel-node" style={{"left": "66%", "top": "54%", "width": "40px", "height": "40px", "animationDelay": "360ms"}}></span>
                    <span className="skel-node" style={{"left": "24%", "top": "60%", "width": "26px", "height": "26px", "animationDelay": "480ms"}}></span>
                    <span className="skel-node" style={{"left": "48%", "top": "70%", "width": "34px", "height": "34px", "animationDelay": "600ms"}}></span>
                    <span className="skel-hint">Assembling your brain</span>
                </div>
                skip;
            }}
            {if tab == "brain" {
                <div key="brain" className="graph-wrap">
                    <BrainGraph
                        nodes={nodes}
                        links={links}
                        skills={skills}
                        hidden={hidden}
                        focus={focus}
                        onPick={pickNode}
                        onClear={clearFocus}
                    />
                    {if len(thoughts) == 0 {
                        <div key="empty" className="empty">
                            <h2>Build your second brain</h2>
                            <p>Neurotech turns what you capture into a living graph.</p>
                            <div className="onboard-steps">
                                <div className="onboard-step">
                                    <span className="onboard-num">1</span>
                                    <span>Capture a thought, memory or goal</span>
                                </div>
                                <div className="onboard-step">
                                    <span className="onboard-num">2</span>
                                    <span>It links itself to related memories</span>
                                </div>
                                <div className="onboard-step">
                                    <span className="onboard-num">3</span>
                                    <span>Watch the skills you feed take shape</span>
                                </div>
                            </div>
                            <button className="ghost-btn" onClick={startHere} disabled={busy}>
                                Capture your first thought
                            </button>
                            <button className="ghost-btn" onClick={loadDemo} disabled={busy}>
                                {"Building..." if busy else "Or load a demo brain"}
                            </button>
                        </div>
                    }}
                    {if len(thoughts) > 0 {
                        <CategoryLegend
                            key="legend"
                            hidden={hidden}
                            open={legendOpen}
                            onToggle={toggle}
                            onExpand={flipLegend}
                        />
                        <div key="count" className="count-pill">
                            <b>{str(len(visible))}</b>{" thoughts · "}<b>{str(len(skills))}</b>{" skills"}
                        </div>
                    }}
                    {if peekText {
                        <NodeSheet
                            key="sheet"
                            kind={peekKind}
                            tint={peekTint}
                            text={peekText}
                            neighbors={peekNeighbors}
                            canDelete={peekIsThought}
                            onDelete={deleteFocused}
                            onClose={clearFocus}
                        />
                    }}
                </div>
            }}
            {if tab == "feed" {
                <Feed key="feed" nodes={nodes} links={links} onDelete={askRemove}/>
            }}
            {if tab == "skills" {
                <Skills key="skills" nodes={nodes} links={links} skills={skills}/>
            }}
            {if tab == "me" {
                <div key="me" className="scroll">
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
                    <button className="ghost-btn wide" onClick={askWipe} disabled={busy}>
                        Erase this brain
                    </button>
                </div>
            }}
        </main>

        <TabBar active={tab} onSelect={choose} onCompose={openComposer}/>

        {if composing {
            <Composer key="composer" busy={busy} onSubmit={submit} onClose={closeComposer}/>
        }}

        {if confirmWipe {
            <ConfirmDialog
                key="confirm-wipe"
                title="Erase this brain?"
                body="Every thought, link and skill will be permanently deleted. This cannot be undone."
                action="Erase everything"
                busy={busy}
                onConfirm={wipe}
                onCancel={cancelWipe}
            />
        }}

        {if pendingDelete {
            <ConfirmDialog
                key="confirm-delete"
                title="Forget this thought?"
                body="The thought and its links will be removed. Skills it fed will lose one rep."
                action="Forget it"
                busy={busy}
                onConfirm={confirmDelete}
                onCancel={cancelDelete}
            />
        }}
    </div>;
}
