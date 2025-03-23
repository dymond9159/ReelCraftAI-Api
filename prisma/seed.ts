import { hash } from "bcrypt";
import { PrismaClient } from "@prisma/client";
import { adminData } from "./seeds/seed-data";

const prisma = new PrismaClient();

async function main() {
  // Seed SuperAdmin, Admin users
  if (adminData && adminData?.length > 0) {
    const hashedUsers = await Promise.all(
      adminData.map(async user => ({
        ...user,
        password: await hash(user.password, 10),
        emailVerified: true,
      })),
    );

    try {
      for (const user of hashedUsers) {
        const one = await prisma.user.findUnique({
          where: { email: user.email },
        });
        if (!one) {
          await prisma.user.create({
            data: user,
          });
        } else {
          await prisma.user.update({
            where: { email: user.email },
            data: user,
          });
        }
      }
    } catch (err) {
      console.log(err);
    }
  }
}

main()
  .catch(e => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
