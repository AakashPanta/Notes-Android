import { prisma } from "../lib/prisma";

async function main() {
  const user = await prisma.user.upsert({
    where: { email: "demo@example.com" },
    update: {},
    create: {
      email: "demo@example.com",
      name: "Demo User"
    }
  });

  await prisma.note.create({
    data: {
      title: "Welcome to Production Notes",
      content: "<p>This is your first production-ready note.</p>",
      plainText: "This is your first production-ready note.",
      authorId: user.id,
      versions: {
        create: {
          content: "<p>This is your first production-ready note.</p>",
          authorId: user.id
        }
      }
    }
  });

  console.log(`Seeded ${user.email}`);
}

main()
  .catch((error) => {
    console.error(error);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
