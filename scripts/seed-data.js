// ===================================================================
// ADVANCED SEED DATA SCRIPT - scripts/seed-data.js
// ===================================================================

const { PrismaClient } = require("@prisma/client");
const { faker } = require("@faker-js/faker");
const { AGENT_CONFIG, LOG_ACTIONS } = require("../backend/src/utils/constants");
const {
  generateId,
  calculateMemoryImportance,
} = require("../backend/src/utils/helpers");

const prisma = new PrismaClient();

// Configuration
const SEED_CONFIG = {
  users: 5,
  agentsPerUser: 3,
  sessionsPerAgent: 2,
  messagesPerSession: 10,
  memoriesPerAgent: 15,
  logsPerAgent: 20,
};

// Sample data templates
const AGENT_TEMPLATES = [
  {
    name: "Creative Writer",
    description:
      "An AI agent specialized in creative writing, storytelling, and content creation",
    goal: "Help users create engaging stories, poems, blog posts, and creative content with imaginative flair",
    personality:
      "Creative, imaginative, and inspiring with a love for storytelling and artistic expression",
    model: "mistral",
    temperature: 0.9,
    maxTokens: 1500,
    tools: ["text_generation", "creative_writing", "summarization"],
  },
  {
    name: "Code Assistant",
    description:
      "A programming companion for software development and technical problem-solving",
    goal: "Assist with coding tasks, debugging, code review, and software architecture decisions",
    personality:
      "Analytical, precise, and methodical with deep technical expertise and problem-solving skills",
    model: "mistral",
    temperature: 0.3,
    maxTokens: 2000,
    tools: ["code_analysis", "debugging", "documentation"],
  },
  {
    name: "Research Helper",
    description:
      "An agent focused on research, analysis, and information synthesis",
    goal: "Help users research topics, analyze information, and synthesize findings into actionable insights",
    personality:
      "Methodical, thorough, and intellectually curious with strong analytical capabilities",
    model: "mistral",
    temperature: 0.5,
    maxTokens: 1200,
    tools: ["web_search", "data_analysis", "summarization"],
  },
  {
    name: "Learning Mentor",
    description:
      "An educational AI designed to help with learning and skill development",
    goal: "Guide users through learning new concepts, skills, and subjects with personalized instruction",
    personality:
      "Patient, encouraging, and knowledgeable with excellent teaching and mentoring abilities",
    model: "mistral",
    temperature: 0.6,
    maxTokens: 1500,
    tools: ["text_generation", "summarization"],
  },
  {
    name: "Business Advisor",
    description:
      "A strategic AI assistant for business planning and decision-making",
    goal: "Provide strategic business insights, help with planning, and support decision-making processes",
    personality:
      "Professional, strategic, and results-oriented with strong business acumen",
    model: "mistral",
    temperature: 0.4,
    maxTokens: 1800,
    tools: ["data_analysis", "summarization"],
  },
];

const CONVERSATION_STARTERS = [
  "Hello! I'm excited to work with you. How can I help you today?",
  "Hi there! What would you like to explore or create together?",
  "Greetings! I'm here and ready to assist. What's on your mind?",
  "Welcome! I'm looking forward to helping you achieve your goals.",
  "Hello! Tell me about what you're working on and how I can support you.",
];

const USER_MESSAGES = [
  "Can you help me brainstorm some ideas for my project?",
  "I need assistance with problem-solving. Where should I start?",
  "What's the best approach for learning this new concept?",
  "Can you review my work and provide feedback?",
  "I'm stuck on this challenge. Can you guide me through it?",
  "How would you recommend I structure this?",
  "What are some best practices for this type of work?",
  "Can you explain this concept in simpler terms?",
  "I need help organizing my thoughts. Where do I begin?",
  "What resources would you recommend for this topic?",
];

const AGENT_RESPONSES = [
  "I'd be happy to help you brainstorm! Let's start by exploring your objectives and constraints.",
  "Great question! Here's a systematic approach we can take to tackle this problem effectively.",
  "Learning new concepts is exciting! I recommend we break this down into manageable steps.",
  "I'll review your work carefully and provide constructive feedback to help you improve.",
  "No worries about being stuck - that's a normal part of the process. Let's work through this together.",
  "For structuring this effectively, I suggest we consider these key organizational principles.",
  "Here are some proven best practices that will help you achieve better results.",
  "Absolutely! Let me explain this concept using simple examples and clear analogies.",
  "Organizing thoughts is crucial for success. Let's create a clear framework to guide your thinking.",
  "I can recommend several excellent resources that align with your learning style and goals.",
];

