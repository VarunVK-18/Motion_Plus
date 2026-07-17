const { initializeApp, cert } = require('firebase-admin/app');
const { getMessaging } = require('firebase-admin/messaging');
const path = require("path");
const fs = require("fs");

let initialized = false;
let messagingApp;

function initializeFirebase() {
  if (initialized) return;

  const serviceAccountPath = path.join(__dirname, 'firebase-adminsdk.json');
  
  if (fs.existsSync(serviceAccountPath)) {
    try {
      const serviceAccount = require(serviceAccountPath);
      const app = initializeApp({
        credential: cert(serviceAccount)
      });
      messagingApp = getMessaging(app);
      initialized = true;
      console.log('Firebase Admin SDK initialized successfully.');
    } catch (error) {
      console.error('Error initializing Firebase Admin SDK:', error);
    }
  } else {
    console.warn('firebase-adminsdk.json not found! Push notifications will not work.');
  }
}

async function sendPushNotification(tokens, title, body, data = {}) {
  if (!initialized || !messagingApp || !tokens || tokens.length === 0) return;

  const message = {
    notification: {
      title,
      body,
    },
    data,
    tokens: tokens,
  };

  try {
    const response = await messagingApp.sendEachForMulticast(message);
    if (response.failureCount > 0) {
      console.warn(`Failed to send ${response.failureCount} push notifications.`);
    }
  } catch (error) {
    console.error('Error sending push notification:', error);
  }
}

module.exports = {
  initializeFirebase,
  sendPushNotification
};
