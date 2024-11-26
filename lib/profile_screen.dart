import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'widgets/custom_drawer.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Obtendo o usuário logado
    User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      drawer: const CustomDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: user == null
            ? const Center(child: Text('Usuário não autenticado'))
            : Column(
                children: [
                  Text(
                    'Nome: ${user.displayName ?? 'Não informado'}',
                    style: const TextStyle(fontSize: 18),
                  ),
                  Text(
                    'E-mail: ${user.email ?? 'Não informado'}',
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      // Adicionar lógica para editar perfil
                    },
                    child: const Text('Editar Perfil'),
                  ),
                ],
              ),
      ),
    );
  }
}
