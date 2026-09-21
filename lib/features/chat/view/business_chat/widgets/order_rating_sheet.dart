import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/business/auth/repo/business_profile_repo.dart';
import 'package:BlueEra/features/chat/view/business_chat/widgets/order_card_ui.dart';
import 'package:flutter/material.dart';

/// **`How was your ride?` / `Rate your experience`** — the board's rating
/// block, as a sheet.
///
/// The rider's completion screen draws it inline and the customer's picked-up
/// card reaches it from a button; both are the same five stars, the same word
/// under them and the same optional line of review, so there is one of it.
///
/// Two things it deliberately does not do:
///
/// * **It never rates on behalf of the person.** No star is pre-selected and
///   `Submit` stays disabled until one is, because a sheet that opens on five
///   stars collects five stars from everyone who taps through it.
/// * **It does not block the order.** Rating is the last thing that happens
///   and it changes nothing about the order's state, so the sheet closes on a
///   failed submit with a message rather than trapping the person in a retry.
Future<bool> showOrderRatingSheet(
  BuildContext context, {
  /// The shop being rated. Empty means there is nobody to rate.
  required String businessId,
  String? shopName,
  String title = 'Rate your experience',
  String question = 'How was your order?',
}) async {
  if (businessId.trim().isEmpty) {
    commonSnackBar(message: "We can't tell which shop this order was from.");
    return false;
  }
  final done = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _OrderRatingSheet(
      businessId: businessId.trim(),
      shopName: shopName,
      title: title,
      question: question,
    ),
  );
  return done ?? false;
}

class _OrderRatingSheet extends StatefulWidget {
  final String businessId;
  final String? shopName;
  final String title;
  final String question;

  const _OrderRatingSheet({
    required this.businessId,
    required this.title,
    required this.question,
    this.shopName,
  });

  @override
  State<_OrderRatingSheet> createState() => _OrderRatingSheetState();
}

class _OrderRatingSheetState extends State<_OrderRatingSheet> {
  int _stars = 0;
  bool _sending = false;
  final TextEditingController _review = TextEditingController();

  /// The board writes the word, not the number — `4/5` is a score, `Great` is
  /// an opinion, and the second is what someone is actually being asked for.
  static const _words = ['', 'Poor', 'Fair', 'Good', 'Great', 'Excellent'];

  @override
  void dispose() {
    _review.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_stars == 0 || _sending) return;
    setState(() => _sending = true);
    try {
      final res = await BusinessProfileRepo().submitRatingToBusinessAccount(
        widget.businessId,
        {'rating': _stars, 'comment': _review.text.trim()},
      );
      if (!mounted) return;
      if (res.isSuccess) {
        Navigator.of(context).pop(true);
        commonSnackBar(message: 'Thank you for your rating!');
      } else {
        // Closed, not trapped: rating changes nothing about the order, so a
        // failure is worth a sentence and not a locked sheet.
        Navigator.of(context).pop(false);
        commonSnackBar(
            message: res.message ?? "That didn't go through. Try again later.");
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 6),
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD8DCE3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(widget.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                            color: OrderUi.ink)),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: OrderUi.block,
                        borderRadius:
                            BorderRadius.circular(OrderUi.blockRadius),
                      ),
                      child: Column(
                        children: [
                          Text(widget.question,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: OrderUi.ink)),
                          const SizedBox(height: 4),
                          Text(
                            widget.shopName == null
                                ? 'Your feedback helps us improve'
                                : 'Your feedback helps ${widget.shopName} improve',
                            textAlign: TextAlign.center,
                            style: OrderUi.blockBody,
                          ),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(5, (i) {
                              final filled = i < _stars;
                              return GestureDetector(
                                onTap: () => setState(() => _stars = i + 1),
                                behavior: HitTestBehavior.opaque,
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 6),
                                  child: Icon(
                                    filled
                                        ? Icons.star_rounded
                                        : Icons.star_outline_rounded,
                                    size: 38,
                                    color: filled
                                        ? const Color(0xFFF5B51E)
                                        : const Color(0xFFC6CCD6),
                                  ),
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 6),
                          SizedBox(
                            height: 20,
                            child: Text(
                              _stars == 0 ? '' : _words[_stars],
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: OrderUi.green),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _review,
                            maxLines: 3,
                            maxLength: 300,
                            style: const TextStyle(
                                fontSize: 14, color: OrderUi.ink),
                            decoration: InputDecoration(
                              hintText: 'Write a short review',
                              hintStyle: OrderUi.blockBody,
                              counterText: '',
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.all(12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                    color: OrderUi.blockBorder),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                    color: OrderUi.blockBorder),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide:
                                    const BorderSide(color: OrderUi.blue),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          OrderButton(
                            label: 'Submit',
                            busy: _sending,
                            // No star, no submit: a sheet that opens on five
                            // stars collects five stars from everyone who taps
                            // straight through it.
                            onTap: _stars == 0 ? null : _submit,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
