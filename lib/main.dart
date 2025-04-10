import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:intl/intl.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Assistente Financeiro IA',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.light,
        ),
      ),
      home: const FinanceScreen(),
    );
  }
}

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({Key? key}) : super(key: key);

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final stt.SpeechToText _speech = stt.SpeechToText();

  String _financialAdvice = '';
  bool _isLoading = false;
  bool _isListening = false;
  bool _isExpense = true;
  DateTime _selectedDate = DateTime.now();
  List<Map<String, dynamic>> _transactions = [];

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }


void _initSpeech() async {
  bool available = await _speech.initialize(
    onStatus: (status) {
      if (status == 'done') {
        setState(() => _isListening = false);
      }
    },
    onError: (error) => setState(() => _isListening = false),
  );
  
  if (!available && mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reconhecimento de voz não disponível')),
    );
  }
}

void _listen() async {
  if (!_isListening) {
    bool available = await _speech.initialize(
      onStatus: (status) => print('Status: $status'),
      onError: (error) => print('Error: $error'),
    );
    
    if (available) {
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (result) => setState(() {
          _descriptionController.text = result.recognizedWords;
        }),
        localeId: 'pt_BR',
      );
    }
  } else {
    setState(() => _isListening = false);
    _speech.stop();
  }
}

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _addTransaction() async {
    if (_descriptionController.text.isEmpty ||
        _amountController.text.isEmpty ||
        _categoryController.text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Preencha todos os campos')),
        );
      }
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Digite um valor válido maior que zero')),
        );
      }
      return;
    }

    final newTransaction = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'description': _descriptionController.text,
      'amount': amount,
      'category': _categoryController.text,
      'isExpense': _isExpense,
      'date': _selectedDate,
    };

    setState(() {
      _transactions.add(newTransaction);
      _descriptionController.clear();
      _amountController.clear();
      _categoryController.clear();
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transação adicionada com sucesso!')),
      );
    }
  }

  Future<void> _getFinancialAdvice() async {
    if (_transactions.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Adicione transações primeiro')),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final expenses = _transactions.where((t) => t['isExpense']).toList();
      final incomes = _transactions.where((t) => !t['isExpense']).toList();

      final totalExpenses = expenses.fold(0.0, (sum, t) => sum + t['amount']);
      final totalIncomes = incomes.fold(0.0, (sum, t) => sum + t['amount']);

      final categories = <String, double>{};
      for (var t in expenses) {
        categories[t['category']] = (categories[t['category']] ?? 0) + t['amount'];
      }

      const apiKey = 'AIzaSyBbNxkEwLKipQO8qaqWMb9afVbrTsEyxa8';
      const apiUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-pro:generateContent?key=$apiKey';

      final prompt = '''
      Você é um especialista em finanças pessoais. Analise estes dados e forneça:
      1. Um resumo financeiro claro (máximo 3 linhas)
      2. 3 recomendações específicas baseadas nos padrões de gastos
      3. Alertas sobre possíveis problemas financeiros
      4. Sugestões de economia personalizadas

      Formate a resposta com tópicos e use emojis para melhorar a legibilidade.

      Dados do usuário:
      - Receitas totais: R\$${totalIncomes.toStringAsFixed(2)}
      - Despesas totais: R\$${totalExpenses.toStringAsFixed(2)}
      - Saldo atual: R\$${(totalIncomes - totalExpenses).toStringAsFixed(2)}
      - Distribuição de gastos: ${categories.entries.map((e) => '${e.key}: R\$${e.value.toStringAsFixed(2)}').join(', ')}
      ''';

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": prompt}
              ]
            }
          ],
          "generationConfig": {
            "temperature": 0.7,
            "topK": 40,
            "topP": 0.95,
            "maxOutputTokens": 1024,
          }
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['candidates'] != null &&
            jsonResponse['candidates'][0]['content']['parts'][0]['text'] != null) {
          setState(() {
            _financialAdvice = jsonResponse['candidates'][0]['content']['parts'][0]['text'];
          });
        } else {
          setState(() {
            _financialAdvice = 'Erro: Estrutura de resposta inesperada da API';
          });
        }
      } else {
        setState(() {
          _financialAdvice = 'Erro na API: ${response.statusCode}\n${response.body}';
        });
      }
    } catch (e) {
      setState(() {
        _financialAdvice = 'Erro de conexão: $e\n\nDica: Verifique sua conexão com a internet e a chave da API';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildTransactionList() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Histórico de Transações',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_transactions.isNotEmpty)
                  Text(
                    'Total: ${_transactions.length}',
                    style: TextStyle(
                      color: Colors.teal.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            if (_transactions.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    'Nenhuma transação registrada',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              )
            else
              Column(
                children: _transactions.reversed.take(5).map((transaction) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: transaction['isExpense']
                              ? Colors.red.shade50
                              : Colors.green.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          transaction['isExpense']
                              ? Icons.arrow_circle_down
                              : Icons.arrow_circle_up,
                          color: transaction['isExpense']
                              ? Colors.red.shade700
                              : Colors.green.shade700,
                        ),
                      ),
                      title: Text(
                        transaction['description'],
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        '${transaction['category']} • ${DateFormat('dd/MM/yyyy').format(transaction['date'])}',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'R\$${transaction['amount'].toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: transaction['isExpense'] 
                                  ? Colors.red.shade700 
                                  : Colors.green.shade700,
                            ),
                          ),
                          Text(
                            transaction['isExpense'] ? 'Despesa' : 'Receita',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assistente Financeiro IA'),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: _getFinancialAdvice,
            tooltip: 'Obter análise financeira',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Seção de adicionar transação
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'Registrar Nova Transação',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _descriptionController,
                            decoration: InputDecoration(
                              labelText: 'Descrição',
                              border: const OutlineInputBorder(),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: _descriptionController.clear,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(
                            _isListening ? Icons.mic_off : Icons.mic,
                            color: _isListening 
                                ? Colors.red.shade700 
                                : Colors.teal.shade700,
                          ),
                          onPressed: _listen,
                          tooltip: 'Reconhecimento de voz',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _amountController,
                            decoration: const InputDecoration(
                              labelText: 'Valor',
                              border: OutlineInputBorder(),
                              prefixText: 'R\$ ',
                            ),
                            keyboardType: TextInputType.numberWithOptions(decimal: true),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: _categoryController,
                            decoration: InputDecoration(
                              labelText: 'Categoria',
                              border: const OutlineInputBorder(),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: _categoryController.clear,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: _pickDate,
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Data',
                                border: OutlineInputBorder(),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    DateFormat('dd/MM/yyyy').format(_selectedDate),
                                  ),
                                  const Icon(Icons.calendar_today),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: SwitchListTile(
                            title: Text(
                              _isExpense ? 'Despesa' : 'Receita',
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            value: _isExpense,
                            onChanged: (value) => setState(() => _isExpense = value),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _addTransaction,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal.shade700,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.add),
                      label: const Text('Adicionar Transação'),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Lista de transações
            _buildTransactionList(),
            
            const SizedBox(height: 20),
            if (_financialAdvice.isNotEmpty) ...[
              const Text(
                'Análise Financeira IA:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: Colors.teal.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
                          ),
                        )
                      : SingleChildScrollView(
                          child: Text(
                            _financialAdvice,
                            style: const TextStyle(
                              height: 1.6,
                              fontSize: 14,
                            ),
                          ),
                        ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _categoryController.dispose();
    _speech.stop();
    super.dispose();
  }
}