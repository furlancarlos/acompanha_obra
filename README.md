# 🏗️ Obra - Acompanhamento de Custos

![Flutter](https://img.shields.io/badge/Flutter-3.41.7-blue?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.11.5-blue?logo=dart)
![License](https://img.shields.io/badge/License-MIT-green)
![Status](https://img.shields.io/badge/Status-Em%20Desenvolvimento-yellow)

---

## 📋 Sobre o Projeto

O **Obra** é um aplicativo mobile desenvolvido em Flutter para auxiliar no acompanhamento financeiro de projetos de construção e reformas. Com ele, você pode cadastrar orçamentos, organizar etapas, controlar despesas e visualizar o progresso financeiro de forma clara e intuitiva.

Ideal para:
- 🏠 Donos de obra
- 👷 Engenheiros
- 📐 Arquitetos
- 🛠️ Qualquer pessoa que precise controlar custos de projetos

---

## 🎯 Funcionalidades

### ✅ Implementadas
- [x] **Cadastro de Orçamentos** - Crie e gerencie múltiplos orçamentos
- [x] **Cadastro de Etapas** - Organize seu projeto em etapas com status de conclusão
- [x] **Controle de Despesas** - Adicione e acompanhe gastos por orçamento
- [x] **Dashboard Resumido** - Visão geral com:
  - Progresso de conclusão por etapa
  - Valores: Orçado, Gasto Total e Restante
  - Percentual de gasto com meta visual
- [x] **Status das Etapas** - Marque como: Crítico, Em Andamento, Concluído ou Pendente

### 🚧 Em Desenvolvimento
- [ ] Relatórios detalhados
- [ ] Exportação de dados (CSV/PDF)
- [ ] Backup e restauração
- [ ] Filtros por período

---

## 📱 Screenshots

### Tela Inicial - Dashboard
![Tela Inicial](./assets/screenshots/tela_inicial.jpeg)

*Visão geral dos orçamentos com resumo financeiro e progresso das etapas*

---

## 🛠️ Tecnologias Utilizadas

### Framework e Linguagem
- **Flutter** 3.41.7
- **Dart** 3.11.5

### Dependências Principais
| Pacote | Versão | Finalidade |
|--------|--------|------------|
| [sqflite](https://pub.dev/packages/sqflite) | ^2.3.0 | Banco de dados local SQLite |
| [path](https://pub.dev/packages/path) | ^1.9.0 | Manipulação de caminhos de arquivos |
| [intl](https://pub.dev/packages/intl) | ^0.19.0 | Formatação de datas e números |
| [cupertino_icons](https://pub.dev/packages/cupertino_icons) | ^1.0.8 | Ícones no estilo iOS |

### Arquitetura
- **Padrão MVC** com separação de camadas
- **SQLite** para persistência local
- **State Management** via setState (padrão Flutter)

---

## 🚀 Como Executar

### Pré-requisitos
- Flutter 3.41.7 ou superior
- Dart 3.11.5 ou superior
- Android Studio / VS Code
- Dispositivo ou emulador Android/iOS

### Passo a Passo

1. **Clone o repositório**
```bash
git clone https://github.com/furlancarlos/acompanha_obra.git
cd acompanha_obra

2. Instale as dependências

flutter pub get

    Execute o projeto

flutter run

    Para build de produção

flutter build apk --release  # Android
flutter build ios --release  # iOS

📂 Estrutura do Projeto
text

acompanha_obra/
├── lib/
│   ├── models/          # Classes de modelo (Orçamento, Etapa, Despesa)
│   ├── screens/         # Telas do aplicativo
│   │   ├── home_screen.dart
│   │   ├── orcamento_screen.dart
│   │   └── ...
│   ├── widgets/         # Componentes reutilizáveis
│   └── database/        # Configuração e helpers do SQLite
├── assets/
│   ├── construcao.png   # Ícone do app
│   └── screenshots/     # Imagens para o README
├── android/             # Configurações Android
├── ios/                 # Configurações iOS
├── pubspec.yaml         # Dependências e configurações
└── README.md            # Este arquivo

📊 Banco de Dados

O aplicativo utiliza SQLite com as seguintes tabelas principais:

    Orcamento: id, nome, descricao, valor_orcado

    Etapa: id, orcamento_id, nome, status (crítico/em_andamento/concluído/pendente), concluida

    Despesa: id, orcamento_id, descricao, valor, data

👤 Autor

Carlos Furlan
https://img.shields.io/badge/GitHub-furlancarlos-181717?logo=github
https://img.shields.io/badge/LinkedIn-Carlos_Furlan-0A66C2?logo=linkedin
📄 Licença

Este projeto está sob a licença MIT - veja o arquivo LICENSE para mais detalhes.
🙏 Agradecimentos

    Flutter - Framework incrível

    SQLite - Banco de dados leve e eficiente

    Dart - Linguagem moderna e performática

📌 Status do Projeto

    🟡 Em Desenvolvimento - Versão Beta

    O projeto está em fase de testes e novas funcionalidades estão sendo implementadas.
    Feedback e sugestões são bem-vindos!

📞 Contato

Para dúvidas, sugestões ou contribuições:
📧 carfurlan@gmail.com (substitua pelo seu e-mail real)