const MEMORY_CONTENT = [
  "User prefers step-by-step explanations with examples",
  "Working on a creative writing project - fantasy novel",
  "Interested in learning JavaScript and React development",
  "Needs help with data analysis and visualization",
  "Enjoys collaborative brainstorming sessions",
  "Prefers detailed feedback on written work",
  "Currently studying machine learning concepts",
  "Working on a business plan for a startup",
  "Interested in sustainable technology solutions",
  "Needs support with project management strategies",
  "Enjoys exploring creative problem-solving approaches",
  "Working on improving communication skills",
  "Interested in learning about user experience design",
  "Needs help with time management and productivity",
  "Enjoys discussing philosophical and ethical topics",
];

// Utility functions
function randomChoice(array) {
  return array[Math.floor(Math.random() * array.length)];
}

function randomChoices(array, count) {
  const shuffled = array.sort(() => 0.5 - Math.random());
  return shuffled.slice(0, count);
}

function generateRealisticEmail(firstName, lastName) {
  const domains = ["gmail.com", "yahoo.com", "outlook.com", "protonmail.com"];
  const domain = randomChoice(domains);
  const username = `${firstName.toLowerCase()}.${lastName.toLowerCase()}${
    Math.random() > 0.7 ? Math.floor(Math.random() * 100) : ""
  }`;
  return `${username}@${domain}`;
}

// Seeding functions
async function seedUsers() {
  console.log("🌱 Seeding users...");

  const users = [];

  for (let i = 0; i < SEED_CONFIG.users; i++) {
    const firstName = faker.person.firstName();
    const lastName = faker.person.lastName();
    const email = generateRealisticEmail(firstName, lastName);

    const user = await prisma.user.create({
      data: {
        email,
        name: `${firstName} ${lastName}`,
        provider: randomChoice(["google", "github"]),
        providerId: generateId("provider"),
        image: faker.image.avatar(),
      },
    });

    users.push(user);
  }

  console.log(`✅ Created ${users.length} users`);
  return users;
}

async function seedAgents(users) {
  console.log("🤖 Seeding agents...");

  const agents = [];

  for (const user of users) {
    const userAgents = randomChoices(
      AGENT_TEMPLATES,
      SEED_CONFIG.agentsPerUser
    );

    for (const template of userAgents) {
      const agent = await prisma.agent.create({
        data: {
          ...template,
          tools: JSON.stringify(template.tools),
          userId: user.id,
        },
      });

      agents.push(agent);
    }
  }

  console.log(`✅ Created ${agents.length} agents`);
  return agents;
}

async function seedChatSessions(agents) {
  console.log("💬 Seeding chat sessions...");

  const sessions = [];

  for (const agent of agents) {
    for (let i = 0; i < SEED_CONFIG.sessionsPerAgent; i++) {
      const sessionDate = faker.date.recent({ days: 30 });

      const session = await prisma.chatSession.create({
        data: {
          title: `${faker.hacker.phrase()} - ${sessionDate.toLocaleDateString()}`,
          userId: agent.userId,
          agentId: agent.id,
          createdAt: sessionDate,
          updatedAt: sessionDate,
        },
      });

      sessions.push(session);
    }
  }

  console.log(`✅ Created ${sessions.length} chat sessions`);
  return sessions;
}

