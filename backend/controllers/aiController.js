const { GoogleGenerativeAI } = require('@google/generative-ai');

const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);

const SYSTEM_PROMPT = `You are an AI Physio Assistant for the MotionPlus app.
You provide helpful, general guidance on physiotherapy topics like exercises, pain management, posture, and wellness.

IMPORTANT RULES:
- You must NEVER diagnose medical conditions.
- You must NEVER prescribe specific treatments or medications.
- You must ALWAYS recommend consulting a qualified physiotherapist for personalized advice.
- Keep responses concise, friendly, and encouraging.

If a user asks for something outside your scope, politely redirect them to consult their therapist.`;

// Store chat histories in memory (keyed by user/session)
const chatHistories = new Map();

exports.chat = async (req, res) => {
  try {
    const { message, sessionId } = req.body;

    if (!message || !message.trim()) {
      return res.status(400).json({ error: 'Message is required' });
    }

    const key = sessionId || 'default';

    // Get or initialise chat history for this session
    if (!chatHistories.has(key)) {
      chatHistories.set(key, [
        {
          role: 'user',
          parts: [{ text: SYSTEM_PROMPT }],
        },
        {
          role: 'model',
          parts: [{ text: 'Understood. I am your AI Physio Assistant.' }],
        },
      ]);
    }

    const history = chatHistories.get(key);

    const model = genAI.getGenerativeModel({ model: 'gemini-2.5-flash' });

    const chat = model.startChat({ history });

    const result = await chat.sendMessage(message.trim());
    const responseText = result.response.text();

    // Append this turn to the stored history
    history.push({ role: 'user', parts: [{ text: message.trim() }] });
    history.push({ role: 'model', parts: [{ text: responseText }] });

    // Keep history from growing too large (keep system prompt + last 20 turns)
    if (history.length > 42) {
      history.splice(2, 2); // remove oldest user+model pair after system prompt
    }

    return res.json({ reply: responseText });
  } catch (error) {
    console.error('AI Chat Error:', error);
    return res.status(500).json({ error: 'Failed to get AI response', details: error.message });
  }
};
