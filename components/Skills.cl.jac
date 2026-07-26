"""What the graph says you are getting better at.

Mastery is never entered by the user - it is counted from the thoughts that
point at each skill. That is the whole argument of the app: capture memory,
and the skill picture assembles itself.
"""

sv import from endpoints { GraphNode, GraphLink, SkillView }

import from .palette { categories, cat_color }

def:pub SkillCard(skill: SkillView) -> JsxElement {
    pct = skill.mastery * 100.0;
    level = "Practising";
    if skill.mastery >= 1.0 {
        level = "Fluent";
    } elif skill.mastery >= 0.6 {
        level = "Solid";
    } elif skill.mastery < 0.3 {
        level = "Just started";
    }

    return <article className="card">
        <div className="card-top">
            <span className="skill-name">{skill.name}</span>
            <span className="card-meta">{level}</span>
        </div>
        <p className="card-links" style={{"margin": "0 0 10px"}}>{skill.blurb}</p>
        <div className="bar-track">
            <span
                className="bar-fill"
                style={{"width": str(pct) + "%", "background": "linear-gradient(90deg,#6d4aff,#a78bfa)"}}
            ></span>
        </div>
        <p className="card-links">
            {str(skill.reps) + " of " + str(skill.target) + " thoughts feeding it"}
        </p>
    </article>;
}

def:pub Bar(name: str, count: int, total: int) -> JsxElement {
    pct = 0.0 if total == 0 else count / total * 100.0;

    return <div className="bar-row">
        <span className="bar-name">{name}</span>
        <span className="bar-track">
            <span
                className="bar-fill"
                style={{"width": str(pct) + "%", "background": cat_color(name)}}
            ></span>
        </span>
        <span className="bar-val">{str(count)}</span>
    </div>;
}

def:pub Skills(
    nodes: list[GraphNode],
    links: list[GraphLink],
    skills: list[SkillView]
) -> JsxElement {
    thoughts = [n for n in nodes if n.kind == "thought"];
    counts: dict[str, int] = {};
    for t in thoughts {
        counts[t.category] = counts[t.category] + 1 if t.category in counts else 1;
    }

    # Counted as we go, not via len(): len() of a dict compiles to `undefined`
    # in the browser, which would render the Unlinked tile as NaN.
    seen: dict[str, bool] = {};
    connected = 0;
    for l in links {
        if l.kind == "link" {
            if not (l.source in seen) {
                seen[l.source] = True;
                connected += 1;
            }
            if not (l.target in seen) {
                seen[l.target] = True;
                connected += 1;
            }
        }
    }

    total = len(thoughts);
    strongest = sorted(skills, key=lambda (s: SkillView) -> float { return 0.0 - s.mastery; });

    return <div className="scroll">
        <p className="section-title">Skills forming</p>
        {if len(skills) == 0 {
            <p className="card-links">Capture a few thoughts and skills will emerge here.</p>
            skip;
        }}
        {for s in strongest {
            <SkillCard key={s.id} skill={s}/>
        }}

        <p className="section-title">Memory mix</p>
        {for name in categories() {
            <Bar
                key={name}
                name={name}
                count={counts[name] if name in counts else 0}
                total={total}
            />
        }}

        <p className="section-title">Graph shape</p>
        <div className="stat-grid">
            <div className="stat">
                <div className="stat-num">{str(total)}</div>
                <div className="stat-lbl">Thoughts</div>
            </div>
            <div className="stat">
                <div className="stat-num">{str(len(links))}</div>
                <div className="stat-lbl">Connections</div>
            </div>
            <div className="stat">
                <div className="stat-num">{str(len(skills))}</div>
                <div className="stat-lbl">Skills</div>
            </div>
            <div className="stat">
                <div className="stat-num">{str(total - connected)}</div>
                <div className="stat-lbl">Unlinked</div>
            </div>
        </div>
    </div>;
}
