import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'transaction_screen.dart'; 


const String BACKEND_BASE = 'http://10.0.2.2:4000';


const Color kPrimaryColor = Color(0xFF1E3A8A); 
const Color kAccentColor = Color(0xFF3B82F6);  
const Color kBgColor = Color(0xFFF1F5F9);     

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _userCtrl = TextEditingController(text: 'demo_user');
  final TextEditingController _passCtrl = TextEditingController(text: 'password');
  
  bool _isLoading = false;
  final String _deviceId = "dev_${Random().nextInt(9999)}"; 

  @override
  void initState() {
    super.initState();
    _initNotifications();
  }

  void _initNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }


  Future<void> _handleLogin() async {
    setState(() => _isLoading = true);

    try {
      final res = await http.post(
        Uri.parse('$BACKEND_BASE/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': _userCtrl.text, 
          'device_id': _deviceId
        }),
      );

      final data = jsonDecode(res.body);
      final status = data['status'];
      final eventId = data['event_id'] ?? 'unknown_event'; 

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (status == 'TRUSTED') {
        _startTrustedProtocol(eventId);
      } else {
        _startBindingProtocol(eventId);
      }

    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Connection Error: $e")));
    }
  }

  void _startTrustedProtocol(String eventId) {
    _showUnifiedCheckSheet(isTrusted: true, eventId: eventId);
  }

  void _startBindingProtocol(String eventId) {
    _showUnifiedCheckSheet(isTrusted: false, eventId: eventId);
  }

  void _showUnifiedCheckSheet({required bool isTrusted, required String eventId}) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _UnifiedCheckSheet(
        deviceId: _deviceId,
        isTrusted: isTrusted,
        onTrustedComplete: () {
          Navigator.pop(ctx); 
          _showTrustedFlash(eventId); 
        },
        onBindingComplete: () async {
          Navigator.pop(ctx); 
          String smsOtp = "${Random().nextInt(900000) + 100000}";
          await _showSmsNotification(smsOtp);
          _showOtpInput(eventId, smsOtp);    
        },
      ),
    );
  }

  void _showTrustedFlash(String eventId) async {
    final String otp = "${Random().nextInt(9000) + 1000}";

    final result = await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _TrustedFlashDialog(otp: otp),
    );

    if (!mounted) return;

    if (result == 'APPROVE') {
      try {
        await http.post(Uri.parse('$BACKEND_BASE/ack'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'event_id': eventId, 'channel': 'IN_APP_FLASH'})
        );
      } catch(e) { print("Ack Error: $e"); }
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const TransactionScreen()));

    } else if (result == 'TIMEOUT') {
      try {
        await http.post(Uri.parse('$BACKEND_BASE/ack'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'event_id': eventId, 'channel': 'TIMEOUT'})
        );
      } catch(e) { print("Ack Error: $e"); }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("⚠️ Login Timed Out."),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        )
      );
    } else {
      try {
        await http.post(Uri.parse('$BACKEND_BASE/ack'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'event_id': eventId, 'channel': 'DECLINED'})
        );
      } catch(e) { print("Ack Error: $e"); }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Login Declined"), backgroundColor: Colors.red)
      );
    }
  }

  Future<void> _showSmsNotification(String otp) async {
    final Person sender = Person(
      name: 'Messages • VK-HDFCBK-S 🛡️',
      icon: const DrawableResourceAndroidIcon('icon_sms'), 
      key: 'bot',
    );
    final Message message = Message('Your login OTP is $otp. Do not share this code.', DateTime.now(), sender);
    final MessagingStyleInformation messagingStyle = MessagingStyleInformation(sender, groupConversation: false, messages: [message]);
    
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'binding_otp_channel', 'Security Alerts',
      importance: Importance.max, priority: Priority.high,
      icon: '@mipmap/ic_launcher', color: kPrimaryColor,
      styleInformation: messagingStyle,
    );
    
    await flutterLocalNotificationsPlugin.show(101, null, null, NotificationDetails(android: androidDetails));
  }

  void _showOtpInput(String eventId, String expectedOtp) async {
    final result = await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _BindingOtpDialog(eventId: eventId, expectedOtp: expectedOtp),
    );

    if (!mounted) return;

    if (result == 'SUCCESS') {
      try {
        await http.post(Uri.parse('$BACKEND_BASE/complete-binding'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'user_id': _userCtrl.text, 'device_id': _deviceId, 'event_id': eventId})
        );
      } catch (e) { print("Backend error: $e"); }
      
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Device Bound Successfully!"), backgroundColor: Colors.green));
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const TransactionScreen()));

    } else if (result == 'TIMEOUT') {
      try {
        await http.post(Uri.parse('$BACKEND_BASE/ack'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'event_id': eventId, 'channel': 'TIMEOUT'})
        );
      } catch(e) { print("Ack Error: $e"); }
      
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Verification Timed Out"), backgroundColor: Colors.orange));
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      body: LayoutBuilder(
        builder: (context, constraints) {
          
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: IntrinsicHeight(
                child: Stack(
                  children: [
                    
                    Container(
                      height: 300,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [kPrimaryColor, kAccentColor],
                        ),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(30),
                          bottomRight: Radius.circular(30),
                        )
                      ),
                    ),
                    
                    
                    Center(
                      child: Container(
                        width: min(400, constraints.maxWidth * 0.9), 
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 60),
                            // App Logo/Title
                            const Icon(Icons.shield_moon_rounded, size: 80, color: Colors.white),
                            const SizedBox(height: 16),
                            const Text(
                              "TrustSync Identity",
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1.2
                              ),
                            ),
                            const SizedBox(height: 40),

                            // Login Card
                            Card(
                              elevation: 8,
                              shadowColor: Colors.black26,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                              color: Colors.white,
                              child: Padding(
                                padding: const EdgeInsets.all(28.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    const Text("Welcome Back", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
                                    const SizedBox(height: 8),
                                    const Text("Enter your credentials to access banking.", style: TextStyle(fontSize: 14, color: Colors.grey)),
                                    const SizedBox(height: 30),
                                    
                                    // User Field
                                    TextField(
                                      controller: _userCtrl,
                                      decoration: _inputDecoration("Customer ID", Icons.person_outline),
                                    ),
                                    const SizedBox(height: 20),
                                    
                                    // Password Field
                                    TextField(
                                      controller: _passCtrl,
                                      obscureText: true,
                                      decoration: _inputDecoration("Password", Icons.lock_outline),
                                    ),
                                    const SizedBox(height: 30),
                                    
                                    // Login Button
                                    SizedBox(
                                      height: 56,
                                      child: ElevatedButton(
                                        onPressed: _isLoading ? null : _handleLogin,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: kPrimaryColor,
                                          foregroundColor: Colors.white,
                                          elevation: 4,
                                          shadowColor: kPrimaryColor.withOpacity(0.4),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        ),
                                        child: _isLoading 
                                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)) 
                                          : const Text("SECURE LOGIN", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 30),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                "Device ID: $_deviceId",
                                style: TextStyle(color: Colors.grey[600], fontSize: 12, fontFamily: 'monospace'),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.grey[600]),
      filled: true,
      fillColor: Colors.grey[50],
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: kPrimaryColor, width: 2),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
    );
  }
}


