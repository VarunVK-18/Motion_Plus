import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'patient_dashboard.dart';

class PatientIntakeFormScreen extends StatefulWidget {
  const PatientIntakeFormScreen({super.key});

  @override
  State<PatientIntakeFormScreen> createState() =>
      _PatientIntakeFormScreenState();
}

class _PatientIntakeFormScreenState extends State<PatientIntakeFormScreen> {
  final _formKey1 = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();
  final _formKey3 = GlobalKey<FormState>();
  final _formKey4 = GlobalKey<FormState>();
  

  bool _isSubmitting = false;
  int _currentStep = 0;

  // Colors
  static const Color primaryBlue = Color(0xFF3E84DC);
  static const Color darkSlate = Color(0xFF0F172A);
  static const Color softSlate = Color(0xFF64748B);
  static const Color forestGreen = Color(0xFF2D6A4F);
  static const Color background = Color(0xFFF8FAFC);

  // Controllers and State
  final _fullNameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  String _gender = 'Select';
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _occupationCtrl = TextEditingController();
  final _emContactNumCtrl = TextEditingController();
  String _referral = 'Select';
  final _referringDocCtrl = TextEditingController();

  final _complaintCtrl = TextEditingController();
  String _duration = 'Select';
  String _onset = 'Select';
  double _painScale = 0;
  
  final Map<String, bool> _symptoms = {
    'Pain': false, 'Weakness': false, 'Stiffness': false, 'Tingling': false,
    'Numbness': false, 'Balance problem': false, 'Difficulty walking': false,
    'Fatigue': false, 'Breathing difficulty': false, 'Swelling': false,
    'Speech difficulty': false, 'Feeding difficulty': false,
    'Behavioral concerns': false, 'Delayed milestones': false,
    'Poor attention': false, 'Sleep disturbances': false,
  };
  final _otherSymptomCtrl = TextEditingController();

  final Map<String, bool> _limitations = {
    'Walking': false, 'Standing': false, 'Sitting': false, 'Climbing stairs': false,
    'Dressing': false, 'Bathing': false, 'Feeding': false, 'Writing': false,
    'Lifting': false, 'Playing': false, 'Speaking': false, 'Sleeping': false,
    'School activities': false, 'Work activities': false, 'Sports activities': false,
  };
  
  String _severity = 'Select';

  final Map<String, bool> _goals = {
    'Pain relief': false, 'Walk independently': false, 'Improve strength': false,
    'Return to work': false, 'Return to sports': false, 'Improve balance': false,
    'Better hand function': false, 'Better communication': false,
    'Improve attention': false, 'Improve independence': false,
    'Improve quality of life': false,
  };
  final _otherGoalCtrl = TextEditingController();

  final Map<String, bool> _medicalHistory = {
    'Diabetes': false, 'Hypertension': false, 'Heart Disease': false,
    'Thyroid Disorder': false, 'Neurological Disease': false,
    'Respiratory Disease': false, 'Previous Surgery': false,  'Nothing': false,
  };
  final _surgeryDetailsCtrl = TextEditingController();
  
  final _medicationsCtrl = TextEditingController();

  bool _smoking = false;
  bool _alcohol = false;
  String _physicalActivity = 'Select';
  String _sleepQuality = 'Select';
  
  bool _fallsHistory = false;
  
  String _assistiveDevice = 'Select';
  String _homeExercise = 'Select';

  bool _consent = false;

