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
const fcmNotificationsRouter = require('./routers/notificationsRouter');
const messageRouter = require('./routers/messageRoutes');
const firstAidRouter = require('./routers/firstAidRoutes');
const aiRouter = require('./routers/aiRouter');
const dailyStatsRouter = require('./routers/dailyStatsRouter');
const cron = require('node-cron');
const ScheduledNotification = require('./models/ScheduledNotification');
const PatientDailyStats = require('./models/PatientDailyStats');
const Profile = require('./models/Profile');
const Session = require('./models/Session');
const PrescribedExercise = require('./models/PrescribedExercise');
const MorningCheckin = require('./models/MorningCheckin');
const { sendPushNotification } = require('./firebaseAdmin');

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
app.use('/api/fcm-notifications', fcmNotificationsRouter);
app.use('/api/messages', messageRouter);
app.use('/api/first-aid', firstAidRouter);
app.use('/api/ai', aiRouter);
app.use('/api/daily-stats', dailyStatsRouter);

// Start Cron Job for Morning Form FCM and Contextual Notifications
// Runs every hour to check for various contextual triggers
cron.schedule('0 * * * *', async () => {
    try {
        const now = new Date();
        const todayStr = now.toISOString().split('T')[0];
        const currentHour = now.getHours();

        // 1. Process Scheduled Notifications (Morning Form)
        const pendingNotifications = await ScheduledNotification.find({
            sent: false,
            scheduled_time: { $lte: now }
        }).populate('patient_id');

        for (let notif of pendingNotifications) {
            if (notif.patient_id && notif.patient_id.fcmTokens && notif.patient_id.fcmTokens.length > 0) {
                await sendPushNotification(notif.patient_id.fcmTokens, notif.title, notif.body, { type: 'morning_form' });
            }
            notif.sent = true;
            await notif.save();
        }

        // 2. Process Daily Habits (Steps, Water, Exercises, Pain)
        
        // Water at 2 PM (14:00)
        if (currentHour === 14) {
            const allPatients = await Profile.find({ role: 'patient' });
            for (let patient of allPatients) {
                if (!patient.fcmTokens || patient.fcmTokens.length === 0) continue;
                const stats = await PatientDailyStats.findOne({ patient_id: patient._id, date: todayStr });
                
                const target = (stats && stats.water_goal) ? stats.water_goal : 8;
                const current = (stats && stats.water_glasses) ? stats.water_glasses : 0;
                
                // If by 2 PM they haven't met at least 50% of their goal
                if (current < (target / 2)) {
                    await sendPushNotification(patient.fcmTokens, "Hydration Reminder", "You're falling behind on your water goal today. Drink up!", { type: 'contextual' });
                }
            }
        }
        
        // Walking at 5 PM (17:00)
        if (currentHour === 17) {
            const allPatients = await Profile.find({ role: 'patient' });
            for (let patient of allPatients) {
                if (!patient.fcmTokens || patient.fcmTokens.length === 0) continue;
                const stats = await PatientDailyStats.findOne({ patient_id: patient._id, date: todayStr });
                if (!stats || !stats.steps || stats.steps === 0) {
                    await sendPushNotification(patient.fcmTokens, "Daily Activity", "You haven't walked today. Let's get some steps in!", { type: 'contextual' });
                }
            }
        }

        // Pain Check at 6 PM (18:00)
        if (currentHour === 18) {
            const allPatients = await Profile.find({ role: 'patient' });
            for (let patient of allPatients) {
                if (!patient.fcmTokens || patient.fcmTokens.length === 0) continue;
                const recentCheckins = await MorningCheckin.find({ patient_id: patient._id })
                    .sort({ created_at: -1 })
                    .limit(3);
                
                if (recentCheckins.length === 3) {
                    const p1 = parseInt(recentCheckins[2].pain_discomfort) || 0;
                    const p2 = parseInt(recentCheckins[1].pain_discomfort) || 0;
                    const p3 = parseInt(recentCheckins[0].pain_discomfort) || 0;
                    
                    if (p3 > p2 && p2 > p1) {
                        await sendPushNotification(patient.fcmTokens, "Pain Alert", "Your pain has increased for 3 consecutive days. Please contact your therapist.", { type: 'contextual_alert' });
                    }
                }
            }
        }

        // Exercises at 8 PM (20:00)
        if (currentHour === 20) {
            const allPatients = await Profile.find({ role: 'patient' });
            for (let patient of allPatients) {
                if (!patient.fcmTokens || patient.fcmTokens.length === 0) continue;
                const stats = await PatientDailyStats.findOne({ patient_id: patient._id, date: todayStr });
                const hasExercises = await PrescribedExercise.exists({ patient_id: patient._id });
                if (hasExercises && (!stats || !stats.exercises_completed)) {
                    await sendPushNotification(patient.fcmTokens, "Home Exercises", "Don't forget your home exercises for today.", { type: 'contextual' });
                }
            }
        }
        
        // 3. Process Reassessment and Appointments at 9 AM
        if (currentHour === 9) {
            const allPatients = await Profile.find({ role: 'patient' });
            
            for (let patient of allPatients) {
                if (!patient.fcmTokens || patient.fcmTokens.length === 0) continue;
                
                // Monthly Reassessment
                const firstSession = await Session.findOne({ patient_id: patient._id }).sort({ created_at: 1 });
                if (firstSession && firstSession.created_at) {
                    const daysSinceStart = Math.floor((now - firstSession.created_at) / (1000 * 60 * 60 * 24));
                    if (daysSinceStart > 0 && daysSinceStart % 30 === 0) {
                        await sendPushNotification(patient.fcmTokens, "Reassessment Due", "Your monthly reassessment is due.", { type: 'contextual' });
                    }
                }
                
                // Appointment tomorrow
                const tomorrow = new Date(now);
                tomorrow.setDate(tomorrow.getDate() + 1);
                const tomorrowStr = tomorrow.toISOString().split('T')[0];
                
                const upcomingSession = await Session.findOne({ 
                    patient_id: patient._id, 
                    status: { $in: ['assigned', 'approved'] },
                    scheduled_date: tomorrowStr 
                });
                
                if (upcomingSession) {
                    const timeStr = upcomingSession.scheduled_time ? ` at ${upcomingSession.scheduled_time}` : '';
                    await sendPushNotification(patient.fcmTokens, "Appointment Reminder", `You have an appointment tomorrow${timeStr}.`, { type: 'contextual' });
                }
            }
        }
    } catch (error) {
        console.error('Error in contextual FCM cron job:', error);
    }
});

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
