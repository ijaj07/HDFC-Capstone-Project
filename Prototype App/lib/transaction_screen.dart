import 'dart:convert';
import 'dart:math';
import 'dart:io';
import 'dart:ui'; 
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:http/http.dart' as http;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

// --- CONFIG ---
const String BACKEND_BASE = 'http://10.0.2.2:4000';
const Color kPrimaryColor = Color(0xFF1E3A8A);
const Color kAccentColor = Color(0xFF3B82F6);

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  final DarwinInitializationSettings initializationSettingsDarwin =
      DarwinInitializationSettings();

  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsDarwin,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  runApp(const TrustSyncApp());
}

class TrustSyncApp extends StatelessWidget {
  const TrustSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TrustSync Transaction Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: kPrimaryColor,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
          iconTheme: IconThemeData(color: Colors.white),
        ),
      ),
      home: const TransactionScreen(),
    );
  }
}

class TransactionScreen extends StatefulWidget {
  const TransactionScreen({super.key});

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  final String _userId = 'demo_user';
  final TextEditingController _payeeController =
      TextEditingController(text: 'Amazon India Pvt Ltd');
  final TextEditingController _amountController =
      TextEditingController(text: '12499');

  bool _loading = false;
  String? _status;
  String? _channel;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      await Permission.notification.request();
    }
  }

  // --- 1. NOTIFICATION LOGIC  ---
  Future<void> _showLocalNotification(String channel, String amount) async {
    final randomOtp = Random().nextInt(900000) + 100000;

    String title = 'HDFC Bank Alert';
    String body = 'OTP $randomOtp for txn of ₹$amount. (via $channel)';
    String iconName = 'icon_sms';

    if (channel == 'WHATSAPP') {
      title = 'WhatsApp • HDFC Bank ☑️';
      body = 'Verify payment of ₹$amount to Amazon. Code: $randomOtp';
      iconName = 'icon_whatsapp';
    } else if (channel == 'PUSH') {
      title = 'HDFC Bank Mobile';
      body =
          'Secure Alert: OTP $randomOtp for payment of ₹$amount to ${_payeeController.text}.';
      iconName = 'icon_bank';
    } else {
      title = 'Messages • VK-HDFCBK-S 🛡️';
      body =
          'OTP is $randomOtp for txn of INR $amount at Amazon. Do not share this.';
      iconName = 'icon_sms';
    }

    final Person sender = Person(
      name: title,
      icon: DrawableResourceAndroidIcon(iconName),
      key: 'bot',
    );

    final Message message = Message(
      body,
      DateTime.now(),
      sender,
    );

    final MessagingStyleInformation messagingStyle = MessagingStyleInformation(
      sender,
      groupConversation: false,
      messages: [message],
    );

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'trustsync_txn_id',
      'Transaction Alerts',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFF1E3A8A),
      styleInformation: messagingStyle,
    );

    final NotificationDetails details =
        NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(0, null, null, details);
  }

  // --- 2. IN-APP FLASH DIALOG  ---
  void _showInAppFlash(String amount, String eventId) async {
    final randomOtp = Random().nextInt(900000) + 100000;

    final result = await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          _FlashCountdownDialog(amount: amount, otp: '$randomOtp'),
    );

    if (!mounted) return;

    if (result == 'APPROVE') {
      _sendAck(eventId, 'IN_APP');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("✅ Transaction Verified"),
          backgroundColor: Colors.green));
    } else if (result == 'TIMEOUT') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("⚠️ Request Timed Out"),
          backgroundColor: Colors.orange));
    } else {
      _sendAck(eventId, 'DECLINED');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Transaction Declined"), backgroundColor: Colors.red));
    }
  }

  // --- 3. AUTO-ACKNOWLEDGE TO BACKEND  ---
  Future<void> _sendAck(String eventId, String channel) async {
    await Future.delayed(const Duration(seconds: 2));
    print("🚀 Sending ACK for $eventId...");

    try {
      final response = await http.post(
        Uri.parse('$BACKEND_BASE/ack'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'event_id': eventId, 'channel': channel}),
      );

      if (response.statusCode == 200) {
        print("✅ ACK Sent!");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Device ACK sent to TrustSync Engine'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ));
        }
      }
    } catch (e) {
      print("❌ Failed to send ACK: $e");
    }
  }

  Future<void> _initiateTransaction() async {
    setState(() {
      _loading = true;
      _status = 'Requesting OTP...';
      _channel = null;
    });

    try {
      final uri = Uri.parse('$BACKEND_BASE/send-notification');

      final payload = {
        'event_type': 'TRANSACTION_OTP',
        'user_id': _userId,
        'user_context': {
          'has_app': true,
          'is_active': false,
          'device_online': true,
          'whatsapp_opt_in': true,
        },
      };

      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (!mounted) return;

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final ch = (body['chosen_channel'] ?? 'UNKNOWN').toString();
        final evtId = (body['event_id'] ?? '').toString();

        setState(() {
          _channel = ch;
          _status = 'Route Chosen: $ch';
        });

        if (ch == 'IN_APP') {
          _showInAppFlash(_amountController.text, evtId);
        } else if (['PUSH', 'WHATSAPP', 'SMS'].contains(ch)) {
          _showLocalNotification(ch, _amountController.text);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('OTP sent via $ch'),
            backgroundColor: ch == 'IN_APP' ? Colors.green[600] : Colors.indigo,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        setState(() => _status = 'Backend Error: ${res.statusCode}');
      }
    } catch (e) {
      setState(() => _status = 'Connection Failed');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Payments'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [kPrimaryColor, Color(0xFFF3F4F6)],
                stops: [0.3, 0.3],
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 10),
                  // Main Card
                  Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 32, horizontal: 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10))
                      ],
                    ),
                    child: Column(
                      children: [
                        // Avatar with glow effect
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.orange.withOpacity(0.2),
                                width: 2),
                          ),
                          child: CircleAvatar(
                            radius: 32,
                            backgroundColor: const Color(0xFFFFF7ED),
                            child: const Icon(Icons.storefront_rounded,
                                color: Color(0xFFF97316), size: 32),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Payee Input 
                        const Text('PAYING TO',
                            style: TextStyle(
                                color: Colors.grey,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2)),
                        TextField(
                          controller: _payeeController,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1F2937)),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        const Divider(height: 30, thickness: 1),

                        // Amount Input 
                        const Text('TOTAL AMOUNT',
                            style: TextStyle(
                                color: Colors.grey,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2)),
                        const SizedBox(height: 8),
                        IntrinsicWidth(
                          child: TextField(
                            controller: _amountController,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: kPrimaryColor),
                            decoration: const InputDecoration(
                              prefixText: '₹ ',
                              prefixStyle: TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Action Button
                  SizedBox(
                    height: 58,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _initiateTransaction,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryColor,
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shadowColor: kPrimaryColor.withOpacity(0.4),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _loading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2.5))
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.lock_outline, size: 20),
                                SizedBox(width: 8),
                                Text('SECURE PAY',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5)),
                              ],
                            ),
                    ),
                  ),

                  // Status Indicator
                  if (_status != null) ...[
                    const SizedBox(height: 20),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Text(
                          _status!,
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                  ],

                  // Footer Logo/Branding
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shield_outlined,
                          size: 16, color: Colors.grey[400]),
                      const SizedBox(width: 6),
                      Text('Powered by TrustSync',
                          style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                              fontWeight: FontWeight.w500)),
                    ],
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- NEW WIDGET ---
class _FlashCountdownDialog extends StatefulWidget {
  final String amount;
  final String otp;

