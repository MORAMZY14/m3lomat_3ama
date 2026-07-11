import { applicationDefault, initializeApp } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";

async function main(): Promise<void> {
  initializeApp({ credential: applicationDefault() });

  const email = process.argv[2]?.trim();
  if (!email) {
    throw new Error("Usage: npm run set-admin -- admin@example.com");
  }

  const auth = getAuth();
  const user = await auth.getUserByEmail(email);
  await auth.setCustomUserClaims(user.uid, { ...(user.customClaims ?? {}), admin: true });
  console.log(`Admin claim enabled for ${email}. Sign out and in again to refresh the token.`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
