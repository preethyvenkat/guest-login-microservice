const express = require('express');
const bodyParser = require('body-parser');
const jwt = require('jsonwebtoken');

const app = express();
const PORT = process.env.PORT || 3000;
const SECRET = process.env.JWT_SECRET || 'dummy_secret';

app.use(bodyParser.json());

const users = [{ email: 'user@example.com', password: 'pass123' }];

app.post('/login', (req, res) => {
  const { email, password } = req.body;
  const user = users.find(u => u.email === email && u.password === password);
  if (!user) return res.status(401).send({ error: 'Invalid credentials' });
  const token = jwt.sign({ email: user.email }, SECRET, { expiresIn: '1h' });
  res.send({ token });
});

app.listen(PORT, () => console.log(`Login service running on port ${PORT}`));

app.get('/healthz', (req, res) => res.sendStatus(200));

app.get('/metrics', (req, res) => {
  res.set('Content-Type', 'text/plain');
  res.send('http_requests_total 1\n'); // Replace with real metrics later
});


#app.get('/healthz/live', (req, res) => res.sendStatus(200));

#app.get('/healthz/ready', (req, res) => {
 # // perform readiness checks here (e.g., DB ping)
 # res.sendStatus(200);
#});
