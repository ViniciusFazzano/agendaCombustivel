import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart'; // Importando o pacote

class AddFuelRecordScreen extends StatefulWidget {
  const AddFuelRecordScreen({Key? key}) : super(key: key);

  @override
  State<AddFuelRecordScreen> createState() => _AddFuelRecordScreenState();
}

class _AddFuelRecordScreenState extends State<AddFuelRecordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _litersController = TextEditingController();
  final TextEditingController _mileageController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  String? _selectedVehicleId;

  // Máscara para a data no formato dd-MM-yyyy
  final _dateFormatter = MaskTextInputFormatter(
      mask: '##-##-####', filter: {'#': RegExp(r'[0-9]')});

  Future<void> _saveFuelRecord() async {
    if (_formKey.currentState!.validate()) {
      try {
        User? user = FirebaseAuth.instance.currentUser;

        if (user != null) {
          final parts = _dateController.text.split('-'); // Divide a data
          final formattedDate =
              '${parts[2]}-${parts[1]}-${parts[0]}'; // Converte para YYYY-MM-DD

          await FirebaseFirestore.instance.collection('fuelRecords').add({
            'userId': user.uid,
            'vehicleId': _selectedVehicleId,
            'liters': double.parse(_litersController.text),
            'mileage': int.parse(_mileageController.text),
            'date': Timestamp.fromDate(DateTime.parse(formattedDate)),
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Abastecimento cadastrado com sucesso!')),
          );
          Navigator.pop(context); // Fecha a tela após salvar
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Usuário não autenticado.')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao cadastrar: ${e.toString()}')),
        );
      }
    }
  }

  Future<List<QueryDocumentSnapshot>> _fetchVehicles() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return [];
    }

    final querySnapshot = await FirebaseFirestore.instance
        .collection('vehicles')
        .where('userId', isEqualTo: user.uid)
        .get();

    return querySnapshot.docs;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cadastrar Abastecimento')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<List<QueryDocumentSnapshot>>(
          future: _fetchVehicles(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return const Center(child: Text('Erro ao carregar veículos.'));
            }

            final vehicles = snapshot.data ?? [];

            if (vehicles.isEmpty) {
              return const Center(
                child: Text(
                    'Nenhum veículo cadastrado. Cadastre um veículo primeiro.'),
              );
            }

            return Form(
              key: _formKey,
              child: ListView(
                children: [
                  // Dropdown para selecionar o veículo
                  DropdownButtonFormField<String>(
                    value: _selectedVehicleId,
                    items: vehicles.map((vehicle) {
                      return DropdownMenuItem(
                        value: vehicle.id,
                        child: Text(vehicle['name']),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedVehicleId = value;
                      });
                    },
                    decoration: const InputDecoration(labelText: 'Veículo'),
                    validator: (value) =>
                        value == null ? 'Selecione um veículo' : null,
                  ),
                  TextFormField(
                    controller: _litersController,
                    decoration: const InputDecoration(
                        labelText: 'Quantidade de Litros'),
                    keyboardType: TextInputType.number,
                    validator: (value) => value == null || value.isEmpty
                        ? 'Insira a quantidade de litros'
                        : null,
                  ),
                  TextFormField(
                    controller: _mileageController,
                    decoration:
                        const InputDecoration(labelText: 'Quilometragem Atual'),
                    keyboardType: TextInputType.number,
                    validator: (value) => value == null || value.isEmpty
                        ? 'Insira a quilometragem atual'
                        : null,
                  ),
                  // Campo de data com máscara
                  TextFormField(
                    controller: _dateController,
                    decoration: const InputDecoration(
                      labelText: 'Data',
                      hintText: 'DD-MM-YYYY',
                    ),
                    keyboardType: TextInputType.datetime,
                    inputFormatters: [_dateFormatter], // Aplicando a máscara
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Insira a data';
                      }
                      try {
                        final parts =
                            value.split('-'); // Divide a data em partes
                        if (parts.length != 3) throw FormatException();
                        final formattedDate =
                            '${parts[2]}-${parts[1]}-${parts[0]}'; // Converte para YYYY-MM-DD
                        DateTime.parse(formattedDate); // Valida a data
                      } catch (_) {
                        return 'Formato de data inválido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _saveFuelRecord,
                    child: const Text('Salvar Abastecimento'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
