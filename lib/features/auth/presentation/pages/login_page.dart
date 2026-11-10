import 'package:e_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:e_app/features/auth/presentation/pages/register_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/auth_cubit.dart';
import 'forgot_password_page.dart';
class LoginPage extends StatefulWidget {
 const LoginPage({super.key});

 @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {

  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  void _login(){
    if(!_formKey.currentState!.validate()) {
      return;
    }
    context.read<AuthCubit>().login(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim()

    );
  }
  @override
  Widget build (BuildContext context){
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state){
        if (state is AuthAuthenticated){
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Login successful'))
          );
        }
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message))
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Login'),
        ),
        body: SafeArea(child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: Form(
                key: _formKey,
                child:Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Welcome Back 👋',
                    textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),

                    Text('Login to your ShopFlow account',
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 32),

                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (value){
                        if (value == null || value.trim().isEmpty){
                          return 'Please enter your email' ;
                        }

                        if (!value.contains('@')){
                          return 'Please enter a valid email';
                        }

                        return null;
                      },
                    ),
                    SizedBox(height: 16),

                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.lock_outline),
                        suffixIcon: IconButton(onPressed: (){
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                          icon: Icon(_obscurePassword
                          ? Icons.visibility
                              :Icons.visibility_off,
                          ),
                        ),
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
                    SizedBox(height: 24),
                    BlocBuilder <AuthCubit, AuthState>(
                      builder: (context, state) {

                        if (state is AuthLoading){
                        return Center(
                          child: CircularProgressIndicator(),
                        );
                    }
                        return ElevatedButton(onPressed: _login, child:Text('Login'));
                      }
                    ),
                    SizedBox(height: 16),
                    TextButton(onPressed: (){
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ForgotPasswordPage(),
                        ),
                      );

                    }, child: Text('Forgot Password?',),),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Don\'t have an account?'),
                        TextButton(onPressed: (){
                          Navigator.push(context, MaterialPageRoute(builder: (_) => RegisterPage(),
                          ),);
                        }, child: Text('Register'))
                      ],
                    )
                  ],
                )
            ),
          ),
        )),
      ),
    );
  }
}