import 'package:flutter/material.dart';

class PaymentsPage extends StatefulWidget {
  const PaymentsPage({super.key});

  @override
  State<PaymentsPage> createState() => _PaymentsPageState();
}

class _PaymentsPageState extends State<PaymentsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Pagos'),
        backgroundColor: const Color(0xFFA11C25),
      ),
      body: const Center(
        child: Text(
          'Aquí podrás gestionar los pagos de los residentes.',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
