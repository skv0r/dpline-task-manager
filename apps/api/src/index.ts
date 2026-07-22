import { config } from "dotenv";
import { resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { createServer } from "node:http";

const rootDir = resolve(fileURLToPath(new URL(".", import.meta.url)), "../../..");
config({ path: resolve(rootDir, ".env") });

const PORT = Number(process.env.PORT) || 3001;
const databaseUrl = process.env.DATABASE_URL;

const server = createServer((req, res) => {
    if (req.method === "GET" && req.url === "/health") {
        res.writeHead(200, {"Content-Type": "application/json"});
        res.end(JSON.stringify({
            status: "ok",
            databaseUrlConfigured: Boolean(databaseUrl),
        }));
        
        return;
    }

    res.writeHead(404, {"Content-Type": "application/json"});
    res.end(JSON.stringify({error: "Not Found"}));
})

server.listen(PORT, () => {
    console.log(`API listening on http://localhost:${PORT}`)
    if (databaseUrl) {
        // пароль в лог не светим
        const safe = databaseUrl.replace(/:[^:@/]+@/, ":****@");
        console.log(`DATABASE_URL: ${safe}`);
      } else {
        console.log("DATABASE_URL: not set (скопируй .env.example → .env в корне)");
      }
})