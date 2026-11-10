import 'package:e_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/auth_cubit.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose(){
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
void _register() {
if (!_formKey.currentState!.validate()) {
return;
}
context.read<AuthCubit>().register(
  name: _nameController.text.trim(),
  email: _emailController.text.trim(),
  password: _passwordController.text.trim(),
);
}

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state){
        if (state is AuthAuthenticated){
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Account created successfully'),),
          );
          Navigator.pop(context);
        }
        if (state is AuthError){
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message),)
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Create Account'),
        ),
        body: SafeArea(child:Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Create Account 🚀',
                    textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text('Create your ShopFlow account',
                    textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 32),

                    TextFormField(
                      controller: _nameController,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'Name',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty){
                          return 'Please enter your name';
                        }
                        if (value.trim().length < 3) {
                          return 'Name must be at least 3 characters';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),

                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!value.contains('@')) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),

                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.lock_outline),
                        suffixIcon: IconButton(onPressed: (){
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        }, icon: Icon(_obscurePassword
                        ? Icons.visibility
                            : Icons.visibility_off
                        ),),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        if (value.length < 6){
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        prefixIcon: Icon(Icons.lock_outline),
                        suffixIcon: IconButton(onPressed: (){
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        }, icon: Icon(
                          _obscureConfirmPassword
                          ? Icons.visibility
                              :Icons.visibility_off,
                        ),),
                      ),
                      validator: (value){
                        if (value == null || value.isEmpty) {
                          return 'Please confirm your password';
                        }
                        if (value != _passwordController.text){
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 24),
                    BlocBuilder <AuthCubit,AuthState>(
                        builder: (context, state) {
                        if (state is AuthLoading) {
                          return Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        return ElevatedButton(onPressed: _register, child: Text('Create Account'),);
                    }, ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Already have an account?'),
                        TextButton(onPressed: (){
                          Navigator.pop(context);
                        },
                          child:Text('Login'),
                        ),
                      ],
                    ),

                  ],
                ),),
          ),
        ),),
      ),
    );
  }
}
