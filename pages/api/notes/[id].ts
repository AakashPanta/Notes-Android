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

  const id = String(req.query.id || "");

  if (!id) {
    return res.status(400).json({ error: "Missing note id" });
  }

  if (req.method === "GET") {
    const note = await prisma.note.findFirst({
      where: {
        id,
        authorId: user.id
      },
      include: {
        tags: true,
        notebook: true,
        versions: {
          orderBy: {
            createdAt: "desc"
          },
          take: 50
        }
      }
    });

    if (!note) {
      return res.status(404).json({ error: "Not found" });
    }

    return res.status(200).json(note);
  }

  if (req.method === "PUT") {
    const existing = await prisma.note.findFirst({
      where: {
        id,
        authorId: user.id
      }
    });

    if (!existing) {
      return res.status(404).json({ error: "Not found" });
    }

    const title =
      typeof req.body.title === "string" && req.body.title.trim()
        ? req.body.title.trim()
        : existing.title;

    const content = typeof req.body.content === "string" ? req.body.content : existing.content;
    const tags = normalizeTags(req.body.tags);
    const plainText = stripHtml(content);

    const updated = await prisma.note.update({
      where: {
        id
      },
      data: {
        title,
        content,
        plainText,
        isPinned: typeof req.body.isPinned === "boolean" ? req.body.isPinned : existing.isPinned,
        isArchived: typeof req.body.isArchived === "boolean" ? req.body.isArchived : existing.isArchived,
        isEncrypted:
          typeof req.body.isEncrypted === "boolean" ? req.body.isEncrypted : existing.isEncrypted,
        versionCount: {
          increment: 1
        },
        tags: {
          set: [],
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

    return res.status(200).json(updated);
  }

  if (req.method === "DELETE") {
    const existing = await prisma.note.findFirst({
      where: {
        id,
        authorId: user.id
      }
    });

    if (!existing) {
      return res.status(404).json({ error: "Not found" });
    }

    await prisma.note.delete({
      where: {
        id
      }
    });

    return res.status(200).json({ ok: true });
  }

  res.setHeader("Allow", "GET, PUT, DELETE");
  return res.status(405).json({ error: "Method not allowed" });
}
