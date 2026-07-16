const Message = require('../models/Message');

// @desc    Get messages by session
// @route   GET /api/messages
const getMessages = async (req, res) => {
    try {
        const query = {};
        if (req.query.session_id) query.session_id = req.query.session_id;
        const messages = await Message.find(query).sort({ created_at: -1 });
        res.json(messages);
    } catch (error) {
        res.status(500).json({ message: 'Server error fetching messages' });
    }
};

// @desc    Create a message
// @route   POST /api/messages
const createMessage = async (req, res) => {
    try {
        const message = await Message.create(req.body);
        res.status(201).json(message);
    } catch (error) {
        res.status(500).json({ message: 'Server error creating message' });
    }
};

// @desc    Update a message
// @route   PUT /api/messages/:id
const updateMessage = async (req, res) => {
    try {
        const updated = await Message.findByIdAndUpdate(req.params.id, req.body, { new: true });
        if (!updated) return res.status(404).json({ message: 'Message not found' });
        res.json(updated);
    } catch (error) {
        res.status(500).json({ message: 'Server error updating message' });
    }
};

// @desc    Delete a message
// @route   DELETE /api/messages/:id
const deleteMessage = async (req, res) => {
    try {
        await Message.findByIdAndDelete(req.params.id);
        res.json({ message: 'Message deleted' });
    } catch (error) {
        res.status(500).json({ message: 'Server error deleting message' });
    }
};

module.exports = { getMessages, createMessage, updateMessage, deleteMessage };
