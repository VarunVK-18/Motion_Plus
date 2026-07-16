const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const profileSchema = new mongoose.Schema({
    first_name: { type: String, required: true },
    last_name: { type: String, required: true },
    full_name: { type: String, required: true },
    phone: { type: String },
    role: { type: String, enum: ['patient', 'therapist', 'therapist_assistant', 'admin', 'superadmin'], default: 'patient' },
    email: { type: String, required: true, unique: true },
    password: { type: String, required: true },
    clinic_id: { type: mongoose.Schema.Types.ObjectId, ref: 'Clinic' },
    avatar_url: { type: String }, // Can be Base64 string if file is small
    created_at: { type: Date, default: Date.now },
}, { timestamps: true });

// Hash password before saving
profileSchema.pre('save', async function(next) {
    if (!this.isModified('password')) {
        next();
    }
    const salt = await bcrypt.genSalt(10);
    this.password = await bcrypt.hash(this.password, salt);
});

// Method to check password match
profileSchema.methods.matchPassword = async function(enteredPassword) {
    return await bcrypt.compare(enteredPassword, this.password);
};

// Transform _id to id in JSON response
profileSchema.set('toJSON', {
    virtuals: true,
    transform: (doc, ret) => {
        ret.id = ret._id;
        delete ret._id;
        delete ret.__v;
        delete ret.password;
        return ret;
    }
});

const Profile = mongoose.model('Profile', profileSchema);

module.exports = Profile;
