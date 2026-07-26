"""Neurotech - Entry Point.

One module wiring the two halves together: the object-spatial brain on the
server and the React UI in the browser. The server import registers the
endpoints; the `cl` block mounts the client shell.
"""

import from endpoints { Thought, Link, LoadBrain, create_thought, delete_thought }

# Client-side UI
cl {
    import from .frontend { app as ClientApp }

    def:pub app -> JsxElement {
        return <ClientApp/>;
    }
}
