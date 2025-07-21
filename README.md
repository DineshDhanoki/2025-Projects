# AgentForge (Kogo_Clone)

## 🚀 Introduction

**AgentForge** is a full-stack platform for building, deploying, and managing intelligent AI agents. It features a modern Next.js frontend and a robust Node.js/Express backend, with support for authentication, vector storage, and extensible agent logic.

---

## 🌟 Project Vision & Philosophy

AgentForge aims to make building, deploying, and managing AI agents as easy and enjoyable as possible for both developers and non-developers. We believe in:

- **Simplicity:** Easy setup, clear code, and intuitive UI.
- **Extensibility:** Modular backend and frontend for rapid feature addition.
- **Transparency:** Well-documented code and APIs.
- **Security & Privacy:** Your data, your rules.

---

## 📁 Project Structure Overview

Kogo_Clone/
  backend/      # Node.js/Express API, Prisma, agent logic
  frontend/     # Next.js app, React components, UI
  scripts/      # Deployment and setup scripts
  package.json  # Monorepo root (if used)

---

## 🛠️ Backend

 Tech Stack

- Node.js, Express.js
- Prisma ORM (SQLite by default)
- ChromaDB (vector storage, optional)
- NextAuth.js (for authentication)
- Docker (optional for deployment)

### Folder & File Structure

backend/
  src/
    config/         # Configuration files (DB, Chroma, etc.)
    controllers/    # Route controllers (business logic for each API route)
    middleware/     # Express middleware (auth, error handling, logging, etc.)
    models/         # Prisma models (User, Agent, Chat, etc.)
    routes/         # Express route definitions (agents.js, chat.js, etc.)
    services/       # Business logic/services (agentService.js, chromaService.js, etc.)
    utils/          # Helpers, constants, logger
  tests/            # Unit/integration tests
  app.js            # Main Express app
  server.js         # Server entry point
  Dockerfile        # For containerization
  docker-compose.yml# For multi-service local dev
  Prisma/           # Prisma schema, migrations, seed script

### Key Files Explained

