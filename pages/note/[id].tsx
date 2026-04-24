import axios from "axios";
import { useRouter } from "next/router";
import { useEffect, useState } from "react";
import useSWR from "swr";
import Editor from "../../components/Editor";

const fetcher = (url: string) => axios.get(url).then((response) => response.data);

type Note = {
  id: string;
  title: string;
  content: string;
  isPinned: boolean;
  isArchived: boolean;
  tags: {
    id: string;
    name: string;
  }[];
  versions: {
    id: string;
    createdAt: string;
  }[];
};

export default function NotePage() {
  const router = useRouter();
  const id = typeof router.query.id === "string" ? router.query.id : "";

  const { data: note, mutate, isLoading } = useSWR<Note>(
    id ? `/api/notes/${id}` : null,
    fetcher
  );

  const [title, setTitle] = useState("");
  const [content, setContent] = useState("");
  const [tagText, setTagText] = useState("");
  const [isPinned, setIsPinned] = useState(false);
  const [isArchived, setIsArchived] = useState(false);
  const [isSaving, setIsSaving] = useState(false);

  useEffect(() => {
    if (!note) return;

    setTitle(note.title || "Untitled");
    setContent(note.content || "");
    setTagText(note.tags?.map((tag) => tag.name).join(", ") || "");
    setIsPinned(Boolean(note.isPinned));
    setIsArchived(Boolean(note.isArchived));
  }, [note]);

  async function save() {
    if (!id) return;

    setIsSaving(true);

    try {
      await axios.put(`/api/notes/${id}`, {
        title,
        content,
        isPinned,
        isArchived,
        tags: tagText
          .split(",")
          .map((tag) => tag.trim())
          .filter(Boolean)
      });

      await mutate();
    } finally {
      setIsSaving(false);
    }
  }

  async function remove() {
    if (!id) return;

    const confirmed = window.confirm("Delete this note permanently?");

    if (!confirmed) return;

    await axios.delete(`/api/notes/${id}`);
    await router.push("/");
  }

  if (isLoading || !note) {
    return <main className="app-shell">Loading note...</main>;
  }

  return (
    <main className="app-shell">
      <section className="editor-card">
        <div className="editor-header">
          <button className="secondary-button" onClick={() => router.push("/")}>
            Back
          </button>

          <div className="editor-actions">
            <button className="secondary-button danger" onClick={remove}>
              Delete
            </button>

            <button className="primary-button" onClick={save} disabled={isSaving}>
              {isSaving ? "Saving..." : "Save"}
            </button>
          </div>
        </div>

        <input
          className="title-input"
          aria-label="Note title"
          value={title}
          onChange={(event) => setTitle(event.target.value)}
        />

        <div className="metadata-row">
          <label>
            <input
              type="checkbox"
              checked={isPinned}
              onChange={(event) => setIsPinned(event.target.checked)}
            />
            Pinned
          </label>

          <label>
            <input
              type="checkbox"
              checked={isArchived}
              onChange={(event) => setIsArchived(event.target.checked)}
            />
            Archived
          </label>
        </div>

        <input
          className="tag-input"
          aria-label="Tags"
          placeholder="Tags, separated by commas"
          value={tagText}
          onChange={(event) => setTagText(event.target.value)}
        />

        <Editor value={content} onChange={setContent} />
      </section>

      <section className="versions-card">
        <h2>Versions</h2>

        <ul>
          {note.versions?.map((version) => (
            <li key={version.id}>{new Date(version.createdAt).toLocaleString()}</li>
          ))}
        </ul>
      </section>
    </main>
  );
}
