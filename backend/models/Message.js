const mongoose = require('mongoose');

const messageSchema = new mongoose.Schema({
    session_id: { type: String, required: true },
    sender_id: { type: mongoose.Schema.Types.ObjectId, ref: 'Profile', required: true },
    receiver_id: { type: mongoose.Schema.Types.ObjectId, ref: 'Profile', required: true },
    content: { type: String, required: true },
    is_read: { type: Boolean, default: false },
    created_at: { type: Date, default: Date.now }
});

module.exports = mongoose.model('Message', messageSchema);
