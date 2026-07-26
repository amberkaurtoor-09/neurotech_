"""A small modal confirm. Destructive actions never fire on first tap."""

def:pub ConfirmDialog(
    title: str,
    body: str,
    action: str,
    busy: bool,
    onConfirm: Callable[[], None],
    onCancel: Callable[[], None]
) -> JsxElement {
    def go(_e: MouseEvent) {
        onConfirm();
    }

    def stay(_e: MouseEvent) {
        onCancel();
    }

    return <div>
        <div className="backdrop" onClick={stay}></div>
        <div className="confirm-card" role="alertdialog" aria-label={title}>
            <h3>{title}</h3>
            <p>{body}</p>
            <div className="confirm-actions">
                <button className="confirm-cancel" onClick={stay} disabled={busy}>Cancel</button>
                <button className="confirm-go" onClick={go} disabled={busy}>
                    {"Working..." if busy else action}
                </button>
            </div>
        </div>
    </div>;
}
