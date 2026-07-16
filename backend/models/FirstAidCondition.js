const mongoose = require('mongoose');

const firstAidConditionSchema = new mongoose.Schema({
    title: { type: String, required: true },
    overview: { type: String },
    dos: [{ type: String }],
    donts: [{ type: String }],
    red_flags: [{ type: String }],
    ice_heat_guidance: { type: String },
    icon_name: { type: String }
});

module.exports = mongoose.model('FirstAidCondition', firstAidConditionSchema);