  Future<void> _submitForm() async {
    if (!_consent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please agree to the consent terms to proceed.'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final user = await ApiService.get('/profiles/me', includeAuth: true);
      if (user == null) throw 'User not logged in';

      final Map<String, dynamic> basicInfo = {
        'full_name': _fullNameCtrl.text,
        'age': _ageCtrl.text,
        'gender': _gender,
        'phone': _phoneCtrl.text,
        'email': _emailCtrl.text,
        'address': _addressCtrl.text,
        'occupation': _occupationCtrl.text,
        'emergency_contact_number': _emContactNumCtrl.text,
      };

      final Map<String, dynamic> referralInfo = {
        'referral_source': _referral,
        'referring_doctor': _referringDocCtrl.text,
      };

      final symptomsList = _symptoms.entries.where((e) => e.value).map((e) => e.key).toList();
      if (_otherSymptomCtrl.text.isNotEmpty) symptomsList.add('Other: ${_otherSymptomCtrl.text}');

      final limitationsList = _limitations.entries.where((e) => e.value).map((e) => e.key).toList();

      final goalsList = _goals.entries.where((e) => e.value).map((e) => e.key).toList();
      if (_otherGoalCtrl.text.isNotEmpty) goalsList.add('Other: ${_otherGoalCtrl.text}');

      final medicalHistory = Map<String, dynamic>.from(_medicalHistory);
      if (_medicalHistory['Previous Surgery'] == true) {
        medicalHistory['surgery_details'] = _surgeryDetailsCtrl.text;
      }

      final lifestyle = {
        'smoking': _smoking,
        'alcohol': _alcohol,
        'physical_activity': _physicalActivity,
        'sleep_quality': _sleepQuality,
      };

      await ApiService.post('/patient_intake_forms', {
        'patient_id': user['id'],
        'basic_info': basicInfo,
        'referral_info': referralInfo,
        'primary_complaint': _complaintCtrl.text,
        'problem_duration': _duration,
        'onset': _onset,
        'pain_scale': _painScale.toInt(),
        'symptoms': symptomsList,
        'functional_limitation': limitationsList,
        'severity': _severity,
        'patient_goal': goalsList,
        'medical_history': medicalHistory,
        'medication': _medicationsCtrl.text,
        'lifestyle': lifestyle,
        'falls_history': _fallsHistory,
        'assistive_device': _assistiveDevice,
        'home_exercise_compliance': _homeExercise,
        'consent': _consent,
      }, includeAuth: true);

      if (mounted) {
        // Successful submission, go back to dashboard
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const PatientDashboard()),
        );
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool optional = false, TextInputType? keyboardType, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label ${optional ? "(Optional)" : "*"}', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 13, color: darkSlate)),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            style: GoogleFonts.outfit(fontSize: 14),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              hintText: 'Enter $label',
              hintStyle: GoogleFonts.outfit(color: Colors.grey[400], fontSize: 13),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: primaryBlue)),
            ),
            validator: (value) {
              if (!optional && (value == null || value.trim().isEmpty)) return 'Please enter $label';
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label *', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 13, color: darkSlate)),
          const SizedBox(height: 8),
          DropdownButtonFormField2<String>(
            isExpanded: true,
            valueListenable: ValueNotifier(value == 'Select' ? null : value),
            hint: Text('Select $label', style: GoogleFonts.outfit(color: softSlate, fontSize: 13)),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: primaryBlue)),
            ),
            items: items.map((i) => DropdownItem<String>(value: i, child: Text(i, style: GoogleFonts.outfit(fontSize: 14)))).toList(),
            onChanged: onChanged,
            validator: (val) => val == null ? 'Please select $label' : null,
            buttonStyleData: const FormFieldButtonStyleData(
              padding: EdgeInsets.only(right: 8),
            ),
            dropdownStyleData: DropdownStyleData(
              maxHeight: 250,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: Colors.white,
              ),
              offset: const Offset(0, -5),
            ),
            iconStyleData: const IconStyleData(
              icon: Icon(Icons.keyboard_arrow_down_rounded, color: softSlate),
              iconSize: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckboxGrid(String title, Map<String, bool> map) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 13, color: darkSlate)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: map.keys.map((key) {
              final val = map[key]!;
              return FilterChip(
                label: Text(key),
                selected: val,
                onSelected: (selected) => setState(() => map[key] = selected),
                selectedColor: primaryBlue.withOpacity(0.1),
                checkmarkColor: primaryBlue,
                labelStyle: GoogleFonts.outfit(
                  color: val ? primaryBlue : darkSlate,
                  fontWeight: val ? FontWeight.bold : FontWeight.normal,
                ),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: val ? primaryBlue : Colors.grey[300]!)),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1() {
    return Column(
      children: [
        _buildTextField('Full Name', _fullNameCtrl),
        Row(
          children: [
            Expanded(child: _buildTextField('Age', _ageCtrl, keyboardType: TextInputType.number)),
            const SizedBox(width: 16),
            Expanded(child: _buildDropdown('Gender', _gender, ['Male', 'Female', 'Other'], (val) => setState(() => _gender = val!))),
          ],
        ),
        _buildTextField('Phone Number', _phoneCtrl, keyboardType: TextInputType.phone),
        _buildTextField('Email ID', _emailCtrl, optional: true, keyboardType: TextInputType.emailAddress),
        _buildTextField('Address', _addressCtrl, maxLines: 2),
        _buildTextField('Occupation', _occupationCtrl),
        _buildTextField('Emergency Contact Number', _emContactNumCtrl, keyboardType: TextInputType.phone),
        _buildDropdown('Referral Source', _referral, ['Self', 'Doctor', 'Hospital', 'Friend/Family', 'Social Media', 'Insurance', 'Other'], (val) => setState(() => _referral = val!)),
        if (_referral == 'Doctor' || _referral == 'Hospital')
          _buildTextField('Referring Doctor', _referringDocCtrl, optional: true),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      children: [
        _buildTextField('What brings you here today? (Primary Complaint)', _complaintCtrl, maxLines: 3),
        Row(
          children: [
            Expanded(child: _buildDropdown('Problem Duration', _duration, ['<1 week', '1–4 weeks', '1–3 months', '3–6 months', '> 6 months'], (val) => setState(() => _duration = val!))),
            const SizedBox(width: 16),
            Expanded(child: _buildDropdown('Onset', _onset, ['Sudden', 'Gradual', 'After Surgery', 'After Injury', 'Since Birth', 'Unknown'], (val) => setState(() => _onset = val!))),
          ],
        ),
        const SizedBox(height: 16),
        Text('Pain Scale (0-10)', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 13, color: darkSlate)),
        Slider(
          value: _painScale,
          min: 0,
          max: 10,
          divisions: 10,
          label: _painScale.round().toString(),
          activeColor: primaryBlue,
          onChanged: (val) => setState(() => _painScale = val),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('No Pain (0)', style: GoogleFonts.outfit(color: softSlate, fontSize: 11)),
              Text('Severe (10)', style: GoogleFonts.outfit(color: softSlate, fontSize: 11)),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildCheckboxGrid('Symptoms', _symptoms),
        _buildTextField('Other Symptoms', _otherSymptomCtrl, optional: true),
        _buildCheckboxGrid('Functional Limitations (What is difficult currently?)', _limitations),
        _buildDropdown('Severity Perception (Compared to normal)', _severity, ['Mild', 'Moderate', 'Severe'], (val) => setState(() => _severity = val!)),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      children: [
        _buildCheckboxGrid('Patient Goal (What do you want to achieve?)', _goals),
        _buildTextField('Other Goals', _otherGoalCtrl, optional: true),
        const SizedBox(height: 16),
        Text('Medical History', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 16, color: darkSlate)),
        const SizedBox(height: 8),
        _buildCheckboxGrid('Select any conditions you have:', _medicalHistory),
        if (_medicalHistory['Previous Surgery'] == true)
          _buildTextField('Previous Surgery Details', _surgeryDetailsCtrl),
        _buildTextField('Current Medications', _medicationsCtrl, maxLines: 2, optional: true),
        const SizedBox(height: 16),
        Text('Lifestyle', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 16, color: darkSlate)),
        const SizedBox(height: 8),
        SwitchListTile(
          title: Text('Do you smoke?', style: GoogleFonts.outfit(fontSize: 14)),
          value: _smoking,
          onChanged: (val) => setState(() => _smoking = val),
          activeColor: primaryBlue,
          contentPadding: EdgeInsets.zero,
        ),
        SwitchListTile(
          title: Text('Do you consume alcohol?', style: GoogleFonts.outfit(fontSize: 14)),
          value: _alcohol,
          onChanged: (val) => setState(() => _alcohol = val),
          activeColor: primaryBlue,
          contentPadding: EdgeInsets.zero,
        ),
        _buildDropdown('Physical Activity', _physicalActivity, ['Sedentary', 'Moderate', 'Active'], (val) => setState(() => _physicalActivity = val!)),
        _buildDropdown('Sleep Quality', _sleepQuality, ['Good', 'Fair', 'Poor'], (val) => setState(() => _sleepQuality = val!)),
        SwitchListTile(
          title: Text('Any falls in past 6 months?', style: GoogleFonts.outfit(fontSize: 14)),
          value: _fallsHistory,
          onChanged: (val) => setState(() => _fallsHistory = val),
          activeColor: primaryBlue,
          contentPadding: EdgeInsets.zero,
        ),
        _buildDropdown('Assistive Device', _assistiveDevice, ['None', 'Walker', 'Stick', 'Crutches', 'Wheelchair', 'Orthosis'], (val) => setState(() => _assistiveDevice = val!)),
        _buildDropdown('Home Exercise Compliance (Follow-up)', _homeExercise, ['Excellent', 'Partial', 'Poor'], (val) => setState(() => _homeExercise = val!)),
      ],
    );
  }

  Widget _buildStep4() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Consent & Agreement', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 18, color: darkSlate)),
              const SizedBox(height: 12),
              Text(
                'I understand that rehabilitation outcomes vary between individuals and that recovery depends on multiple factors including condition severity, participation, consistency, and overall health.',
                style: GoogleFonts.outfit(fontSize: 14, color: softSlate, height: 1.5),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Checkbox(
                    value: _consent,
                    onChanged: (val) => setState(() => _consent = val ?? false),
                    activeColor: forestGreen,
                  ),
                  Expanded(
                    child: Text('I agree to the terms above.', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: Text('Personal Details Form', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: darkSlate, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false, // Force them to complete it
      ),
      body: SafeArea(
        child: Stepper(
            type: StepperType.horizontal,
            currentStep: _currentStep,
            onStepTapped: (step) {
              // Ensure previous steps are validated before allowing jumping ahead
              if (step < _currentStep) {
                 setState(() => _currentStep = step);
              }
            },
            onStepContinue: () {
              if (_currentStep == 0) {
                if (!_formKey1.currentState!.validate()) return;
                setState(() => _currentStep += 1);
              } else if (_currentStep == 1) {
                if (_duration == 'Select' || _onset == 'Select' || _severity == 'Select') {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select dropdown values')));
                  return;
                }
                if (!_formKey2.currentState!.validate()) return;
                setState(() => _currentStep += 1);
              } else if (_currentStep == 2) {
                if (_physicalActivity == 'Select' || _sleepQuality == 'Select' || _assistiveDevice == 'Select' || _homeExercise == 'Select') {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select dropdown values')));
                  return;
                }
                if (!_formKey3.currentState!.validate()) return;
                setState(() => _currentStep += 1);
              } else {
                if (!_formKey4.currentState!.validate()) return;
                _submitForm();
              }
            },
            onStepCancel: () {
              if (_currentStep > 0) setState(() => _currentStep -= 1);
            },
            controlsBuilder: (context, details) {
              final isLastStep = _currentStep == 3;
              return Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : details.onStepContinue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text(isLastStep ? 'SUBMIT' : 'CONTINUE', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: Colors.white)),
                      ),
                    ),
                    if (_currentStep > 0) const SizedBox(width: 12),
                    if (_currentStep > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: details.onStepCancel,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            side: BorderSide(color: Colors.grey[300]!),
                          ),
                          child: Text('BACK', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: softSlate)),
                        ),
                      ),
                  ],
                ),
              );
            },
            steps: [
              Step(title: const SizedBox.shrink(), content: Form(key: _formKey1, child: _buildStep1()), isActive: _currentStep >= 0, state: _currentStep > 0 ? StepState.complete : StepState.indexed),
              Step(title: const SizedBox.shrink(), content: Form(key: _formKey2, child: _buildStep2()), isActive: _currentStep >= 1, state: _currentStep > 1 ? StepState.complete : StepState.indexed),
              Step(title: const SizedBox.shrink(), content: Form(key: _formKey3, child: _buildStep3()), isActive: _currentStep >= 2, state: _currentStep > 2 ? StepState.complete : StepState.indexed),
              Step(title: const SizedBox.shrink(), content: Form(key: _formKey4, child: _buildStep4()), isActive: _currentStep >= 3, state: _currentStep > 3 ? StepState.complete : StepState.indexed),
            ],
          ),
        ),
    );
  }
}
