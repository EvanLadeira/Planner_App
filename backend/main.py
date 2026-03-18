from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from datetime import datetime
from typing import Optional
import sqlite3

app = FastAPI()

# ── Base de données ──────────────────────────────────────────
def get_db():
    conn = sqlite3.connect("calendrier.db")
    conn.row_factory = sqlite3.Row
    return conn

def init_db():
    conn = get_db()
    conn.execute("""
        CREATE TABLE IF NOT EXISTS events (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            description TEXT DEFAULT '',
            start TEXT NOT NULL,
            end TEXT NOT NULL,
            color TEXT DEFAULT '#6C63FF',
            category_id INTEGER
        )
    """)
    conn.execute("""
        CREATE TABLE IF NOT EXISTS event_categories (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            color TEXT NOT NULL DEFAULT '#6C63FF'
        )
    """)
    conn.execute("""
        CREATE TABLE IF NOT EXISTS themes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            color TEXT NOT NULL DEFAULT '#6366f1',
            parent_id INTEGER,
            FOREIGN KEY (parent_id) REFERENCES themes(id)
        )
    """)
    conn.execute("""
        CREATE TABLE IF NOT EXISTS todos (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            done INTEGER DEFAULT 0,
            due TEXT,
            theme_id INTEGER,
            parent_id INTEGER,
            FOREIGN KEY (theme_id) REFERENCES themes(id),
            FOREIGN KEY (parent_id) REFERENCES todos(id)
        )
    """)
    # Migrations
    migrations = [
        "ALTER TABLE todos ADD COLUMN theme_id INTEGER",
        "ALTER TABLE todos ADD COLUMN parent_id INTEGER",
        "ALTER TABLE events ADD COLUMN color TEXT DEFAULT '#6C63FF'",
        "ALTER TABLE events ADD COLUMN description TEXT DEFAULT ''",
        "ALTER TABLE events ADD COLUMN category_id INTEGER",
    ]
    for migration in migrations:
        try:
            conn.execute(migration)
        except Exception:
            pass
    conn.commit()
    conn.close()

init_db()

# ── Modèles ──────────────────────────────────────────────────
class Event(BaseModel):
    title: str
    description: str = ""
    start: datetime
    end: datetime
    color: str = "#6C63FF"
    category_id: Optional[int] = None

class EventCategory(BaseModel):
    name: str
    color: str = "#6C63FF"

class Todo(BaseModel):
    title: str
    due: Optional[datetime] = None
    theme_id: Optional[int] = None
    parent_id: Optional[int] = None

class Theme(BaseModel):
    name: str
    color: str = "#6366f1"
    parent_id: Optional[int] = None

# ── Routes Event Categories ──────────────────────────────────
@app.get("/event-categories")
def get_event_categories():
    conn = get_db()
    categories = conn.execute("SELECT * FROM event_categories").fetchall()
    conn.close()
    return [dict(c) for c in categories]

@app.post("/event-categories")
def create_event_category(category: EventCategory):
    conn = get_db()
    conn.execute(
        "INSERT INTO event_categories (name, color) VALUES (?, ?)",
        (category.name, category.color)
    )
    conn.commit()
    conn.close()
    return {"message": "Catégorie créée !", "category": category}

@app.delete("/event-categories/{category_id}")
def delete_event_category(category_id: int):
    conn = get_db()
    conn.execute("DELETE FROM event_categories WHERE id = ?", (category_id,))
    conn.commit()
    conn.close()
    return {"message": "Catégorie supprimée !"}

# ── Routes Events ────────────────────────────────────────────
@app.get("/events")
def get_events():
    conn = get_db()
    events = conn.execute("""
        SELECT events.*, event_categories.name as category_name
        FROM events
        LEFT JOIN event_categories ON events.category_id = event_categories.id
    """).fetchall()
    conn.close()
    return [dict(e) for e in events]

@app.post("/events")
def create_event(event: Event):
    conn = get_db()
    conn.execute(
        "INSERT INTO events (title, description, start, end, color, category_id) VALUES (?, ?, ?, ?, ?, ?)",
        (event.title, event.description, str(event.start), str(event.end), event.color, event.category_id)
    )
    conn.commit()
    conn.close()
    return {"message": "Événement créé !", "event": event}

