"""Neurotech - the app shell.

One stateful component owns the brain and prop-drills it into the sections
(jac-cl-organization's stateful-shell pattern). Handler bodies live in
frontend.impl.jac so this file stays a readable description of the UI.
"""

import "./global.css";

import from .components.BrainHome { BrainHome }
import from .components.GraphScreen { GraphScreen }
import from .components.TabBar { TabBar }
import from .components.Composer { Composer }
import from .components.Skills { Skills }
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

    def openComposerFromBrain() -> None {
        composing = True;
    }

    def openGraphFromBrain() -> None {
        tab = "graph";
        focus = "";
    }

    def dismissError(_e: MouseEvent) -> None {
        error = "";
    }

    # Flattened peek fields: type guards do not narrow across JSX slots (E1099).
    peekTitle = "";
    peekKind = "";
    peekText = "";
    peekTint = "#8b9cff";
    peekIsThought = False;
    for n in nodes {
        if n.id == focus {
            peekTitle = n.label if n.label else n.detail;
            peekKind = "Skill" if n.kind == "skill" else n.category;
            peekText = n.detail if n.kind == "thought" else n.detail;
            peekIsThought = n.kind == "thought";
            if n.kind == "thought" {
                peekTint = cat_color(n.category);
            } else {
                peekTint = "#a78bfa";
            }
        }
    }

    labelOf: dict[str, str] = {};
    for n in nodes {
        labelOf[n.id] = n.label if n.label else n.detail;
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

    thoughtCount = len([n for n in nodes if n.kind == "thought"]);

    return <div className="device-scene">
        <div className="iphone">
            <div className="iphone-frame">
                <div className="iphone-island" aria-hidden="true"></div>
                <div className="iphone-screen">
                    <div className="shell">
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
                <BrainHome
                    key="brain"
                    nodes={nodes}
                    links={links}
                    skills={skills}
                    busy={busy}
                    onCapture={openComposerFromBrain}
                    onDemo={loadDemo}
                    onOpenGraph={openGraphFromBrain}
                />
            }}
            {if tab == "graph" {
                <GraphScreen
                    key="graph"
                    nodes={nodes}
                    links={links}
                    skills={skills}
                    hidden={hidden}
                    focus={focus}
                    legendOpen={legendOpen}
                    busy={busy}
                    peekTitle={peekTitle}
                    peekKind={peekKind}
                    peekTint={peekTint}
                    peekText={peekText}
                    peekNeighbors={peekNeighbors}
                    peekIsThought={peekIsThought}
                    onPick={pickNode}
                    onClear={clearFocus}
                    onToggle={toggle}
                    onExpandLegend={flipLegend}
                    onDelete={deleteFocused}
                    onCapture={startHere}
                />
            }}
            {if tab == "skills" {
                <Skills key="skills" nodes={nodes} links={links} skills={skills}/>
            }}
            {if tab == "profile" {
                <div key="profile" className="scroll profile-page">
                    <div className="profile-hero">
                        <span className="profile-avatar">M</span>
                        <h2>Mercedes</h2>
                        <p>Second brain operator</p>
                    </div>
                    <div className="stat-grid">
                        <div className="stat">
                            <div className="stat-num">{str(thoughtCount)}</div>
                            <div className="stat-lbl">Thoughts</div>
                        </div>
                        <div className="stat">
                            <div className="stat-num">{str(len(skills))}</div>
                            <div className="stat-lbl">Skills</div>
                        </div>
                        <div className="stat">
                            <div className="stat-num">{str(len(links))}</div>
                            <div className="stat-lbl">Links</div>
                        </div>
                        <div className="stat">
                            <div className="stat-num">{str(len(nodes))}</div>
                            <div className="stat-lbl">Nodes</div>
                        </div>
                    </div>
                    <p className="section-title">About</p>
                    <div className="glass-card">
                        <p className="card-text">
                            {"Every thought is a node on a Jac graph. Relatedness is a typed Link edge, "
                             + "and a Builds edge points at the skill a memory moved forward."}
                        </p>
                    </div>
                    <p className="section-title danger-label">Danger zone</p>
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
                    </div>
                </div>
                <div className="iphone-bar" aria-hidden="true"></div>
            </div>
        </div>
    </div>;
}
