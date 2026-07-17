require('dotenv').config();
const express = require('express');
const cors = require('cors');
const http = require('http');
const { Server } = require('socket.io');
const connectDB = require('./config/db');
const firebaseAdmin = require('./firebaseAdmin');

// Initialize Firebase
firebaseAdmin.initializeFirebase();

const authRouter = require('./routers/authRouter');
const clinicRouter = require('./routers/clinicRouter');
const settingRouter = require('./routers/settingRouter');
const profileRouter = require('./routers/profileRouter');
const prescribedExerciseRouter = require('./routers/prescribedExerciseRouter');
const smartAlertRouter = require('./routers/smartAlertRouter');
const morning_checkinsRouter = require('./routers/morning_checkinsRouter');
const caregiver_observation_logsRouter = require('./routers/caregiver_observation_logsRouter');
const pain_bingo_assessmentsRouter = require('./routers/pain_bingo_assessmentsRouter');
const patient_intake_formsRouter = require('./routers/patient_intake_formsRouter');
const patient_achievementsRouter = require('./routers/patient_achievementsRouter');
const patient_documentsRouter = require('./routers/patient_documentsRouter');
const patient_media_filesRouter = require('./routers/patient_media_filesRouter');
const accessRequestRouter = require('./routers/accessRequestRouter');
const sessionRouter = require('./routers/sessionRouter');
const notificationRouter = require('./routers/notificationRouter');
const messageRouter = require('./routers/messageRoutes');
const firstAidRouter = require('./routers/firstAidRoutes');
const aiRouter = require('./routers/aiRouter');

// Connect to MongoDB

connectDB();

const app = express();

// Middleware
app.use(cors());
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ limit: '50mb', extended: true }));

// Routes
app.use('/api/auth', authRouter);
app.use('/api/clinics', clinicRouter);
app.use('/api/settings', settingRouter);
app.use('/api/profiles', profileRouter);
app.use('/api/prescribed_exercises', prescribedExerciseRouter);
app.use('/api/smart_alerts', smartAlertRouter);
app.use('/api/morning_checkins', morning_checkinsRouter);
app.use('/api/caregiver_observation_logs', caregiver_observation_logsRouter);
app.use('/api/pain_bingo_assessments', pain_bingo_assessmentsRouter);
app.use('/api/patient_intake_forms', patient_intake_formsRouter);
app.use('/api/patient_achievements', patient_achievementsRouter);
app.use('/api/patient_documents', patient_documentsRouter);
app.use('/api/patient_media_files', patient_media_filesRouter);
app.use('/api/access-requests', accessRequestRouter);
app.use('/api/sessions', sessionRouter);
app.use('/api/notifications', notificationRouter);
app.use('/api/messages', messageRouter);
app.use('/api/first-aid', firstAidRouter);
app.use('/api/ai', aiRouter);

const server = http.createServer(app);
const io = new Server(server, {
    cors: {
        origin: '*', // Allow all origins for Flutter app
        methods: ['GET', 'POST']
    }
});

io.on('connection', (socket) => {
    const userId = socket.handshake.query.userId;
    if (userId) {
        socket.join(userId);
        console.log(`User ${userId} joined socket room`);
    } else {
        console.log('A user connected without userId:', socket.id);
    }
    
    socket.on('disconnect', () => {
        console.log('User disconnected:', socket.id);
    });
});

// Make io accessible to our routers/controllers
app.set('io', io);

const PORT = process.env.PORT || 5000;

server.listen(PORT, '0.0.0.0', () => {
    console.log(`Server running on port ${PORT}`);
});
