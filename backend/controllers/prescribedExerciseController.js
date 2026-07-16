const PrescribedExercise = require('../models/PrescribedExercise');

exports.getExercises = async (req, res) => {
    try {
        const query = {};
        if (req.query.patient_id) query.patient_id = req.query.patient_id;
        if (req.query.therapist_id) query.therapist_id = req.query.therapist_id;
        const exercises = await PrescribedExercise.find(query).sort({ created_at: -1 });
        // Map _id to id
        res.json(exercises.map(ex => ({ ...ex.toObject(), id: ex._id.toString() })));
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};

exports.createExercise = async (req, res) => {
    try {
        const exercise = new PrescribedExercise(req.body);
        await exercise.save();
        res.status(201).json({ ...exercise.toObject(), id: exercise._id.toString() });
    } catch (error) {
        res.status(400).json({ error: error.message });
    }
};

exports.deleteExercise = async (req, res) => {
    try {
        await PrescribedExercise.findByIdAndDelete(req.params.id);
        res.status(204).send();
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};
