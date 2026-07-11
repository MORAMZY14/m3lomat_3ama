FIXED JAVASCRIPT FIREBASE FUNCTIONS
===================================

This folder is now JavaScript-only for deployment:
- Firebase entry file: index.js
- Node runtime: 22
- No TypeScript compiler is required.
- The "npm run build" command is intentionally a no-op, so an existing
  Firebase predeploy hook that runs "npm run build" will still succeed.

INSTALL AND DEPLOY
------------------
1. Install/use Node.js 22. Verify:
   node -v

2. From this functions folder:
   npm install
   npm run build

3. Set the OpenAI secret if it has not been set yet:
   firebase functions:secrets:set OPENAI_API_KEY

4. From the Firebase project root (the folder containing firebase.json):
   firebase deploy --only functions

IMPORTANT
---------
- Do not edit or restore src/index.ts, lib/index.js, or tsconfig.json.
- Do not put the OpenAI API key in index.js, .env, Flutter, or GitHub.
- Revoke the API key that was previously exposed and use a newly-created key.
