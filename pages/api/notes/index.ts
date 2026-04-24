import type { NextApiRequest, NextApiResponse } from "next";
import { getServerSession } from "next-auth/next";
import { authOptions } from "../auth/[...nextauth]";
import { prisma } from "../../../lib/prisma";
import { normalizeTags, stripHtml } from "../../../lib/text";

async function getCurrentUser(req: NextApiRequest, res: NextApiResponse) {
  const session = await getServerSession(req, res, authOptions);
  const email = session?.user?.email;

  if (!email) return null;

  return prisma.user.findUnique({ where: { email } });
}

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  const user = await getCurrentUser(req, res);

  if (!user) {
    return res.status(401).json({ error: "Unauthorized" });
  }

  if (req.method === "GET") {
    const { q, tag, notebook, archived } = req.query;
    const include = { tags: true, notebook: true };

    if (q && String(q).trim()) {
      const search = String(q).trim();

      const rows = await prisma.$queryRaw<{ id: string }[]>`
        SELECT "id"
        FROM "Note"
        WHERE "authorId" = ${user.id}
          AND "isArchived" = ${archived === "true"}
          AND to_tsvector('english', coalesce("title", '') || ' ' || coalesce("plainText", ''))
              @@ plainto_tsquery('english', ${search})
        ORDER BY "updatedAt" DESC
        LIMIT 200
      `;

      const ids = rows.map((row) => row.id);
      const order = new Map(ids.map((id, index) => [id, index]));

      const notes = await prisma.note.findMany({
        where: {
          id: { in: ids },
          authorId: user.id
        },
        include
      });

      notes.sort((a, b) => (order.get(a.id) ?? 0) - (order.get(b.id) ?? 0));

      return res.status(200).json(notes);
    }

    const notes = await prisma.note.findMany({
      where: {
        authorId: user.id,
        isArchived: archived === "true",
        ...(notebook ? { notebookId: String(notebook) } : {}),
        ...(tag
          ? {
              tags: {
                some: {
                  ownerId: user.id,
                  name: String(tag).toLowerCase()
                }
              }
            }
          : {})
      },
      orderBy: [{ isPinned: "desc" }, { updatedAt: "desc" }],
      take: 200,
      include
    });

    return res.status(200).json(notes);
  }

  if (req.method === "POST") {
    const title =
      typeof req.body.title === "string" && req.body.title.trim()
        ? req.body.title.trim()
        : "Untitled";

    const content = typeof req.body.content === "string" ? req.body.content : "";
    const notebookId = typeof req.body.notebookId === "string" ? req.body.notebookId : undefined;
    const tags = normalizeTags(req.body.tags);
    const plainText = stripHtml(content);

    if (notebookId) {
      const notebook = await prisma.notebook.findFirst({
        where: {
          id: notebookId,
          ownerId: user.id
        },
        select: {
          id: true
        }
      });

      if (!notebook) {
        return res.status(400).json({ error: "Invalid notebook" });
      }
    }

    const note = await prisma.note.create({
      data: {
        title,
        content,
        plainText,
        authorId: user.id,
        notebookId,
        isEncrypted: Boolean(req.body.isEncrypted),
        tags: {
          connectOrCreate: tags.map((name) => ({
            where: {
              ownerId_name: {
                ownerId: user.id,
                name
              }
            },
            create: {
              ownerId: user.id,
              name
            }
          }))
        },
        versions: {
          create: {
            content,
            authorId: user.id
          }
        }
      },
      include: {
        tags: true,
        notebook: true
      }
    });

    return res.status(201).json(note);
  }

  res.setHeader("Allow", "GET, POST");
  return res.status(405).json({ error: "Method not allowed" });
}
