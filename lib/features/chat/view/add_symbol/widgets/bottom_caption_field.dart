import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../auth/controller/add_chat_symbol_controller.dart';
import '../../contacts/view/be_available_contacts_list.dart';

class BottomCaptionField extends StatelessWidget {
  const BottomCaptionField({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<AddChatSymbolController>();

    return Obx(() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          _buildDivider(),
          const SizedBox(height: 20),

          // Tag friends header
          GestureDetector(
            onTap: () {
              Get.to(() => BeAvailableContactsList(
                    preSelectedUsers: c.onTagSelectedList,
                    maxSelectionCount: 5,
                    tagPersonsSelection: true,
                    isFromAddMember: true,
                    onSelectedPersons: (selectedPersonsList) {
                      c.onTagSelectedList.value = selectedPersonsList;
                    },
                  ));
            },
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7971E).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.person_pin_rounded,
                      size: 16, color: Color(0xFFF7971E)),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Tag Friends',
                    style: TextStyle(
                      color: Color(0xFF2D3142),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F8),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded,
                          size: 16,
                          color: const Color(0xFF2D3142).withOpacity(0.5)),
                      const SizedBox(width: 4),
                      Text(
                        'Add',
                        style: TextStyle(
                          color: const Color(0xFF2D3142).withOpacity(0.5),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Tagged user chips
          if (c.onTagSelectedList.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: c.onTagSelectedList.map((user) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF0086FF).withOpacity(0.06),
                        const Color(0xFF0086FF).withOpacity(0.02),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF0086FF).withOpacity(0.12),
                    ),
                  ),
                  padding:
                      const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 10,
                        backgroundColor:
                            const Color(0xFF0086FF).withOpacity(0.15),
                        child: Text(
                          (user.name ?? 'U')[0].toUpperCase(),
                          style: const TextStyle(
                            color: Color(0xFF0086FF),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 120),
                        child: Text(
                          user.name ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF0086FF),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => c.onTagSelectedList.remove(user),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2D3142).withOpacity(0.08),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close_rounded,
                            size: 12,
                            color: const Color(0xFF2D3142).withOpacity(0.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      );
    });
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            const Color(0xFF2D3142).withOpacity(0.08),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}
