import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

// Fill in the app ID obtained from Agora Console
const appId = "6c65142d2fcb4d808b7539581e95b0fd";
// Fill in the temporary token generated from Agora Console
const token =
    "007eJxTYJA+9uNpR87bS/lWfQtLGey5RIJXF1p6z+QMSjjx0pm3QEaBwSzZzNTQxCjFKC05ySTFwsAiydzU2NLUwjDV0jTJIC1lZ1pDVkMgI8P/AjtGJgZGMATxeRhSUnPzdZMzEvPyUnMYGJjgMiwMhgYGhgD2hiJ+";
// Fill in the channel name you used to generate the token
const channel = "demo-channel";

/// Voice call page using Agora RTC.
///
/// - Tap "开始通话" to join the channel and start voice
/// - Tap microphone icon to mute / unmute
/// - Tap "挂断" to leave the channel
class ActivitiesPage extends StatefulWidget {
  const ActivitiesPage({super.key});

  @override
  State<ActivitiesPage> createState() => _ActivitiesPageState();
}

class _ActivitiesPageState extends State<ActivitiesPage> {
  late RtcEngine _engine;
  int? _remoteUid;
  bool _isJoined = false;
  bool _isMuted = false;
  int _callSeconds = 0;
  Timer? _callTimer;

  @override
  void dispose() {
    _stopCallTimer();
    _cleanupAgoraEngine();
    super.dispose();
  }

  // ── Call controls ──

  Future<void> _startCall() async {
    await _requestPermissions();
    await _initializeAgoraVoiceSDK();
    _setupEventHandlers();
    await _joinChannel();
  }

  Future<void> _endCall() async {
    await _cleanupAgoraEngine();
    setState(() {
      _isJoined = false;
      _remoteUid = null;
    });
    _stopCallTimer();
  }

  void _toggleMute() {
    if (!_isJoined) return;
    _isMuted = !_isMuted;
    _engine.setEnableSpeakerphone(!_isMuted);
    _engine.muteLocalAudioStream(_isMuted);
    setState(() {});
  }

  // ── Agora setup ──

  Future<void> _requestPermissions() async {
    await [Permission.microphone].request();
  }

  Future<void> _initializeAgoraVoiceSDK() async {
    _engine = createAgoraRtcEngine();
    await _engine.initialize(const RtcEngineContext(
      appId: appId,
      channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
    ));
  }

  void _setupEventHandlers() {
    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          debugPrint("Local user ${connection.localUid} joined");
          setState(() => _isJoined = true);
          _startCallTimer();
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          debugPrint("Remote user $remoteUid joined");
          setState(() => _remoteUid = remoteUid);
        },
        onUserOffline: (RtcConnection connection, int remoteUid,
            UserOfflineReasonType reason) {
          debugPrint("Remote user $remoteUid left");
          setState(() => _remoteUid = null);
        },
      ),
    );
  }

  Future<void> _joinChannel() async {
    await _engine.joinChannel(
      token: token,
      channelId: channel,
      options: const ChannelMediaOptions(
        autoSubscribeAudio: true,
        publishMicrophoneTrack: true,
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
      ),
      uid: 0,
    );
  }

  Future<void> _cleanupAgoraEngine() async {
    if (!_isJoined) return;
    await _engine.leaveChannel();
    await _engine.release();
  }

  // ── Call timer ──

  void _startCallTimer() {
    _callTimer?.cancel();
    _callSeconds = 0;
    _callTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _callSeconds++);
    });
  }

  void _stopCallTimer() {
    _callTimer?.cancel();
    _callTimer = null;
  }

  String _formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ── UI ──

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('语音通话')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Avatar / status
            CircleAvatar(
              radius: 48,
              backgroundColor:
                  Theme.of(context).colorScheme.primaryContainer,
              child: Icon(
                _isMuted ? Icons.mic_off : Icons.mic,
                size: 40,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 24),

            // Status text
            Text(
              _isJoined
                  ? (_remoteUid != null
                      ? '通话中 · ${_formatDuration(_callSeconds)}'
                      : '等待对方加入 · ${_formatDuration(_callSeconds)}')
                  : '未加入频道',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            if (_isJoined && _remoteUid != null)
              Text('对方 UID: $_remoteUid',
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 40),

            // Call controls
            if (!_isJoined)
              FilledButton.icon(
                onPressed: _startCall,
                icon: const Icon(Icons.call),
                label: const Text('开始通话'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32, vertical: 12),
                ),
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Mute toggle
                  IconButton.filled(
                    onPressed: _toggleMute,
                    icon: Icon(_isMuted ? Icons.mic_off : Icons.mic),
                    style: IconButton.styleFrom(
                      backgroundColor:
                          _isMuted ? Colors.orange : Colors.blueGrey,
                      foregroundColor: Colors.white,
                    ),
                    tooltip: _isMuted ? '取消静音' : '静音',
                  ),
                  const SizedBox(width: 24),
                  // End call
                  IconButton.filled(
                    onPressed: _endCall,
                    icon: const Icon(Icons.call_end),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    tooltip: '挂断',
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