  const _FlashCountdownDialog({required this.amount, required this.otp});

  @override
  State<_FlashCountdownDialog> createState() => _FlashCountdownDialogState();
}

class _FlashCountdownDialogState extends State<_FlashCountdownDialog> {
  int _timeLeft = 20; // 20 Seconds Timer
  late Stream<int> _timerStream;

  @override
  void initState() {
    super.initState();
    _timerStream =
        Stream.periodic(const Duration(seconds: 1), (i) => 20 - i - 1).take(20);
    _timerStream.listen((timeLeft) {
      if (mounted) {
        setState(() => _timeLeft = timeLeft);
      }
      if (timeLeft == 0) {
        Navigator.pop(context, 'TIMEOUT');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        contentPadding: const EdgeInsets.all(0),
        content: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 1. Header with Timer
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.bolt_rounded,
                            color: Colors.amber, size: 24),
                        SizedBox(width: 8),
                        Text('Quick Verify',
                            style: TextStyle(
                                color: Color(0xFF374151),
                                fontSize: 18,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _timeLeft <= 5
                            ? Colors.red[50]
                            : Colors.blueGrey[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_timeLeft}s',
                        style: TextStyle(
                            color: _timeLeft <= 5
                                ? Colors.red
                                : const Color(0xFF1E3A8A),
                            fontSize: 14,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // 2. Amount Text
                Text('AUTHORIZING',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[400],
                        letterSpacing: 1)),
                const SizedBox(height: 4),
                Text(
                  '₹${widget.amount}',
                  style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E3A8A),
                      letterSpacing: -1),
                ),
                const SizedBox(height: 24),

                // 3. OTP Box 
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: const Color(0xFFE2E8F0),
                        width: 1.5,
                        style: BorderStyle.solid),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'SECURE OTP CODE',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF64748B),
                            letterSpacing: 1),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.otp.split('').join(' '), // Spaced out
                        style: const TextStyle(
                            fontFamily: 'Courier',
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                            color: Color(0xFF0F172A)),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _timeLeft / 20,
                    backgroundColor: Colors.grey[100],
                    color: _timeLeft <= 5
                        ? Colors.red
                        : const Color(0xFF1E3A8A),
                    minHeight: 4,
                  ),
                ),

                const SizedBox(height: 24),

                // 4. Buttons
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context, 'CANCEL'),
                        style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14)),
                        child: Text('DECLINE',
                            style: TextStyle(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, 'APPROVE'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E3A8A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: const Text('APPROVE',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}