async function seedMessages(sessions) {
  console.log("📝 Seeding messages...");

  let totalMessages = 0;

  for (const session of sessions) {
    const messageCount =
      Math.floor(Math.random() * SEED_CONFIG.messagesPerSession) + 5;
    let currentTime = new Date(session.createdAt);

    for (let i = 0; i < messageCount; i++) {
      const isUserMessage = i % 2 === 0;
      const role = isUserMessage ? "user" : "assistant";

      let content;
      if (i === 0) {
        // First message is always a greeting
        content = randomChoice(CONVERSATION_STARTERS);
      } else if (isUserMessage) {
        content = randomChoice(USER_MESSAGES);
      } else {
        content = randomChoice(AGENT_RESPONSES);
      }

      // Add some variation to message content
      if (Math.random() > 0.7) {
        content += ` ${faker.lorem.sentence()}`;
      }

      const tokens = Math.floor(content.split(" ").length * 1.3); // Rough token estimation

      // Add realistic time gaps between messages
      currentTime = new Date(currentTime.getTime() + Math.random() * 300000); // 0-5 minutes

      await prisma.message.create({
        data: {
          sessionId: session.id,
          role,
          content,
          tokens,
          timestamp: currentTime,
        },
      });

      totalMessages++;
    }
  }

  console.log(`✅ Created ${totalMessages} messages`);
}

async function seedMemories(agents) {
  console.log("🧠 Seeding memories...");

  let totalMemories = 0;

  for (const agent of agents) {
    for (let i = 0; i < SEED_CONFIG.memoriesPerAgent; i++) {
      const content = randomChoice(MEMORY_CONTENT);
      const role = Math.random() > 0.3 ? "user" : "assistant";
      const importance = calculateMemoryImportance(content, role, {
        isFirstMessage: i === 0,
        isInstruction: content.includes("prefer") || content.includes("need"),
      });

      // Generate simple embedding (mock)
      const embedding = Array.from(
        { length: 384 },
        () => Math.random() * 2 - 1
      );

      const memoryDate = faker.date.recent({ days: 30 });

      await prisma.memory.create({
        data: {
          agentId: agent.id,
          content,
          embedding: JSON.stringify(embedding),
          importance,
          metadata: JSON.stringify({
            role,
            timestamp: memoryDate.toISOString(),
            type: "conversation",
            source: "chat",
          }),
          createdAt: memoryDate,
        },
      });

      totalMemories++;
    }
  }

  console.log(`✅ Created ${totalMemories} memories`);
}

async function seedActivityLogs(agents, users) {
  console.log("📊 Seeding activity logs...");

  let totalLogs = 0;

  for (const agent of agents) {
    const user = users.find((u) => u.id === agent.userId);

    for (let i = 0; i < SEED_CONFIG.logsPerAgent; i++) {
      const action = randomChoice([
        LOG_ACTIONS.CHAT_MESSAGE,
        LOG_ACTIONS.CHAT_RESPONSE,
        LOG_ACTIONS.AGENT_UPDATED,
        LOG_ACTIONS.SESSION_CREATED,
        LOG_ACTIONS.MEMORY_CREATED,
      ]);

      const success = Math.random() > 0.1; // 90% success rate
      const duration = success ? Math.floor(Math.random() * 3000) + 500 : null;
      const logDate = faker.date.recent({ days: 30 });

      const details = {
        agentName: agent.name,
        model: agent.model,
        timestamp: logDate.toISOString(),
      };

      if (
        action === LOG_ACTIONS.CHAT_MESSAGE ||
        action === LOG_ACTIONS.CHAT_RESPONSE
      ) {
        details.messageLength = Math.floor(Math.random() * 200) + 50;
        details.tokens = Math.floor(details.messageLength * 1.3);
      }

      if (!success) {
        details.error = randomChoice([
          "Network timeout",
          "Model unavailable",
          "Rate limit exceeded",
          "Invalid request format",
        ]);
      }

      await prisma.activityLog.create({
        data: {
          userId: user.id,
          agentId: agent.id,
          action,
          details: JSON.stringify(details),
          success,
          duration,
          error: success ? null : details.error,
          timestamp: logDate,
        },
      });

      totalLogs++;
    }
  }

  console.log(`✅ Created ${totalLogs} activity logs`);
}