class _BindingOtpDialog extends StatefulWidget {
  final String eventId;
  final String expectedOtp;
  const _BindingOtpDialog({required this.eventId, required this.expectedOtp});
  @override
  State<_BindingOtpDialog> createState() => _BindingOtpDialogState();
}

class _BindingOtpDialogState extends State<_BindingOtpDialog> {
  final TextEditingController _otpCtrl = TextEditingController();
  int _timeLeft = 60;
  late Stream<int> _timerStream;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _timerStream = Stream.periodic(const Duration(seconds: 1), (i) => 60 - i - 1).take(60);
    _timerStream.listen((timeLeft) {
      if (mounted) setState(() => _timeLeft = timeLeft);
      if (timeLeft == 0) Navigator.pop(context, 'TIMEOUT');
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("New Device", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
            child: Text("$_timeLeft s", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _timeLeft < 10 ? Colors.red : Colors.black87)),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("We sent a code to your registered mobile number ending in **89.", style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          const SizedBox(height: 24),
          TextField(
            controller: _otpCtrl,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 6,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 12),
            decoration: InputDecoration(
                counterText: "",
                hintText: "------",
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)
            ),
          ),
        ],
      ),
      actionsPadding: const EdgeInsets.all(24),
      actions: [
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: _isChecking ? null : () async {
              if (_otpCtrl.text.trim() != widget.expectedOtp) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Incorrect OTP."), backgroundColor: Colors.red));
                return;
              }
              Navigator.pop(context, 'SUCCESS');
            },
            child: const Text("VERIFY & BIND", style: TextStyle(fontWeight: FontWeight.bold))
          ),
        )
      ],
    );
  }
}


class _UnifiedCheckSheet extends StatefulWidget {
  final String deviceId;
  final bool isTrusted;
  final VoidCallback onTrustedComplete;
  final VoidCallback onBindingComplete;

  const _UnifiedCheckSheet({required this.deviceId, required this.isTrusted, required this.onTrustedComplete, required this.onBindingComplete});

  @override
  State<_UnifiedCheckSheet> createState() => _UnifiedCheckSheetState();
}

class _UnifiedCheckSheetState extends State<_UnifiedCheckSheet> {
  int _step = 0; 
  @override
  void initState() {
    super.initState();
    _runSequence();
  }

