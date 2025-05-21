import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'config.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

class MaintenancePage extends StatefulWidget {
  const MaintenancePage({super.key});

  @override
  _MaintenanceSupportPageState createState() => _MaintenanceSupportPageState();
}

class _MaintenanceSupportPageState extends State<MaintenancePage> {
  final TextEditingController _supportMessageController =
      TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  bool _isChatActive = false;
  DateTime? _selectedDate;
  final List<ChatMessage> _messages = [];
  late final GenerativeModel _model;

  @override
  void initState() {
    super.initState();
    _initializeModel();
  }

  void _initializeModel() {
    try {
      _model = GenerativeModel(
        model: Config.modelName,
        apiKey: Config.apiKey,
      );
    } catch (e) {
      print('Error initializing Gemini model: $e');
    }
  }

  void _toggleChat() {
    setState(() {
      _isChatActive = !_isChatActive;
    });
  }

  Future<void> _sendMessage() async {
    final message = _supportMessageController.text.trim();
    if (message.isNotEmpty) {
      setState(() {
        _messages.add(ChatMessage(
            text: message, isUser: true, timestamp: DateTime.now()));
      });

      _supportMessageController.clear();

      try {
        final response = await _model.generateContent([
          Content.text(
            '''You are an expert maintenance support assistant for agricultural and construction equipment. 
            Your role is to help users with:
            1. Equipment maintenance scheduling
            2. Troubleshooting common issues
            3. Preventive maintenance advice
            4. Equipment care tips
            5. Maintenance best practices
            
            Please provide clear, concise, and practical advice. If the query is not maintenance-related, 
            politely redirect the user to the appropriate support channel.
            
            User query: $message''',
          ),
        ]);

        setState(() {
          _messages.add(
            ChatMessage(
              text: response.text ?? 'Sorry, I could not process that request.',
              isUser: false,
              timestamp: DateTime.now(),
            ),
          );
        });
      } catch (e) {
        setState(() {
          _messages.add(
            ChatMessage(
              text:
                  'Sorry, there was an error processing your request. Please check your API key configuration.',
              isUser: false,
              timestamp: DateTime.now(),
            ),
          );
        });
        print('Error sending message: $e');
      }
    }
  }

  Future<void> _pickDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
        _dateController.text = "${pickedDate.toLocal()}".split(' ')[0];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Maintenance & Support',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF4CAF50),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Section(
              title: 'Schedule Maintenance',
              children: [
                DropdownButtonFormField<String>(
                  decoration:
                      const InputDecoration(labelText: 'Select Equipment'),
                  items: const [
                    DropdownMenuItem(
                      value: 'excavator',
                      child: Text('Excavator CAT 320'),
                    ),
                    DropdownMenuItem(
                      value: 'loader',
                      child: Text('Wheel Loader Komatsu WA320'),
                    ),
                    DropdownMenuItem(
                      value: 'crane',
                      child: Text('Mobile Crane XCMG 25T'),
                    ),
                  ],
                  onChanged: (value) {},
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _dateController,
                  decoration: const InputDecoration(
                    labelText: 'Preferred Date',
                    hintText: 'Select a date',
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  readOnly: true,
                  onTap: _pickDate,
                ),
                const SizedBox(height: 16),
                const Text('Priority Level'),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: () {},
                      child: const Text(
                        'Low',
                        style: TextStyle(color: Color(0xFF4CAF50)),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {},
                      child: const Text(
                        'Medium',
                        style: TextStyle(color: Color(0xFF4CAF50)),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {},
                      child: const Text(
                        'High',
                        style: TextStyle(color: Color(0xFF4CAF50)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                 TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Describe the issue...',
                  ),
                  maxLines: 4,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    if (_selectedDate != null) {
                      print('Selected Date: $_selectedDate');
                    } else {
                      print('No date selected');
                    }
                  },
                  child: const Text(
                    'Submit Date',
                    style: TextStyle(color: Color(0xFF4CAF50)),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                  ),
                  child: const Text(
                    'Submit Request',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            const Section(
              title: 'FAQs',
              children: [
                FAQItem(
                  question: 'How do I schedule emergency maintenance?',
                  answer:
                      'Select "High" priority. Our team will respond within 2 hours.',
                ),
                FAQItem(
                  question: "What's included in regular maintenance?",
                  answer:
                      'Includes equipment inspection, oil change, filter replacement, and basic repairs.',
                ),
                FAQItem(
                  question: 'How often should I schedule maintenance?',
                  answer:
                      'Every 250 operating hours or monthly, whichever comes first.',
                ),
              ],
            ),
            Section(
              title: 'Contact Support',
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _supportMessageController,
                  decoration: const InputDecoration(labelText: 'Message'),
                  maxLines: 4,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _sendMessage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                  ),
                  child: const Text(
                    'Send Message',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _toggleChat,
        backgroundColor: const Color(0xFF4CAF50),
        child: const Icon(Icons.message, color: Colors.white),
      ),
      bottomSheet: _isChatActive
          ? ChatWindow(
              onClose: _toggleChat,
              onSendMessage: _sendMessage,
              controller: _supportMessageController,
              messages: _messages,
            )
          : null,
    );
  }
}

class Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const Section({super.key, required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}

class FAQItem extends StatelessWidget {
  final String question;
  final String answer;

  const FAQItem({super.key, required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title:
          Text(question, style: const TextStyle(fontWeight: FontWeight.bold)),
      children: [
        Padding(padding: const EdgeInsets.all(8), child: Text(answer))
      ],
    );
  }
}

class ChatWindow extends StatelessWidget {
  final VoidCallback onClose;
  final VoidCallback onSendMessage;
  final TextEditingController controller;
  final List<ChatMessage> messages;

  const ChatWindow({
    super.key,
    required this.onClose,
    required this.onSendMessage,
    required this.controller,
    required this.messages,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      height: 500,
      color: Colors.white,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  CircleAvatar(radius: 8, backgroundColor: Colors.green),
                  SizedBox(width: 8),
                  Text(
                    'Support Chat',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              IconButton(icon: const Icon(Icons.close), onPressed: onClose),
            ],
          ),
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                return Align(
                  alignment: message.isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:
                          message.isUser ? Colors.green[100] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(message.text),
                  ),
                );
              },
            ),
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration:
                      const InputDecoration(hintText: 'Type your message...'),
                ),
              ),
              IconButton(
                  icon: const Icon(Icons.send), onPressed: onSendMessage),
            ],
          ),
        ],
      ),
    );
  }
}
