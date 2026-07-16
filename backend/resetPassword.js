require('dotenv').config();
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

async function resetPassword() {
  await mongoose.connect(process.env.MONGO_URL);
  console.log('Connected to MongoDB');
  
  const salt = await bcrypt.genSalt(10);
  const hash = await bcrypt.hash('MigratedUser123!', salt);
  
  // Check if user exists first
  const user = await mongoose.connection.collection('profiles').findOne({ email: 'king@gmail.com' });
  if (!user) {
    console.log('User king@gmail.com NOT FOUND in database!');
    // List all users
    const allUsers = await mongoose.connection.collection('profiles').find({}).toArray();
    console.log('All users in DB:', allUsers.map(u => ({ email: u.email, role: u.role })));
  } else {
    console.log('Found user:', user.email, '| Role:', user.role);
    const result = await mongoose.connection.collection('profiles').updateOne(
      { email: 'king@gmail.com' },
      { $set: { password: hash } }
    );
    console.log('Password reset! Modified:', result.modifiedCount, 'docs');
  }
  
  await mongoose.disconnect();
}

resetPassword().catch(console.error);
