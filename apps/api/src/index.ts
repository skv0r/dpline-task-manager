import { createServer } from "node:http";

const PORT = Number(process.env.PORT) || 3001

const server = createServer((req, res) => {
    if (req.method === "GET" && req.url === "/health") {
        res.writeHead(200, {"Content-Type": "application/json"});
        res.end(JSON.stringify({status: "ok"}));
        return;
    }

    res.writeHead(404, {"Content-Type": "application/json"});
    res.end(JSON.stringify({error: "Not Found"}));
})

server.listen(PORT, () => {
    console.log(`API listening on http://localhost:${PORT}`)
})