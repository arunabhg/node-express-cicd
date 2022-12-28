import express, { Request, Response } from "express";

const app = express();
const port = 3000;

app.get("/", (req: Request, res: Response) => {
	res.send("Hello World from Node & Express CI-CD!!)");
});

app.get("/work", (req: Request, res: Response) => {
	res.send("Work is going good");
});

app.listen(port, () => {
	// eslint-disable-next-line no-console
	console.log(`Server listening on port: ${port}`);
});
