import axios from "axios";
import Link from "next/link";
import { signIn, signOut, useSession } from "next-auth/react";
import { useMemo, useState } from "react";
import useSWR from "swr";

const fetcher = (url: string) => axios.get(url).then((response) => response.data);

type NoteListItem = {
  id: string;
  title: string;
  plainText: string;
  isPinned: boolean;
  updatedAt: string;
  tags: {
    id: string;
    name: string;
  }[];
};

export default function Home() {
  const { data: session, status } = useSession();
  const [q, setQ] = useState("");

  const notesUrl = useMemo(() => {
    if (!session) return null;

    const params = new URLSearchParams();

    if (q.trim()) {
      params.set("q", q.trim());
    }

    const suffix = params.toString();

    return `/api/notes${suffix ? `?${suffix}` : ""}`;
  }, [q, session]);

  const { data: notes, mutate, isLoading } = useSWR<NoteListItem[]>(notesUrl, fetcher);

  async function createNote() {
    const response = await axios.post("/api/notes", {
      title: "New note",
      content: "<p></p>",
      tags: []
    });

    await mutate();

    window.location.href = `/note/${response.data.id}`;
  }

  return (
    <main className="app-shell">
      <section className="hero-card">
        <div>
          <p className="eyebrow">Production Notes</p>
          <h1>Private, searchable, revision-safe notes.</h1>
          <p className="subtitle">
            A clean Next.js + Prisma notes app foundation with authentication, rich editing, tags,
            archive state, revision history, and CI-ready structure.
          </p>
        </div>

        <div className="auth-panel">
          {status === "loading" ? (
            <span>Checking session...</span>
          ) : session ? (
            <>
              <span className="signed-in">
                Signed in as {session.user?.email || session.user?.name}
              </span>
              <button className="secondary-button" onClick={() => signOut()}>
                Sign out
              </button>
            </>
          ) : (
            <button className="primary-button" onClick={() => signIn()}>
              Sign in
            </button>
          )}
        </div>
      </section>

      {session ? (
        <section className="notes-card">
          <div className="toolbar">
            <input
              aria-label="Search notes"
              placeholder="Search notes..."
              value={q}
              onChange={(event) => setQ(event.target.value)}
            />
            <button className="primary-button" onClick={createNote}>
              New Note
            </button>
          </div>

          {isLoading ? <p className="muted">Loading notes...</p> : null}

          <div className="notes-grid">
            {notes?.map((note) => (
              <Link key={note.id} href={`/note/${note.id}`} className="note-card">
                <div className="note-card-top">
                  <h2>{note.title}</h2>
                  {note.isPinned ? <span className="pin">Pinned</span> : null}
                </div>

                <p>{note.plainText || "No content yet."}</p>

                <div className="note-meta">
                  <span>{new Date(note.updatedAt).toLocaleString()}</span>
                  <span>{note.tags.map((tag) => tag.name).join(", ")}</span>
                </div>
              </Link>
            ))}
          </div>

          {!isLoading && notes?.length === 0 ? (
            <p className="muted">No notes found. Create your first note.</p>
          ) : null}
        </section>
      ) : (
        <section className="notes-card">
          <p className="muted">Sign in to create and manage your notes.</p>
        </section>
      )}
    </main>
  );
}
