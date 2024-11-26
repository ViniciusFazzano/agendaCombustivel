import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RefuelDetailScreen extends StatefulWidget {
  final String refuelId;

  const RefuelDetailScreen({Key? key, required this.refuelId})
      : super(key: key);

  @override
  _RefuelDetailScreenState createState() => _RefuelDetailScreenState();
}

class _RefuelDetailScreenState extends State<RefuelDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _litersController = TextEditingController();
  final _mileageController = TextEditingController();
  DateTime? _date;
  String? _selectedVehicleId; // ID do veículo selecionado
  String? _selectedVehicleName; // Nome do veículo selecionado
  List<Map<String, dynamic>> _vehicles = []; // Lista de veículos disponíveis

  @override
  void initState() {
    super.initState();
    _fetchRefuelDetails();
    _fetchVehicles(); // Carregar a lista de veículos
  }

  // Busca os detalhes do abastecimento
  Future<void> _fetchRefuelDetails() async {
    try {
      final refuelDoc = await FirebaseFirestore.instance
          .collection('fuelRecords')
          .doc(widget.refuelId)
          .get();

      if (refuelDoc.exists) {
        final refuelData = refuelDoc.data();
        setState(() {
          _litersController.text = refuelData?['liters'].toString() ?? '';
          _mileageController.text = refuelData?['mileage'].toString() ?? '';
          _date = (refuelData?['date'] as Timestamp).toDate();
          _selectedVehicleId =
              refuelData?['vehicleId']; // ID do veículo vinculado
          _selectedVehicleName =
              refuelData?['vehicleName']; // Nome do veículo vinculado
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Abastecimento não encontrado!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar os dados: ${e.toString()}')),
      );
    }
  }

  // Busca todos os veículos disponíveis
  Future<void> _fetchVehicles() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        // Se o usuário não estiver logado, exibe uma mensagem
        SnackBar(content: Text('Você precisa estar logado.'));
        return;
      }
      final vehiclesSnapshot = await FirebaseFirestore.instance
          .collection(
              'vehicles') // Supondo que você tenha uma coleção 'vehicles'
          .where('userId', isEqualTo: user.uid)
          .get();

      setState(() {
        _vehicles = vehiclesSnapshot.docs.map((doc) {
          return {
            'id': doc.id,
            'name':
                doc['name'], // Supondo que cada veículo tenha um campo 'name'
          };
        }).toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar veículos: ${e.toString()}')),
      );
    }
  }

  // Atualiza o abastecimento no Firestore
  Future<void> _updateRefuel() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        await FirebaseFirestore.instance
            .collection('fuelRecords')
            .doc(widget.refuelId)
            .update({
          'liters': double.parse(_litersController.text),
          'mileage': int.parse(_mileageController.text),
          'date': _date,
          'vehicleId': _selectedVehicleId, // Atualiza o veículo
          'vehicleName': _selectedVehicleName, // Atualiza o nome do veículo
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Abastecimento atualizado com sucesso!')),
        );
        Navigator.pop(context); // Volta para a tela anterior
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao atualizar: ${e.toString()}')),
        );
      }
    }
  }

  // Abre o seletor de data
  Future<void> _selectDate(BuildContext context) async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _date ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (selectedDate != null && selectedDate != _date) {
      setState(() {
        _date = selectedDate;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar Abastecimento')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Dropdown para selecionar o veículo
              DropdownButtonFormField<String>(
                value: _selectedVehicleId,
                hint: const Text('Selecione o veículo'),
                onChanged: (newValue) {
                  setState(() {
                    _selectedVehicleId = newValue;
                    _selectedVehicleName = _vehicles.firstWhere(
                        (vehicle) => vehicle['id'] == newValue)['name'];
                  });
                },
                items: _vehicles.map((vehicle) {
                  return DropdownMenuItem<String>(
                    value: vehicle['id'],
                    child: Text(vehicle['name']),
                  );
                }).toList(),
                validator: (value) {
                  if (value == null) {
                    return 'Selecione um veículo';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _litersController,
                decoration: const InputDecoration(labelText: 'Litros'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Informe a quantidade de litros';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _mileageController,
                decoration: const InputDecoration(labelText: 'Quilometragem'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Informe a quilometragem';
                  }
                  return null;
                },
              ),
              Row(
                children: [
                  Text(
                    _date == null
                        ? 'Data: Não selecionada'
                        : 'Data: ${_date!.day}/${_date!.month}/${_date!.year}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () => _selectDate(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _updateRefuel,
                child: const Text('Atualizar Abastecimento'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
