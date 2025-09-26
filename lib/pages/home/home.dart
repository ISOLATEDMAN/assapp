// home_page_with_bloc.dart
import 'package:assapp/blocs/PatientBloc/bloc/patient_handling_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:assapp/models/Patient/Patient_model.dart';
import 'package:assapp/pages/patient/PatientPage.dart';
import 'package:assapp/pages/patient/TranscriptsPage.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  void initState() {
    super.initState();
    // Load patients when the page initializes
    context.read<PatientHandlingBloc>().add(LoadPatientsEvent());
  }

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
      // Trigger the BLoC event to create patient
      context.read<PatientHandlingBloc>().add(
        CreatePatientEvent(patientName: newPatientName),
      );
    }
  }

  void _onRefreshPatients() {
    context.read<PatientHandlingBloc>().add(RefreshPatientsEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _onRefreshPatients,
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
              child: BlocConsumer<PatientHandlingBloc, PatientHandlingState>(
                listener: (context, state) {
                  if (state is PatientCreatedState) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Patient created successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    
                    // Navigate to the new patient's page
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => Patientpage(
                          patientName: state.patient.name,
                          patientId: state.patient.id,
                        ),
                      ),
                    );
                  } else if (state is PatientErrorState) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.message),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                builder: (context, state) {
                  if (state is PatientLoadingState) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is PatientCreatingState) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Creating patient...'),
                        ],
                      ),
                    );
                  } else if (state is PatientLoadedState || state is PatientCreatedState) {
                    List<PatientModel> patients = [];
                    
                    if (state is PatientLoadedState) {
                      patients = state.patients;
                    } else if (state is PatientCreatedState) {
                      patients = state.allPatients;
                    }
                    
                    if (patients.isEmpty) {
                      return const Center(
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
                      );
                    }
                    
                    return ListView.builder(
                      itemCount: patients.length,
                      itemBuilder: (context, index) {
                        final patient = patients[index];
                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.person_outline),
                            title: Text(patient.name),
                            subtitle: Text('ID: ${patient.id}'),
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
                            trailing: IconButton(
                              icon: const Icon(Icons.history),
                              tooltip: 'View Transcripts',
                              onPressed: () {
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
                    );
                  } else if (state is PatientErrorState) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 64, color: Colors.red),
                          const SizedBox(height: 16),
                          Text(
                            'Error: ${state.message}',
                            style: const TextStyle(color: Colors.red, fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _onRefreshPatients,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }
                  
                  return const Center(
                    child: Text('Initialize patients...'),
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