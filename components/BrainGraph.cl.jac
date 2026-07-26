"""The graph view - Obsidian's map, sized for a thumb.

Two node kinds share one canvas: thoughts (small, coloured by category) and
skills (larger, ringed, always labelled). Skill rings double as progress
bars - the arc length is mastery. Edges are quadratic beziers whose opacity
encodes link weight.

Positions arrive precomputed from the server walker; this component owns the
camera. One-finger drag pans (with momentum on release), two-finger pinch and
the trackpad wheel zoom, the +/- controls do the same for anyone who prefers
buttons, and tapping a node glides the camera to it. The camera and gesture
bookkeeping live in module `glob`s rather than `has` state - pointer events
and animation frames outrun React re-renders, so reactive reads would be
stale mid-gesture. State only mirrors the camera for rendering.
"""

sv import from endpoints { GraphNode, GraphLink, SkillView }

import from .palette { cat_color, node_radius }

glob WORLD_W: float = 1000.0;
glob WORLD_H: float = 1700.0;
glob MIN_W: float = 320.0;
glob MAX_W: float = 2200.0;

# Camera source of truth (see module docstring). `seen` remembers the node
# count so the auto-fit fires on first data and again after a wipe+reseed.
glob cam: dict[str, float] = {"x": 0.0, "y": 0.0, "w": 1000.0, "seen": 0.0};

# Non-reactive gesture state.
glob gesture: dict[str, float] = {
    "mode": 0.0,   # 0 idle, 1 pan, 2 pinch
    "x": 0.0, "y": 0.0,
    "id1": -1.0, "id2": -1.0,
    "x2": 0.0, "y2": 0.0,
    "dist": 0.0,
    "moved": 0.0,
    "vx": 0.0, "vy": 0.0   # smoothed px-per-event velocity for momentum
};

# One animation driver for both inertia (mode 1) and glide-to-target (mode 2).
# `token` invalidates any in-flight loop the moment a new gesture starts.
glob motion: dict[str, float] = {
    "token": 0.0, "mode": 0.0, "t": 0.0, "k": 1.0,
    "vx": 0.0, "vy": 0.0,
    "sx": 0.0, "sy": 0.0, "sw": 0.0,
    "tx": 0.0, "ty": 0.0, "tw": 0.0
};

"""Clip a label to something that fits beside a node on a phone."""
def:pub trim(text: str, limit: int) -> str {
    if len(text) <= limit {
        return text;
    }
    return text[:limit].strip() + "...";
}

def:pub GraphNodeMark(
    item: GraphNode,
    index: int,
    mastery: float,
    dim: bool,
    lit: bool,
    labelled: bool,
    onPick: Callable[[str], None]
) -> JsxElement {
    def handle(_e: MouseEvent) {
        onPick(item.id);
    }

    skill = item.kind == "skill";
    color = "#c9d1ff" if skill else cat_color(item.category);
    r = node_radius(item.kind, item.strength);

    klass = "gnode";
    if dim {
        klass = "gnode dim";
    }
    if lit {
        klass = "gnode lit";
    }

    # Staggered spring-in on mount; keys are node ids so data refreshes
    # only replay the animation for genuinely new nodes.
    delay = index * 30;
    if delay > 600 {
        delay = 600;
    }

    # Mastery ring geometry (skills only).
    ring_r = r + 8.0;
    circ = 6.28318 * ring_r;

    return <g className={klass} style={{"animationDelay": str(delay) + "ms"}} onClick={handle}>
        {if lit {
            <circle key="glow" className="gnode-glow" cx={item.x} cy={item.y} r={r * 2.4} fill={color}/>
        }}
        {if skill {
            <circle
                key="ring-track"
                cx={item.x}
                cy={item.y}
                r={ring_r}
                fill="none"
                stroke="#2b2e3d"
                strokeWidth={3.0}
            />
            <circle
                key="ring"
                className="gnode-ring"
                cx={item.x}
                cy={item.y}
                r={ring_r}
                fill="none"
                stroke={color}
                strokeWidth={3.0}
                strokeLinecap="round"
                strokeDasharray={str(circ * mastery) + " " + str(circ)}
                transform={"rotate(-90 " + str(item.x) + " " + str(item.y) + ")"}
            />
        }}
        <circle
            className={"gnode-core skill" if skill else "gnode-core"}
            cx={item.x}
            cy={item.y}
            r={r}
            fill={"#171a2e" if skill else color}
            stroke={color}
            strokeWidth={3.0 if skill else 0.0}
        />
        {if labelled {
            <text
                key="label"
                className={"glabel skill" if skill else "glabel"}
                x={item.x}
                y={item.y + (ring_r if skill else r) + 26}
                textAnchor="middle"
                fill={color}
            >
                {trim(item.label, 17 if skill else 22)}
            </text>
        }}
    </g>;
}

