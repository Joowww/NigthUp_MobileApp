import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/chat_controller.dart';
import '../theme/colors.dart';

class CreatePollScreen extends StatefulWidget {
  final String?
  groupId; // ✅ MODIFICACIÓN: Parámetro opcional para identificar el grupo

  const CreatePollScreen({
    super.key,
    this.groupId, // ✅ MODIFICACIÓN: Si es null = encuesta independiente, si tiene valor = encuesta de grupo
  });

  @override
  State<CreatePollScreen> createState() => _CreatePollScreenState();
}

class _CreatePollScreenState extends State<CreatePollScreen> {
  final ChatController _chatController = Get.find<ChatController>();
  final TextEditingController _questionController = TextEditingController();
  final List<TextEditingController> _optionControllers = [
    TextEditingController(),
    TextEditingController(),
  ];

  bool isPublic = true;
  DateTime? expiresAt;
  bool isLoading = false;

  @override
  void dispose() {
    _questionController.dispose();
    for (var controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addOption() {
    if (_optionControllers.length < 10) {
      setState(() {
        _optionControllers.add(TextEditingController());
      });
    }
  }

  void _removeOption(int index) {
    if (_optionControllers.length > 2) {
      setState(() {
        _optionControllers[index].dispose();
        _optionControllers.removeAt(index);
      });
    }
  }

  Future<void> _createPoll() async {
    if (_questionController.text.trim().isEmpty) {
      Get.snackbar(
        'Error',
        'Ingresa una pregunta',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final options = _optionControllers
        .map((c) => c.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();

    if (options.length < 2) {
      Get.snackbar(
        'Error',
        'Debes tener al menos 2 opciones',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // ✅ MODIFICACIÓN: Detectar si es encuesta de grupo o independiente
      if (widget.groupId != null) {
        // ✅ MODIFICACIÓN: Es una encuesta DE GRUPO - usar createGroupPoll
        await _chatController.createGroupPoll(
          question: _questionController.text.trim(),
          options: options,
          expiresAt: expiresAt,
        );
      } else {
        // ✅ MODIFICACIÓN: Es una encuesta INDEPENDIENTE - usar createPoll
        await _chatController.createPoll(
          question: _questionController.text.trim(),
          options: options,
          isPublic: isPublic,
          expiresAt: expiresAt,
        );
      }
      Get.back();
    } catch (e) {
      // Error ya manejado en el controller
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ MODIFICACIÓN: Detectar si es encuesta de grupo para cambiar el título
    final isGroupPoll = widget.groupId != null;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        // ✅ MODIFICACIÓN: Título diferente según el tipo de encuesta
        title: Text(isGroupPoll ? 'Crear Encuesta de Grupo' : 'Crear Encuesta'),
        backgroundColor: Colors.black,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ✅ MODIFICACIÓN: Banner informativo si es encuesta de grupo
          if (isGroupPoll) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.group, color: AppColors.primary, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Esta encuesta será visible solo para los miembros del grupo',
                      style: TextStyle(color: AppColors.primary, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          // Pregunta
          const Text(
            'Pregunta',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _questionController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: '¿Cuál es tu género musical favorito?',
              hintStyle: const TextStyle(color: Colors.white30),
              filled: true,
              fillColor: Colors.grey[900],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            maxLines: 2,
            minLines: 1,
          ),

          const SizedBox(height: 24),

          // Opciones
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Opciones',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton.icon(
                onPressed: _optionControllers.length < 10 ? _addOption : null,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Añadir'),
                style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ..._optionControllers.asMap().entries.map((entry) {
            final index = entry.key;
            final controller = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      style: const TextStyle(color: Colors.white),
                      minLines: 1,
                      maxLines: 1,
                      decoration: InputDecoration(
                        hintText: 'Opción ${index + 1}',
                        hintStyle: const TextStyle(color: Colors.white30),
                        filled: true,
                        fillColor: Colors.grey[900],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        prefixIcon: const Icon(
                          Icons.radio_button_unchecked,
                          color: Colors.white30,
                        ),
                      ),
                    ),
                  ),
                  if (_optionControllers.length > 2)
                    IconButton(
                      onPressed: () => _removeOption(index),
                      icon: const Icon(Icons.close, color: Colors.red),
                    ),
                ],
              ),
            );
          }).toList(),

          const SizedBox(height: 24),

          // Configuración
          const Text(
            'Configuración',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          // ✅ MODIFICACIÓN: El switch de "pública" solo se muestra para encuestas independientes
          if (!isGroupPoll) ...[
            SwitchListTile(
              value: isPublic,
              onChanged: (value) {
                setState(() {
                  isPublic = value;
                });
              },
              title: const Text(
                'Encuesta pública',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                isPublic ? 'Todos pueden votar' : 'Solo usuarios seleccionados',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
              activeColor: AppColors.primary,
            ),
          ],

          ListTile(
            leading: const Icon(Icons.calendar_today, color: Colors.white),
            title: const Text(
              'Fecha de expiración',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              expiresAt != null
                  ? '${expiresAt!.day}/${expiresAt!.month}/${expiresAt!.year}'
                  : 'Sin fecha de expiración',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
            trailing: expiresAt != null
                ? IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        expiresAt = null;
                      });
                    },
                  )
                : null,
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now().add(const Duration(days: 7)),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (date != null) {
                setState(() {
                  expiresAt = date;
                });
              }
            },
          ),

          const SizedBox(height: 32),

          // Botón crear
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: isLoading ? null : _createPoll,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Crear Encuesta',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
