import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

// Fill in the app ID obtained from Agora Console
const appId = "6c65142d2fcb4d808b7539581e95b0fd";
// Fill in the temporary token generated from Agora Console
const token = "007eJxTYFik71H/51Nas5lSlI1v9ayQI2bS1QqHl04+tEL1n+NCTl4FBrNkM1NDE6MUo7TkJJMUCwOLJHNTY0tTC8NUS9Mkg7QUkwW5WQ2BjAwfNl5nYmJgBEMQn5UhMS+vMpGBgQkuxMJgaGBgCAABryCl";
// Fill in the channel name you used to generate the token
const channel = "annya";

// Main App Widget
class ActivitiesPage extends StatelessWidget {
 const ActivitiesPage({Key? key}) : super(key: key);

 @override
 Widget build(BuildContext context) {
  return const MaterialApp(
   home: _MainScreen(),
  );
 }
}

// Voice call Screen Widget
class _MainScreen extends StatefulWidget {
 const _MainScreen({Key? key}) : super(key: key);

 @override
 _MainScreenScreenState createState() => _MainScreenScreenState();
}

class _MainScreenScreenState extends State<_MainScreen> {
 late RtcEngine _engine; // Stores Agora RTC Engine instance
 int? _remoteUid; // Stores the remote user's UID

 @override
 void initState() {
  super.initState();
  _startVoiceCalling();
 }

 // Initializes Agora SDK
 Future<void> _startVoiceCalling() async {
  await _requestPermissions();
  await _initializeAgoraVoiceSDK();
  _setupEventHandlers();
  await _joinChannel();
 }

 // Requests microphone permission
 Future<void> _requestPermissions() async {
  await [Permission.microphone].request();
 }

 // Set up the Agora RTC engine instance
 Future<void> _initializeAgoraVoiceSDK() async {
  _engine = createAgoraRtcEngine();
  await _engine.initialize(const RtcEngineContext(
   appId: appId,
   channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
  ));
 }

 // Register an event handler for Agora RTC
 void _setupEventHandlers() {
  _engine.registerEventHandler(
   RtcEngineEventHandler(
    onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
     debugPrint("Local user \${connection.localUid} joined");
    },
    onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
     debugPrint("Remote user \$remoteUid joined");
     setState(() {
      _remoteUid = remoteUid; // Store remote user ID
     });
    },
    onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
     debugPrint("Remote user \$remoteUid left");
     setState(() {
      _remoteUid = null; // Remove remote user ID
     });
    },
   ),
  );
 }

 // Join a channel
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

 @override
 void dispose() {
  _cleanupAgoraEngine();
  super.dispose();
 }

 // Leaves the channel and releases resources
 Future<void> _cleanupAgoraEngine() async {
  await _engine.leaveChannel();
  await _engine.release();
 }

 @override
 Widget build(BuildContext context) {
  return MaterialApp(
   title: 'Agora Voice Call',
   home: Scaffold(
    appBar: AppBar(
     title: const Text('Agora Voice Call'),
    ),
    body: Center(
     child: Text(
      _remoteUid != null
        ? "Remote user $_remoteUid joined"
        : "No remote user in the channel", // Show appropriate message
      style: const TextStyle(fontSize: 18),
     ),
    ),
   ),
  );
 }
}