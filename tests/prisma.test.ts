import { prisma } from "../lib/prisma";

afterAll(async () => {
  await prisma.$disconnect();
});

describe("database smoke test", () => {
  it("connects to PostgreSQL", async () => {
    const result = await prisma.$queryRaw<{ now: Date }[]>`select now()`;
    expect(result[0]?.now).toBeDefined();
  });
});