  void _runSequence() async {
    await Future.delayed(const Duration(milliseconds: 2500));
    if(!mounted) return;
    setState(() => _step = 1); 

    if (widget.isTrusted) {
      await Future.delayed(const Duration(milliseconds: 1500));
      if(!mounted) return;
      widget.onTrustedComplete();
    } else {
      await Future.delayed(const Duration(seconds: 2));
      if(!mounted) return;
      setState(() => _step = 2);
      await Future.delayed(const Duration(seconds: 3));
      if(!mounted) return;
      widget.onBindingComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      height: 380,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          const Spacer(),
          AnimatedSwitcher(
             duration: const Duration(milliseconds: 500),
             transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
             child: _getIcon(),
          ),
          const SizedBox(height: 32),
          Text(_getTitle(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
          const SizedBox(height: 12),
          Text(_getDesc(), style: TextStyle(color: Colors.grey[600], fontSize: 15, height: 1.4), textAlign: TextAlign.center),
          const Spacer(),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              minHeight: 6,
              value: (widget.isTrusted && _step == 1) ? 1.0 : (_step + 1) / 3,
              color: _getColors(), 
              backgroundColor: Colors.grey[100]
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _getIcon() {
    if (_step == 0) return Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.search, size: 48, color: Colors.orange));
    if (widget.isTrusted) return Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.check_circle, size: 48, color: Colors.green));
    else {
      if (_step == 2) return Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.phonelink_setup, size: 48, color: Colors.blue));
      return Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.warning_amber_rounded, size: 48, color: Colors.red));
    }
  }

  Color _getColors() {
    if (_step == 0) return Colors.orange;
    if (widget.isTrusted) return Colors.green;
    if (_step == 2) return Colors.blue;
    return Colors.red;
  }

  String _getTitle() {
    if (_step == 0) return "Checking Registry...";
    if (widget.isTrusted) return "Identity Verified";
    if (_step == 2) return "Binding New Device...";
    return "Device Mismatch";
  }

  String _getDesc() {
    if (_step == 0) return "Verifying Device ID against secure vault:\n${widget.deviceId}";
    if (widget.isTrusted) return "Device recognized. Initiating secure flash handshake.";
    if (_step == 2) return "Sending encrypted SMS to verify ownership.";
    return "This device is not in your trusted list.";
  }
}


class _TrustedFlashDialog extends StatefulWidget {
  final String otp;
  const _TrustedFlashDialog({required this.otp});
  @override
  State<_TrustedFlashDialog> createState() => _TrustedFlashDialogState();
}

class _TrustedFlashDialogState extends State<_TrustedFlashDialog> {
  int _timeLeft = 20; 
  late Stream<int> _timerStream;

  @override
  void initState() {
    super.initState();
    _timerStream = Stream.periodic(const Duration(seconds: 1), (i) => 20 - i - 1).take(20);
    _timerStream.listen((timeLeft) {
      if (mounted) setState(() => _timeLeft = timeLeft);
      if (timeLeft == 0) Navigator.pop(context, 'TIMEOUT');
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      contentPadding: const EdgeInsets.all(24),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.amber[50], borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.bolt_rounded, color: Colors.amber, size: 28),
              ),
              const SizedBox(width: 12),
              const Expanded(child: Text("Instant Flash", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _timeLeft <= 5 ? Colors.red[50] : Colors.blue[50], 
                  borderRadius: BorderRadius.circular(20)
                ),
                child: Text(
                  '${_timeLeft}s', 
                  style: TextStyle(
                    color: _timeLeft <= 5 ? Colors.red : kPrimaryColor, 
                    fontWeight: FontWeight.bold, 
                    fontSize: 13
                  )
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // OTP Box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF), 
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue.withOpacity(0.2))
            ),
            child: Column(
              children: [
                const Text("SECURE LOGIN OTP", style: TextStyle(fontSize: 11, color: kPrimaryColor, fontWeight: FontWeight.bold, letterSpacing: 1)),
                const SizedBox(height: 8),
                Text(widget.otp, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800, letterSpacing: 6, color: Colors.black87)),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: _timeLeft / 20,
              backgroundColor: Colors.grey[100],
              color: _timeLeft <= 5 ? Colors.red : kPrimaryColor,
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 16),
          
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shield_outlined, size: 16, color: Colors.green),
              SizedBox(width: 6),
              Text("Verified by TrustSync Engine", style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 24),
          
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, 'DECLINE'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: Colors.grey[300]!),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    foregroundColor: Colors.grey[700]
                  ),
                  child: const Text("DECLINE"),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, 'APPROVE'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor, 
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0
                  ),
                  child: const Text("APPROVE", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}