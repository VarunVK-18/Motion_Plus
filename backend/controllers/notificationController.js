exports.pushNotification = async (req, res) => {
    try {
        const { userId, title, body, payload } = req.body;
        const io = req.app.get('io');
        if (io && userId) {
            io.to(userId).emit('notification', { title, body, payload });
        }
        res.json({ success: true, message: 'Notification emitted' });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};
