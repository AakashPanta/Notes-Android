const { PrismaClient } = require("@prisma/client");

const prisma = new PrismaClient();

async function main() {
  await prisma.$executeRawUnsafe(`
    CREATE INDEX IF NOT EXISTS note_search_idx
    ON "Note"
    USING GIN (
      to_tsvector('english', coalesce("title", '') || ' ' || coalesce("plainText", ''))
    );
  `);

  console.log("PostgreSQL full-text search index is ready.");
}

main()
  .catch((error) => {
    console.error(error);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
