const mongoose = require('mongoose');

const platformSettingSchema = new mongoose.Schema({
    key: { type: String, required: true, unique: true },
    value: { type: String, required: true }
}, { timestamps: true });

platformSettingSchema.set('toJSON', {
    virtuals: true,
    transform: (doc, ret) => {
        ret.id = ret._id;
        delete ret._id;
        delete ret.__v;
        return ret;
    }
});

const PlatformSetting = mongoose.model('PlatformSetting', platformSettingSchema);
module.exports = PlatformSetting;
