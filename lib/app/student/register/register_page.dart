import 'package:flutter/material.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: const Color(0xFFFFE0B2), // Laranja claro no fundo
        body: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      //width: 350,
                      color: Colors.white,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Center(
                            child: Text(
                              'CADASTRO DO CLIENTE',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF37474F),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          _buildSectionTitle('INFORMAÇÕES PESSOAIS'),
                          const SizedBox(height: 16),
                          _buildLabel('NOME COMPLETO'),
                          _buildTextField(),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabel('IDADE'),
                                    _buildTextField(),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabel('TELEFONE CELULAR'),
                                    _buildTextField(),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildLabel('ENDEREÇO'),
                          _buildTextField(),
                          const SizedBox(height: 24),
                          _buildSectionTitle('INFORMAÇÕES DA VISITA'),
                          const SizedBox(height: 16),
                          _buildLabel('MÉDIA DE GASTOS POR VISITA (3 MESES)'),
                          _buildTextField(),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabel('DIA DA SEMANA'),
                                    _buildTextField(),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabel('HORÁRIO'),
                                    _buildTextField(),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildButton('CANCELAR', Colors.red),
                              _buildButton('SALVAR', Colors.green),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }
        ));}

            Widget _buildSectionTitle(String title) {
    return Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 8),
    color: Color(0xFFFFCCFF), // Rosa claro
    child: Center(
    child: Text(
    title,
    style: const TextStyle(
    fontWeight: FontWeight.bold,
    color: Color(0xFF37474F),
    ),
    ),
    ),
    );
    }

        Widget _buildLabel(String text)
    {
      return Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Color(0xFF37474F),
        ),
      );
    }

    Widget _buildTextField() {
      return Container(
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFECEFF1), // Cinza claro
          borderRadius: BorderRadius.circular(4),
        ),
        child: const TextField(
          decoration: InputDecoration(
            border: InputBorder.none,
          ),
        ),
      );
    }

    Widget _buildButton(String label, Color color) {
      return SizedBox(
        width: 120,
        height: 40,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
          ),
          onPressed: () {},
          child: Text(label),
        ),
      );
    }
  }
