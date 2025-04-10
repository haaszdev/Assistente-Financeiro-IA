# 💸 Assistente Financeiro com IA

Um app Flutter simples e intuitivo para ajudar no controle de despesas e receitas pessoais, com funcionalidades de **reconhecimento de voz** e **análise financeira com IA**.

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Gemini](https://img.shields.io/badge/Google-Gemini-yellow?style=for-the-badge&logo=google)

---

## 📱 Screenshots

<div style="display: flex; gap: 10px; justify-content: center; flex-wrap: wrap;">
  <img src="https://github.com/user-attachments/assets/d5cff8ac-b38b-4f55-baf9-24c06fb2d9ec" alt="image1" width="30%" />
  <img src="https://github.com/user-attachments/assets/938b2050-c93c-445d-a51e-a978c28ebf7b" alt="image2" width="30%" />
  <img src="https://github.com/user-attachments/assets/e55c1dc3-4b49-4e1c-b470-21187ac336da" alt="image3" width="30%" />
</div>

---

## ✅ Requisitos

Antes de executar este projeto, certifique-se de que você tem os seguintes requisitos instalados:

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (versão 3.10 ou superior recomendada)
- Dart (já incluso com o Flutter)
- Android Studio ou VS Code com as extensões do Flutter e Dart
- Emulador Android configurado ou dispositivo físico conectado
- Conexão com a internet para utilizar as funcionalidades com IA
- Permissões de microfone habilitadas para o reconhecimento de voz

---

## 🚀 Funcionalidades

- 📥 Registro de transações financeiras (receitas e despesas)
- 🗣️ Entrada por voz usando reconhecimento de fala
- 📅 Seleção de data para cada transação
- 📊 Análise financeira gerada por IA (via botão)
- 🧾 Visualização de histórico de transações

---

## 🛠️ Tecnologias Utilizadas

- **Flutter** & **Dart**
- **speech_to_text** (reconhecimento de voz)
- **intl** (formatação de datas e valores)
- **IA (Google Gemini)** para análises

---

## 📦 Instalação

1. Clone este repositório:
```bash
git clone https://github.com/seu-usuario/nome-do-repositorio.git
```

2. Navegue até o diretório do projeto:
```bash
cd nome-do-repositorio
```

3. Instale as dependências:
```bash
flutter pub get
```

4. Execute o app:
```bash
flutter run
```

---

## 🧠 Como funciona a análise por IA?

Ao pressionar o botão de **análise financeira**, o app processa suas transações e envia um resumo para um modelo de IA (Gemini), que retorna dicas personalizadas de economia, alertas de gastos excessivos e sugestões baseadas no seu histórico.

> *É necessário um backend ou chave de API válida para isso funcionar corretamente.*
---
