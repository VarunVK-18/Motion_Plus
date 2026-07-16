const mongoose = require('mongoose');

const clinicSchema = new mongoose.Schema({
    name: { type: String, required: true },
    address: { type: String },
    phone: { type: String },
    email: { type: String },
    created_at: { type: Date, default: Date.now }
}, { timestamps: true });

clinicSchema.set('toJSON', {
    virtuals: true,
    transform: (doc, ret) => {
        ret.id = ret._id;
        delete ret._id;
        delete ret.__v;
        return ret;
    }
});

const Clinic = mongoose.model('Clinic', clinicSchema);
module.exports = Clinic;
