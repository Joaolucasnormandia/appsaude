import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Importa o FirebaseAuth

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  User? _currentUser;

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        UserCredential userCredential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        _currentUser = userCredential.user;

        // Enviar e-mail de verificação
        if (_currentUser != null && !_currentUser!.emailVerified) {
          await _currentUser!.sendEmailVerification();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Registro bem-sucedido. Verifique seu e-mail para continuar.')),
          );
        }

        // Limpar os campos
        _emailController.clear();
        _passwordController.clear();
      } on FirebaseAuthException catch (e) {
        String message = 'Erro desconhecido. Tente novamente.';
        if (e.code == 'weak-password') {
          message = 'A senha deve ter pelo menos 6 caracteres.';
        } else if (e.code == 'email-already-in-use') {
          message = 'Este e-mail já está registrado.';
        } else if (e.code == 'invalid-email') {
          message = 'O e-mail fornecido é inválido.';
        }

        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _reenviarEmailVerificacao() async {
    try {
      if (_currentUser != null && !_currentUser!.emailVerified) {
        await _currentUser!.sendEmailVerification();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('E-mail de verificação reenviado.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Usuário já está verificado ou não está logado.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao reenviar e-mail de verificação: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Registrar')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(labelText: 'E-mail'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Informe um e-mail válido.';
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return 'O e-mail informado é inválido.';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(labelText: 'Senha'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Informe uma senha.';
                  }
                  if (value.length < 6) {
                    return 'A senha deve ter pelo menos 6 caracteres.';
                  }
                  return null;
                },
              ),
              SizedBox(height: 24),
              _isLoading
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _register,
                      child: Text('Registrar'),
                    ),
              if (_currentUser != null && !_currentUser!.emailVerified)
                TextButton(
                  onPressed: _reenviarEmailVerificacao,
                  child: Text(
                    'Reenviar e-mail de verificação',
                    style: TextStyle(color: Colors.teal),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
