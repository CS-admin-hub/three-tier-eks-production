const tasks = require("./routes/tasks");
const connection = require("./db");
const cors = require("cors");
const express = require("express");
const app = express();

connection();

app.use(express.json());
app.use(cors());

// Health endpoint - required for K8s liveness/readiness probes
app.get('/health', (req, res) => {
    res.status(200).json({ status: 'ok' });
});

app.use("/api/tasks", tasks);

const port = process.env.PORT || 8080;
app.listen(port, () => console.log(`Listening on port ${port}...`));