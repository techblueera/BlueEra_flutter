import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

/// Entry point for the overlay — runs as a separate Flutter engine.
/// Registered in main.dart with @pragma("vm:entry-point").
@pragma("vm:entry-point")
void overlayMain() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: CallerOverlayWidget(),
  ));
}

class CallerOverlayWidget extends StatefulWidget {
  const CallerOverlayWidget({super.key});

  @override
  State<CallerOverlayWidget> createState() => _CallerOverlayWidgetState();
}

class _CallerOverlayWidgetState extends State<CallerOverlayWidget> {
  String _callerName = '';
  String _callTime = '00:00';
  bool _isVideo = false;

  @override
  void initState() {
    super.initState();
    FlutterOverlayWindow.overlayListener.listen((data) {
      if (data is Map) {
        setState(() {
          if (data['action'] == 'start') {
            _callerName = data['callerName'] ?? '';
            _isVideo = data['isVideo'] ?? false;
            if (data['callTime'] != null) {
              _callTime = data['callTime'];
            }
          } else if (data['action'] == 'updateTimer') {
            _callTime = data['time'] ?? '00:00';
          }
        });
      }
    });
  }

  void _onHangUp() {
    FlutterOverlayWindow.shareData({'action': 'hangup'});
    FlutterOverlayWindow.closeOverlay();
  }

  void _onTapExpand() {
    FlutterOverlayWindow.shareData({'action': 'expand'});
  }

  @override
  Widget build(BuildContext context) {
    if (_isVideo) {
      return _buildVideoOverlay();
    }
    return _buildAudioOverlay();
  }

  Widget _buildAudioOverlay() {
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: _onTapExpand,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF00A884),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.phone_in_talk, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _callerName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      _callTime,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _onHangUp,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.call_end, color: Colors.white, size: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoOverlay() {
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: _onTapExpand,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.videocam, color: Colors.white54, size: 32),
                    const SizedBox(height: 4),
                    Text(
                      _callerName,
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    Text(
                      _callTime,
                      style: const TextStyle(color: Colors.white54, fontSize: 10),
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: 8,
                right: 8,
                child: GestureDetector(
                  onTap: _onHangUp,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.call_end, color: Colors.white, size: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