async function createDemoScenarios(users, agents) {
  console.log("🎭 Creating demo scenarios...");

  // Scenario 1: Creative Writing Session
  const writer = users[0];
  const creativeAgent = agents.find(
    (a) => a.name === "Creative Writer" && a.userId === writer.id
  );

  if (creativeAgent) {
    const session = await prisma.chatSession.create({
      data: {
        title: "Fantasy Novel Planning Session",
        userId: writer.id,
        agentId: creativeAgent.id,
      },
    });

    const demoMessages = [
      {
        role: "user",
        content:
          "I want to write a fantasy novel about a world where magic is powered by emotions. Can you help me develop this concept?",
      },
      {
        role: "assistant",
        content:
          "What a fascinating premise! Emotion-powered magic opens up incredible storytelling possibilities. Let's explore the mechanics: How do different emotions translate to magical abilities? For instance, anger might fuel destructive fire magic, while compassion could power healing spells. What emotional range were you thinking of incorporating?",
      },
      {
        role: "user",
        content:
          "I love that idea! I was thinking that positive emotions create constructive magic, while negative emotions are more destructive. But what if there are rare individuals who can balance both?",
      },
      {
        role: "assistant",
        content:
          'Brilliant! These balanced individuals could be your main characters - perhaps called "Equilibrists" or "Harmony Mages." They\'d face unique challenges: the constant internal struggle to maintain emotional balance, societal fear of their dual nature, and the immense responsibility that comes with such power. This creates natural character development arcs and conflict. What kind of world would they inhabit?',
      },
    ];

    for (let i = 0; i < demoMessages.length; i++) {
      const msg = demoMessages[i];
      await prisma.message.create({
        data: {
          sessionId: session.id,
          role: msg.role,
          content: msg.content,
          tokens: Math.floor(msg.content.split(" ").length * 1.3),
          timestamp: new Date(Date.now() - (demoMessages.length - i) * 120000), // 2-minute intervals
        },
      });
    }
  }

  // Scenario 2: Code Review Session
  const developer = users[1];
  const codeAgent = agents.find(
    (a) => a.name === "Code Assistant" && a.userId === developer.id
  );

  if (codeAgent) {
    const session = await prisma.chatSession.create({
      data: {
        title: "React Component Code Review",
        userId: developer.id,
        agentId: codeAgent.id,
      },
    });

    const codeMessages = [
      {
        role: "user",
        content:
          "Can you review my React component for performance issues? I'm worried about unnecessary re-renders.",
      },
      {
        role: "assistant",
        content:
          "I'd be happy to help with performance optimization! Please share your component code, and I'll analyze it for potential re-render issues. I'll look for common patterns like inline object creation, missing dependency arrays in hooks, and prop drilling that could cause performance problems.",
      },
      {
        role: "user",
        content:
          "Here's the component: [code would be here]. I notice it re-renders every time the parent updates, even when the props haven't changed.",
      },
      {
        role: "assistant",
        content:
          "I can see the issue! The component is receiving a new object reference on every parent render. Here are three solutions: 1) Wrap the component in React.memo() with a custom comparison function, 2) Use useMemo() to memoize the object prop in the parent, or 3) Restructure to pass primitive values instead. I recommend approach #2 for your use case. Would you like me to show you the implementation?",
      },
    ];

    for (let i = 0; i < codeMessages.length; i++) {
      const msg = codeMessages[i];
      await prisma.message.create({
        data: {
          sessionId: session.id,
          role: msg.role,
          content: msg.content,
          tokens: Math.floor(msg.content.split(" ").length * 1.3),
          timestamp: new Date(Date.now() - (codeMessages.length - i) * 180000), // 3-minute intervals
        },
      });
    }
  }

  console.log("✅ Created demo scenarios");
}