- **app.js:** Sets up Express, middleware, and routes.
- **server.js:** Starts the server (entry point).
- **src/routes/**: Each file defines API endpoints (e.g., `agents.js` for `/api/agents`).
- **src/controllers/**: Functions that handle requests for each route.
- **src/services/**: Core business logic, reusable across controllers.
- **src/middleware/**: Auth, error handling, CORS, logging, rate limiting, etc.
- **src/models/**: Prisma models for database tables.
- **Prisma/schema.prisma:** Database schema (edit and run `npx prisma migrate dev` to update DB).
- **Prisma/seed.js:** Script to seed the database with initial data.

### Example: Adding a New API Route

1. Create a new file in `src/routes/` (e.g., `tasks.js`).
2. Add a controller in `src/controllers/` (e.g., `taskController.js`).
3. Add business logic in `src/services/` if needed.
4. Register the route in `app.js`.

### Example API Request

```http
POST /api/agents
Content-Type: application/json
{
  "name": "SupportBot",
  "description": "Handles support tickets"
}
```

**Response:**

```json
{
  "id": 1,
  "name": "SupportBot",
  "status": "active"
}
```

### Error Handling & Logging

- All errors are caught by middleware in `src/middleware/errorHandler.js`.
- Logs are written to `backend/logs/` (combined.log, error.log).
- Use `logger.js` in `utils/` for custom logging.

### Authentication

- Uses NextAuth.js for session-based auth.
- Auth middleware in `src/middleware/auth.js`.
- User model in `src/models/User.js`.
- Example: Protect a route by adding `auth` middleware.

### ChromaDB Usage

- Used for vector storage (memory, embeddings).
- Configure in `src/config/chroma.js`.
- Example usage in `src/services/chromaService.js`.
- If ChromaDB is not running, a mock is used for dev.

### Database Seeding & Reset

- Edit `Prisma/seed.js` to add initial data.
- Run with:

  ```bash
  node Prisma/seed.js
  ```

- To reset DB:

  ```bash
  npx prisma migrate reset
  ```

### Running Tests

- Tests are in `backend/tests/` (unit/integration).
- Run all tests:

  ```bash
  npm test
  ```

- Add new tests in `tests/unit/` or `tests/integration/`.

### Deployment

- Use Docker for local/prod:

  ```bash
  docker-compose up --build
  ```

- Or deploy to Railway, Render, etc.
- Set environment variables in your deployment platform.

---

## 💻 Frontend

### Tech Stack

- Next.js (React)
- Tailwind CSS
- NextAuth.js (for authentication)
- Framer Motion (animations)
- Lucide React (icons)

 Folder & File Structure

frontend/
  components/
    agent/          # Agent-related UI
    chat/           # Chat UI
    dashboard/      # Dashboard widgets
    layout/         # Layouts (nav, footer, etc.)
    logs/           # Log UI
    ui/             # UI primitives (Button, Card, etc.)
    user/           # User profile/settings
  lib/              # API/auth/utils
  pages/            # Next.js pages & API routes
  public/           # Static assets
  styles/           # Tailwind/global CSS

Key Files Explained

- **pages/_app.js:** App entry, wraps all pages with providers/layout.
- **pages/index.js:** Home/landing page.
- **pages/dashboard.js:** Main dashboard page.
- **components/layout/public-layout.js:** Global nav bar and footer.
- **components/ui/button.js:** Reusable button component.
- **lib/auth.js:** Auth/session helpers for client/server.

### Adding a New Page or Component

- Add a new file to `pages/` for a new route (e.g., `pages/about.js`).
- Add a new component to `components/` and import it where needed.
- Use Tailwind classes for styling.

### Theming & Styling

- Tailwind CSS is used throughout.
- Theme toggle in nav bar (light/dark mode).
- To add a new color or extend the theme, edit `tailwind.config.js`.

### Authentication in the UI

- Uses NextAuth.js for login/session.
- Use `useSession` from `next-auth/react` in components.
- Protect pages by checking session in `getServerSideProps` or with hooks.

### Using the API from the Frontend

- Use `fetch` or `axios` to call backend endpoints (see `lib/api.js`).
- Example:

  ```js
  import { getSession } from "next-auth/react";
  const res = await fetch("/api/agents");
  const data = await res.json();
  ```

### Adding a Protected Route

- In your page, use:

  ```js
  import { getServerAuthSession } from "../lib/auth";
  export async function getServerSideProps(ctx) {
    const session = await getServerAuthSession(ctx);
    if (!session) {
      return { redirect: { destination: "/", permanent: false } };
    }
    return { props: { session } };
  }
  ```

Running Tests

- (Add your preferred testing setup, e.g., Jest, React Testing Library.)
- Place tests in a `__tests__` folder or next to components.

Deployment

- Deploy to Vercel, Netlify, or Docker.
- Set environment variables in your deployment platform.
- Build for production:

  ```bash
  npm run build
  npm start
  ```

---

## ⚙️ DevOps & Deployment

- **Docker:** Use `docker-compose.yml` for local multi-service dev. Edit ports as needed.
- **Vercel/Netlify:** Connect your repo, set env vars, and deploy.
- **Railway/Render:** Use Dockerfile or Node buildpack. Set env vars in dashboard.
- **Updating Dependencies:**

  ```bash
  npm outdated
  npm update
  ```

- **Environment Variables:**
  - Store secrets in `.env` (backend) and `.env.local` (frontend).
  - Never commit secrets to git!

---

## 🧰 Troubleshooting

- **Backend won't start:** Check for missing files, bad imports, or missing env vars.
- **ChromaDB errors:** Make sure ChromaDB is running, or ignore for dev.
- **Auth not working:** Check NextAuth config and env vars.
- **Styling issues:** Ensure Tailwind is installed and configured. Try restarting dev server.
- **API errors:** Check backend logs in `backend/logs/`.
- **Debugging:** Use `console.log` or a debugger. For backend, check logs. For frontend, use browser dev tools.

---

## 🤝 Contributing

- **Open Issues/PRs:** Use GitHub Issues for bugs/features. Fork and PR for contributions.
- **Code Style:** Use Prettier and ESLint. Keep code modular and well-commented.
- **Commit Messages:** Use clear, descriptive messages (e.g., `fix: handle agent deletion edge case`).
- **Code Review:** Be constructive, suggest improvements, and ask questions.
- **Tests:** Add/maintain tests for new features.

---

## 📖 Glossary

- **Agent:** An AI entity that can perform tasks, chat, or process data.
- **ChromaDB:** Vector database for storing embeddings/memories.
- **Prisma:** ORM for database access.
- **NextAuth.js:** Authentication library for Next.js.
- **Session:** User login state, managed by NextAuth.
- **Middleware:** Functions that run before/after route handlers (auth, logging, etc.).
- **Component:** Reusable UI element in React.

---

## 📝 Changelog

- Keep a `CHANGELOG.md` in the root.
- For each release, add a section with new features, fixes, and breaking changes.
- Example:

  ```md
  ## [1.0.1] - 2025-07-10
  ### Added
  - New agent analytics dashboard
  ### Fixed
  - Auth bug on login
  ```

---

## 👥 Contact & Community

- **Lead Developer:** Dinesh Dhanoki
- **Contributors:** (Add names/emails here)
- **Contact:** <hello@agentforge.ai>
- **Community:** (Add Slack/Discord/forum links if available)

---

## ⚡ Quick Start (TL;DR)

```bash
# Backend
cd backend
npm install
cp .env.example .env
npm run dev

# Frontend
cd frontend
npm install
cp .env.example .env.local
npm run dev
```

---

## 🗂️ Directory Reference

backend/
  src/
    config/         # Config files (DB, Chroma, etc.)
    controllers/    # Route controllers
    middleware/     # Express middleware
    models/         # Prisma models
    routes/         # Express routes
    services/       # Business logic/services
    utils/          # Helpers, constants, logger
  tests/            # Unit/integration tests
  app.js            # Main Express app
  server.js         # Server entry point

frontend/
  components/
    agent/          # Agent-related UI
    chat/           # Chat UI
    dashboard/      # Dashboard widgets
    layout/         # Layouts (nav, footer, etc.)
    logs/           # Log UI
    ui/             # UI primitives (Button, Card, etc.)
    user/           # User profile/settings
  lib/              # API/auth/utils
  pages/            # Next.js pages & API routes
  public/           # Static assets
  styles/           # Tailwind/global CSS
scripts/            # Deployment/setup scripts

---

## 📝 How to Share

- Share this documentation as a `README.md` in the project root, or as a Google Doc/Notion page.
- Encourage engineers to read the "Project Structure Overview" and "Quick Start" first.
