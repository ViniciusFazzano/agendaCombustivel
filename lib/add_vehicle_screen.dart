import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'widgets/custom_drawer.dart';

class AddVehicleScreen extends StatelessWidget {
  const AddVehicleScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    final TextEditingController _nameController = TextEditingController();
    final TextEditingController _modelController = TextEditingController();
    final TextEditingController _yearController = TextEditingController();
    final TextEditingController _plateController = TextEditingController();

    Future<void> _saveVehicle() async {
      if (_formKey.currentState!.validate()) {
        try {
          User? user = FirebaseAuth.instance.currentUser;
          // Obter referência ao Firestore
          final firestore = FirebaseFirestore.instance;

          // Criar um novo documento para o veículo
          if (user != null) {
            // Cria um novo veículo com o uid do usuário
            await FirebaseFirestore.instance.collection('vehicles').add({
              'name': _nameController.text,
              'model': _modelController.text,
              'year': _yearController.text,
              'plate': _plateController.text,
              'userId': user.uid, // Vincula o veículo ao uid do usuário
            });
          }
          Navigator.pop(context, 'Veículo cadastrado com sucesso!');
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Erro ao cadastrar veículo: ${e.toString()}')),
          );
        }
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Adicionar Veículo')),
      drawer: const CustomDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nome do Veículo'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Insira o nome' : null,
              ),
              TextFormField(
                controller: _modelController,
                decoration: const InputDecoration(labelText: 'Modelo'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Insira o modelo' : null,
              ),
              TextFormField(
                controller: _yearController,
                decoration: const InputDecoration(labelText: 'Ano'),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Insira o ano' : null,
              ),
              TextFormField(
                controller: _plateController,
                decoration: const InputDecoration(labelText: 'Placa'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Insira a placa' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveVehicle,
                child: const Text('Salvar Veículo'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
