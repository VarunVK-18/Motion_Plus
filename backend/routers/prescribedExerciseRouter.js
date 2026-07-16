const express = require('express');
const router = express.Router();
const controller = require('../controllers/prescribedExerciseController');

router.get('/', controller.getExercises);
router.post('/', controller.createExercise);
router.delete('/:id', controller.deleteExercise);

module.exports = router;
