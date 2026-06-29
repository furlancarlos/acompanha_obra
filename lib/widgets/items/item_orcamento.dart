// widgets/items/item_orcamento.dart
// Arquivo de definição da tela de item de listagem de orçamentos.
//============================================================================//

import 'package:flutter/material.dart';
import '../../models/orcamento.dart';

class ItemOrcamento extends StatelessWidget {
  final Orcamento orcamento;
  final bool isSelecionado;
  final VoidCallback onTap;

  const ItemOrcamento({
    super.key,
    required this.orcamento,
    required this.isSelecionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: isSelecionado
              ? const Color(0xFF1B3A5C).withOpacity(0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isSelecionado
              ? Border.all(color: const Color(0xFF1B3A5C), width: 1.5)
              : Border.all(color: Colors.grey.shade200, width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isSelecionado
                    ? const Color(0xFF1B3A5C)
                    : const Color(0xFF1B3A5C).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                Icons.attach_money,
                size: 10,
                color: isSelecionado ? Colors.white : const Color(0xFF1B3A5C),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    orcamento.nome,
                    style: TextStyle(
                      fontWeight: isSelecionado ? FontWeight.bold : FontWeight.w500,
                      color: isSelecionado ? const Color(0xFF1B3A5C) : Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (orcamento.descricao != null && orcamento.descricao!.isNotEmpty)
                    Text(
                      orcamento.descricao!,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            Text(
              'R\$ ${orcamento.valorTotal.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelecionado ? const Color(0xFF1B3A5C) : Colors.black87,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              isSelecionado ? Icons.check_circle : Icons.chevron_right,
              size: 20,
              color: isSelecionado
                  ? const Color(0xFFE8751A)
                  : Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
}
