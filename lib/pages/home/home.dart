import 'package:assapp/pages/patient/PatientPage.dart';
import 'package:assapp/pages/patient/TranscriptsPage.dart';

import 'package:assapp/services/PatientService/PatientService.dart';
import 'package:assapp/models/Patient/Patient_model.dart';
import 'package:flutter/material.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List<PatientModel> _patients = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  Future<void> _loadPatients() async {
    setState(() => _isLoading = true);
    final PatientService patientService = PatientService();
    // This call now fetches patients AND their associated transcripts
    final patients = await patientService.getPatients();
    setState(() {
      _patients = patients;
      _isLoading = false;
    });
  }

  // ... (Your _showCreatePatientDialog function remains the same) ...
  Future<void> _showCreatePatientDialog() async {
    final nameController = TextEditingController();
    
    final String? newPatientName = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Create New Patient'),
          content: TextField(
            controller: nameController,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Enter patient name'),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Create'),
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  Navigator.of(dialogContext).pop(nameController.text);
                }
              },
            ),
          ],
        );
      },
    );

    if (newPatientName != null && newPatientName.isNotEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Creating patient...')),
      );

      final PatientService patientService = PatientService();
      final PatientModel? newPatient = await patientService.createPatient(newPatientName);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (newPatient != null) {
        setState(() {
          _patients.add(newPatient);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Patient created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => Patientpage(
              patientName: newPatient.name,
              patientId: newPatient.id,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to create patient. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPatients,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: _showCreatePatientDialog,
              icon: const Icon(Icons.add),
              label: const Text('Create Patient'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Existing Patients',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Divider(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _patients.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.person_off_outlined, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                'No patients found',
                                style: TextStyle(color: Colors.grey, fontSize: 16),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _patients.length,
                          itemBuilder: (context, index) {
                            final patient = _patients[index];
                            return Card(
                              child: ListTile(
                                leading: const Icon(Icons.person_outline),
                                title: Text(patient.name),
                                subtitle: Text('ID: ${patient.id}'),
                                // ✅ MODIFICATION: The whole tile still navigates to a new session.
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => Patientpage(
                                        patientName: patient.name,
                                        patientId: patient.id,
                                      ),
                                    ),
                                  );
                                },
                                // ✅ MODIFICATION: The trailing icon is now a button for history.
                                trailing: IconButton(
                                  icon: const Icon(Icons.history),
                                  tooltip: 'View Transcripts',
                                  onPressed: () {
                                    // Navigate and pass the patient's existing transcript list.
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => TranscriptsPage(
                                          patientName: patient.name,
                                          transcripts: patient.transcripts,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}