"""Quadratic bezier between two nodes, bowed perpendicular to the chord."""
def:pub edge_path(x1: float, y1: float, x2: float, y2: float) -> str {
    dx = x2 - x1;
    dy = y2 - y1;
    d = (dx * dx + dy * dy) ** 0.5;
    if d < 1.0 {
        return "M " + str(x1) + " " + str(y1) + " L " + str(x2) + " " + str(y2);
    }
    mx = (x1 + x2) / 2.0 - dy / d * d * 0.14;
    my = (y1 + y2) / 2.0 + dx / d * d * 0.14;
    return "M " + str(x1) + " " + str(y1)
        + " Q " + str(mx) + " " + str(my)
        + " " + str(x2) + " " + str(y2);
}

def:pub BrainGraph(
    nodes: list[GraphNode],
    links: list[GraphLink],
    skills: list[SkillView],
    hidden: list[str],
    focus: str,
    onPick: Callable[[str], None],
    onClear: Callable[[], None]
) -> JsxElement {
    # Render mirror of the camera glob.
    has vx: float = 0.0,
        vy: float = 0.0,
        vw: float = 1000.0,
        panning: bool = False;

    def set_cam(x: float, y: float, w: float) -> None {
        cam["x"] = x;
        cam["y"] = y;
        cam["w"] = w;
        vx = x;
        vy = y;
        vw = w;
    }

    """World units per screen pixel at the current zoom ('meet' fit)."""
    def world_per_px(el: any) -> float {
        rect = el.getBoundingClientRect();
        vh = cam["w"] * WORLD_H / WORLD_W;
        sx = rect.width / cam["w"];
        sy = rect.height / vh;
        s = sx if sx < sy else sy;
        return 1.0 / s if s > 0 else 1.0;
    }

    """Re-centre a new width around the current view centre, clamped."""
    def apply_zoom(new_w: float) -> None {
        w = new_w;
        if w < MIN_W {
            w = MIN_W;
        }
        if w > MAX_W {
            w = MAX_W;
        }
        cx = cam["x"] + cam["w"] / 2.0;
        cy = cam["y"] + (cam["w"] * WORLD_H / WORLD_W) / 2.0;
        set_cam(cx - w / 2.0, cy - (w * WORLD_H / WORLD_W) / 2.0, w);
    }

    """The single rAF loop: inertia after a flick, or a glide to a target."""
    def run_motion() -> None {
        token = motion["token"];
        def frame(_ts: any) {
            if motion["token"] != token {
                return;
            }
            if motion["mode"] == 1.0 {
                motion["vx"] = motion["vx"] * 0.9;
                motion["vy"] = motion["vy"] * 0.9;
                set_cam(
                    cam["x"] - motion["vx"] * motion["k"],
                    cam["y"] - motion["vy"] * motion["k"],
                    cam["w"]
                );
                speed = (motion["vx"] if motion["vx"] > 0 else -motion["vx"])
                      + (motion["vy"] if motion["vy"] > 0 else -motion["vy"]);
                if speed > 0.25 {
                    requestAnimationFrame(frame);
                }
            } elif motion["mode"] == 2.0 {
                motion["t"] = motion["t"] + 0.055;
                t = motion["t"];
                if t >= 1.0 {
                    set_cam(motion["tx"], motion["ty"], motion["tw"]);
                    return;
                }
                e = 1.0 - (1.0 - t) ** 3;
                set_cam(
                    motion["sx"] + (motion["tx"] - motion["sx"]) * e,
                    motion["sy"] + (motion["ty"] - motion["sy"]) * e,
                    motion["sw"] + (motion["tw"] - motion["sw"]) * e
                );
                requestAnimationFrame(frame);
            }
        }
        requestAnimationFrame(frame);
    }

    def stop_motion() -> None {
        motion["token"] = motion["token"] + 1.0;
        motion["mode"] = 0.0;
    }

    """Animate the camera to centre (nx, ny), zooming in a touch."""
    def glide_to(nx: float, ny: float) -> None {
        tw = cam["w"] if cam["w"] < 750.0 else 750.0;
        motion["token"] = motion["token"] + 1.0;
        motion["mode"] = 2.0;
        motion["t"] = 0.0;
        motion["sx"] = cam["x"];
        motion["sy"] = cam["y"];
        motion["sw"] = cam["w"];
        motion["tx"] = nx - tw / 2.0;
        motion["ty"] = ny - (tw * WORLD_H / WORLD_W) / 2.0 + tw * 0.25;
        motion["tw"] = tw;
        run_motion();
    }

    """Frame the whole graph with breathing room."""
    def fit_camera() -> None {
        if len(nodes) == 0 {
            set_cam(0.0, 0.0, 1000.0);
            return;
        }
        minx = nodes[0].x;
        maxx = nodes[0].x;
        miny = nodes[0].y;
        maxy = nodes[0].y;
        for n in nodes {
            if n.x < minx { minx = n.x; }
            if n.x > maxx { maxx = n.x; }
            if n.y < miny { miny = n.y; }
            if n.y > maxy { maxy = n.y; }
        }
        pad = 120.0;
        w = maxx - minx + pad * 2.0;
        h = maxy - miny + pad * 2.0;
        w_for_h = h * WORLD_W / WORLD_H;
        if w_for_h > w {
            w = w_for_h;
        }
        if w < 500.0 {
            w = 500.0;
        }
        if w > MAX_W {
            w = MAX_W;
        }
        set_cam(
            (minx + maxx) / 2.0 - w / 2.0,
            (miny + maxy) / 2.0 - (w * WORLD_H / WORLD_W) / 2.0,
            w
        );
    }

    can with [nodes] entry {
        if len(nodes) > 0 and cam["seen"] == 0.0 {
            fit_camera();
        }
        cam["seen"] = len(nodes);
    }

    def pointer_down(e: Event) {
        p = e as any;
        stop_motion();
        if gesture["mode"] == 0.0 {
            gesture["mode"] = 1.0;
            gesture["id1"] = p.pointerId;
            gesture["x"] = p.clientX;
            gesture["y"] = p.clientY;
            gesture["moved"] = 0.0;
            gesture["vx"] = 0.0;
            gesture["vy"] = 0.0;
            panning = True;
        } elif gesture["mode"] == 1.0 {
            gesture["mode"] = 2.0;
            gesture["id2"] = p.pointerId;
            gesture["x2"] = p.clientX;
            gesture["y2"] = p.clientY;
            dx = gesture["x2"] - gesture["x"];
            dy = gesture["y2"] - gesture["y"];
            gesture["dist"] = (dx * dx + dy * dy) ** 0.5;
        }
    }

    def pointer_move(e: Event) {
        p = e as any;
        if gesture["mode"] == 1.0 and p.pointerId == gesture["id1"] {
            dx = p.clientX - gesture["x"];
            dy = p.clientY - gesture["y"];
            gesture["x"] = p.clientX;
            gesture["y"] = p.clientY;
            gesture["moved"] = gesture["moved"] + (dx * dx + dy * dy) ** 0.5;
            gesture["vx"] = gesture["vx"] * 0.7 + dx * 0.3;
            gesture["vy"] = gesture["vy"] * 0.7 + dy * 0.3;
            k = world_per_px(p.currentTarget);
            set_cam(cam["x"] - dx * k, cam["y"] - dy * k, cam["w"]);
        } elif gesture["mode"] == 2.0 {
            if p.pointerId == gesture["id1"] {
                gesture["x"] = p.clientX;
                gesture["y"] = p.clientY;
            } elif p.pointerId == gesture["id2"] {
                gesture["x2"] = p.clientX;
                gesture["y2"] = p.clientY;
            }
            dx = gesture["x2"] - gesture["x"];
            dy = gesture["y2"] - gesture["y"];
            d = (dx * dx + dy * dy) ** 0.5;
            if gesture["dist"] > 0.0 and d > 0.0 {
                gesture["moved"] = gesture["moved"] + 10.0;
                apply_zoom(cam["w"] * gesture["dist"] / d);
                gesture["dist"] = d;
            }
        }
    }

    def pointer_up(e: Event) {
        p = e as any;
        if p.pointerId == gesture["id1"] or p.pointerId == gesture["id2"] {
            speed = (gesture["vx"] if gesture["vx"] > 0 else -gesture["vx"])
                  + (gesture["vy"] if gesture["vy"] > 0 else -gesture["vy"]);
            if gesture["mode"] == 1.0 and speed > 3.0 {
                motion["token"] = motion["token"] + 1.0;
                motion["mode"] = 1.0;
                motion["vx"] = gesture["vx"];
                motion["vy"] = gesture["vy"];
                motion["k"] = world_per_px(p.currentTarget);
                run_motion();
            }
            gesture["mode"] = 0.0;
            gesture["id1"] = -1.0;
            gesture["id2"] = -1.0;
            panning = False;
        }
    }

    def wheel(e: Event) {
        p = e as any;
        stop_motion();
        apply_zoom(cam["w"] * 1.12 if p.deltaY > 0 else cam["w"] / 1.12);
    }

    def zoom_in(_e: MouseEvent) {
        stop_motion();
        apply_zoom(cam["w"] / 1.3);
    }

    def zoom_out(_e: MouseEvent) {
        stop_motion();
        apply_zoom(cam["w"] * 1.3);
    }

    def zoom_reset(_e: MouseEvent) {
        stop_motion();
        fit_camera();
    }

    visible = [n for n in nodes if n.kind == "skill" or n.category not in hidden];

    at: dict[str, GraphNode] = {};
    for n in visible {
        at[n.id] = n;
    }

    # A tap that travelled is a pan, not a pick. Selecting glides the camera.
    def pick(id: str) -> None {
        if gesture["moved"] < 8.0 {
            if id != focus and id in at {
                glide_to(at[id].x, at[id].y);
            }
            onPick(id);
        }
    }

    def clear(_e: MouseEvent) {
        if gesture["moved"] < 8.0 {
            onClear();
        }
    }

    shown = [l for l in links if l.source in at and l.target in at];

    masteryOf: dict[str, float] = {};
    for s in skills {
        masteryOf[s.id] = s.mastery if s.mastery < 1.0 else 1.0;
    }

    # Neighbourhood of the focused node, so focus lights a whole cluster.
    # `focused` is tracked as its own bool rather than testing `len(near)`:
    # len() of a dict compiles to `undefined` in the browser, so the guard
    # silently never fires and no highlight class is ever applied.
    near: dict[str, bool] = {};
    focused = False;

    if focus and focus in at {
        near[focus] = True;
        focused = True;
        for l in shown {
            if l.source == focus {
                near[l.target] = True;
            }
            if l.target == focus {
                near[l.source] = True;
            }
        }
    }

    vh = vw * WORLD_H / WORLD_W;
    box = str(vx) + " " + str(vy) + " " + str(vw) + " " + str(vh);

    return <div className="graph-wrap">
        <svg
            className={"graph-svg panning" if panning else "graph-svg"}
            viewBox={box}
            preserveAspectRatio="xMidYMid meet"
            onPointerDown={pointer_down}
            onPointerMove={pointer_move}
            onPointerUp={pointer_up}
            onPointerCancel={pointer_up}
            onWheel={wheel}
        >
            <rect x={vx - vw} y={vy - vh} width={vw * 3} height={vh * 3} fill="transparent" onClick={clear}/>

            {for l in shown {
                <path
                    key={l.source + "-" + l.target}
                    className={"glink builds" if l.kind == "builds" else "glink"}
                    d={edge_path(at[l.source].x, at[l.source].y, at[l.target].x, at[l.target].y)}
                    fill="none"
                    pathLength={1}
                    strokeWidth={1.8}
                    strokeOpacity={
                        0.9 if focused and l.source in near and l.target in near
                        else (0.06 if focused else 0.12 + l.weight * 0.4)
                    }
                />
            }}

            {for (i, n) in enumerate(visible) {
                <GraphNodeMark
                    key={n.id}
                    item={n}
                    index={i}
                    mastery={masteryOf[n.id] if n.id in masteryOf else 0.0}
                    dim={focused and n.id not in near}
                    lit={focused and n.id == focus}
                    labelled={n.kind == "skill" or (focused and n.id in near)}
                    onPick={pick}
                />
            }}
        </svg>

        <div className="zoom-controls">
            <button className="zoom-btn" onClick={zoom_in} aria-label="Zoom in">+</button>
            <button className="zoom-btn" onClick={zoom_out} aria-label="Zoom out">&minus;</button>
            <button className="zoom-btn" onClick={zoom_reset} aria-label="Fit graph">
                <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor"
                    strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                    <path d="M3 9V5a2 2 0 0 1 2-2h4M15 3h4a2 2 0 0 1 2 2v4M21 15v4a2 2 0 0 1-2 2h-4M9 21H5a2 2 0 0 1-2-2v-4"/>
                </svg>
            </button>
        </div>
    </div>;
}