@app.get("/events/{event_id}")
def get_event(event_id: int):
    conn = get_db()
    event = conn.execute("""
        SELECT events.*, event_categories.name as category_name
        FROM events
        LEFT JOIN event_categories ON events.category_id = event_categories.id
        WHERE events.id = ?
    """, (event_id,)).fetchone()
    conn.close()
    if not event:
        raise HTTPException(status_code=404, detail="Événement introuvable")
    return dict(event)

@app.put("/events/{event_id}")
def update_event(event_id: int, event: Event):
    conn = get_db()
    conn.execute("""
        UPDATE events SET title=?, description=?, start=?, end=?, color=?, category_id=?
        WHERE id=?
    """, (event.title, event.description, str(event.start), str(event.end), event.color, event.category_id, event_id))
    conn.commit()
    conn.close()
    return {"message": "Événement mis à jour !"}

@app.delete("/events/{event_id}")
def delete_event(event_id: int):
    conn = get_db()
    conn.execute("DELETE FROM events WHERE id = ?", (event_id,))
    conn.commit()
    conn.close()
    return {"message": "Événement supprimé !"}

# ── Routes Todos ─────────────────────────────────────────────
@app.get("/todos")
def get_todos():
    conn = get_db()
    todos = conn.execute("""
        SELECT todos.*, themes.name as theme_name, themes.color as theme_color
        FROM todos
        LEFT JOIN themes ON todos.theme_id = themes.id
    """).fetchall()
    conn.close()
    return [dict(t) for t in todos]

@app.post("/todos")
def create_todo(todo: Todo):
    conn = get_db()
    conn.execute(
        "INSERT INTO todos (title, due, theme_id, parent_id) VALUES (?, ?, ?, ?)",
        (todo.title, str(todo.due) if todo.due else None, todo.theme_id, todo.parent_id)
    )
    conn.commit()
    conn.close()
    return {"message": "Todo créé !", "todo": todo}

@app.patch("/todos/{todo_id}/done")
def complete_todo(todo_id: int):
    conn = get_db()
    todo = conn.execute("SELECT * FROM todos WHERE id = ?", (todo_id,)).fetchone()
    if not todo:
        raise HTTPException(status_code=404, detail="Todo introuvable")
    conn.execute("UPDATE todos SET done = 1 WHERE id = ?", (todo_id,))
    conn.commit()
    conn.close()
    return {"message": "Todo complété !"}

@app.delete("/todos/{todo_id}")
def delete_todo(todo_id: int):
    conn = get_db()
    conn.execute("DELETE FROM todos WHERE id = ?", (todo_id,))
    conn.commit()
    conn.close()
    return {"message": "Todo supprimé !"}

@app.post("/todos/{todo_id}/subtodos")
def create_subtodo(todo_id: int, todo: Todo):
    conn = get_db()
    conn.execute(
        "INSERT INTO todos (title, due, theme_id, parent_id) VALUES (?, ?, ?, ?)",
        (todo.title, str(todo.due) if todo.due else None, todo.theme_id, todo_id)
    )
    conn.commit()
    conn.close()
    return {"message": "Sous-tâche créée !"}

# ── Routes Themes ────────────────────────────────────────────
@app.get("/themes")
def get_themes():
    conn = get_db()
    themes = conn.execute("SELECT * FROM themes").fetchall()
    conn.close()
    return [dict(t) for t in themes]

@app.post("/themes")
def create_theme(theme: Theme):
    conn = get_db()
    conn.execute(
        "INSERT INTO themes (name, color, parent_id) VALUES (?, ?, ?)",
        (theme.name, theme.color, theme.parent_id)
    )
    conn.commit()
    conn.close()
    return {"message": "Thème créé !", "theme": theme}

@app.delete("/themes/{theme_id}")
def delete_theme(theme_id: int):
    conn = get_db()
    conn.execute("DELETE FROM themes WHERE id = ?", (theme_id,))
    conn.commit()
    conn.close()
    return {"message": "Thème supprimé !"}