// lista_unidade.dart
// Arquivo de definição da tela de listagem de unidades.
// Layout alinhado com o layout do app
//============================================================================//

import 'package:flutter/material.dart';
import '../dao/unidade_dao.dart';
import '../models/unidade.dart';
import '../screens/cadastro_unidade.dart';

class ListaUnidadePage extends StatefulWidget {
  const ListaUnidadePage({super.key});

  @override
  State<ListaUnidadePage> createState() => _ListaUnidadePageState();
}

class _ListaUnidadePageState extends State<ListaUnidadePage> {
  List<Unidade> unidades = [];

  @override
  void initState() {
    super.initState();
    _carregarUnidades();
  }

  Future<void> _carregarUnidades() async {
    final lista = await UnidadeDAO().getAll();
    setState(() => unidades = lista);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Unidades')),
      body: ListView.builder(
        itemCount: unidades.length,
        itemBuilder: (context, index) {
          final u = unidades[index];
          return ListTile(
            title: Text(u.descricao),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CadastroUnidadePage(unidade: u),
                      ),
                    );
                    _carregarUnidades();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () async {
                    await UnidadeDAO().delete(u.id!);
                    _carregarUnidades();
                  },
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CadastroUnidadePage()),
          );
          _carregarUnidades();
        },
      ),
    );
  }
}
