import 'package:assapp/blocs/AuthBloc/bloc/auths_bloc.dart';
import 'package:assapp/pages/home/home.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The LoginScreen now simply displays the LoginView.
/// It doesn't need to provide the BLoC because it's already
/// provided higher up in the widget tree in main.dart.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // The BlocProvider was removed from here.
    return const LoginView();
  }
}


/// The UI for the Login screen. It listens to state changes from AuthsBloc.
class LoginView extends StatelessWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    // A controller to get the text from the email field.
    final emailController = TextEditingController();
    // A key to validate the form.
    final formKey = GlobalKey<FormState>();

    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      // This will now correctly find and use the AuthsBloc
      // instance provided in your main.dart file.
      body: BlocConsumer<AuthsBloc, AuthsState>(
        listener: (context, state) {
          if (state is AuthsFailure) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(content: Text(state.error), backgroundColor: Colors.red),
              );
          }
          if (state is AuthsSuccess) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>Home()));
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                const SnackBar(content: Text("Login Successful!"), backgroundColor: Colors.green),
              );
            // TODO: Navigate to your home screen
            // Navigator.of(context).pushReplacement(...);
          }
        },
        builder: (context, state) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextFormField(
                      controller: emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      validator: (value) {
                        if (value == null || !value.contains('@')) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    if (state is AuthsLoading)
                      const CircularProgressIndicator()
                    else
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                        ),
                        onPressed: () {
                          if (formKey.currentState?.validate() ?? false) {
                            context.read<AuthsBloc>().add(
                                  LoginReq(email: emailController.text),
                                );
                          }
                        },
                        child: const Text('Login'),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}