async function generateReports() {
  console.log("📈 Generating seed data report...");

  const stats = await Promise.all([
    prisma.user.count(),
    prisma.agent.count(),
    prisma.chatSession.count(),
    prisma.message.count(),
    prisma.memory.count(),
    prisma.activityLog.count(),
  ]);

  const [
    userCount,
    agentCount,
    sessionCount,
    messageCount,
    memoryCount,
    logCount,
  ] = stats;

  console.log("\n📊 SEED DATA SUMMARY");
  console.log("==========================================");
  console.log(`👥 Users:           ${userCount}`);
  console.log(`🤖 Agents:          ${agentCount}`);
  console.log(`💬 Chat Sessions:   ${sessionCount}`);
  console.log(`📝 Messages:        ${messageCount}`);
  console.log(`🧠 Memories:        ${memoryCount}`);
  console.log(`📊 Activity Logs:   ${logCount}`);
  console.log("==========================================");

  // Get some sample data for verification
  const sampleUser = await prisma.user.findFirst({
    include: {
      _count: {
        select: {
          agents: true,
          chatSessions: true,
          logs: true,
        },
      },
    },
  });

  if (sampleUser) {
    console.log(`\n🎯 Sample User: ${sampleUser.name}`);
    console.log(`   Email: ${sampleUser.email}`);
    console.log(`   Agents: ${sampleUser._count.agents}`);
    console.log(`   Sessions: ${sampleUser._count.chatSessions}`);
    console.log(`   Activity Logs: ${sampleUser._count.logs}`);
  }

  const sampleAgent = await prisma.agent.findFirst({
    include: {
      _count: {
        select: {
          chatSessions: true,
          memories: true,
          logs: true,
        },
      },
    },
  });

  if (sampleAgent) {
    console.log(`\n🤖 Sample Agent: ${sampleAgent.name}`);
    console.log(`   Model: ${sampleAgent.model}`);
    console.log(`   Temperature: ${sampleAgent.temperature}`);
    console.log(`   Sessions: ${sampleAgent._count.chatSessions}`);
    console.log(`   Memories: ${sampleAgent._count.memories}`);
    console.log(`   Activity Logs: ${sampleAgent._count.logs}`);
  }
}

async function cleanup() {
  console.log("🧹 Cleaning up existing data...");

  // Delete in reverse dependency order
  await prisma.activityLog.deleteMany();
  await prisma.message.deleteMany();
  await prisma.memory.deleteMany();
  await prisma.chatSession.deleteMany();
  await prisma.agent.deleteMany();
  await prisma.user.deleteMany();

  console.log("✅ Cleanup completed");
}

// Main seeding function
async function main() {
  console.log("🌱 Starting AgentCraft Database Seeding...");
  console.log("==========================================\n");

  try {
    // Clean existing data
    await cleanup();

    // Seed data in dependency order
    const users = await seedUsers();
    const agents = await seedAgents(users);
    const sessions = await seedChatSessions(agents);

    await seedMessages(sessions);
    await seedMemories(agents);
    await seedActivityLogs(agents, users);
    await createDemoScenarios(users, agents);

    // Generate final report
    await generateReports();

    console.log("\n🎉 Database seeding completed successfully!");
    console.log(
      "You can now start the AgentCraft application and explore the demo data."
    );
  } catch (error) {
    console.error("❌ Seeding failed:", error);
    process.exit(1);
  } finally {
    await prisma.$disconnect();
  }
}

// Custom seeding modes
async function seedMinimal() {
  console.log("🌱 Seeding minimal data for development...");

  SEED_CONFIG.users = 2;
  SEED_CONFIG.agentsPerUser = 2;
  SEED_CONFIG.sessionsPerAgent = 1;
  SEED_CONFIG.messagesPerSession = 5;
  SEED_CONFIG.memoriesPerAgent = 5;
  SEED_CONFIG.logsPerAgent = 5;

  await main();
}

async function seedExtensive() {
  console.log("🌱 Seeding extensive data for testing...");

  SEED_CONFIG.users = 10;
  SEED_CONFIG.agentsPerUser = 5;
  SEED_CONFIG.sessionsPerAgent = 5;
  SEED_CONFIG.messagesPerSession = 20;
  SEED_CONFIG.memoriesPerAgent = 30;
  SEED_CONFIG.logsPerAgent = 50;

  await main();
}

// CLI interface
const args = process.argv.slice(2);
const mode = args[0] || "default";

switch (mode) {
  case "minimal":
    seedMinimal();
    break;
  case "extensive":
    seedExtensive();
    break;
  case "cleanup":
    cleanup().then(() => {
      console.log("✅ Database cleaned");
      process.exit(0);
    });
    break;
  case "help":
    console.log("AgentCraft Database Seeding Script");
    console.log("");
    console.log("Usage: node scripts/seed-data.js [mode]");
    console.log("");
    console.log("Modes:");
    console.log("  default    - Standard seeding (5 users, moderate data)");
    console.log("  minimal    - Minimal seeding (2 users, light data)");
    console.log("  extensive  - Extensive seeding (10 users, heavy data)");
    console.log("  cleanup    - Remove all seeded data");
    console.log("  help       - Show this help message");
    break;
  default:
    main();
    break;
}
