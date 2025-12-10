import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'transaction_screen.dart';
import 'inbox_screen.dart'; 

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 30),
              const Icon(Icons.shield_moon, size: 64, color: Color(0xFF1E3A8A)),
              const SizedBox(height: 16),
              const Text(
                "TrustSync",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A8A),
                ),
              ),
              const Text(
                "Context & Identity Engine",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              
              const Spacer(),
              const Text(
                "SELECT SCENARIO",
                style: TextStyle(
                  fontSize: 12, 
                  fontWeight: FontWeight.bold, 
                  color: Colors.grey, 
                  letterSpacing: 1.5
                ),
              ),
              const SizedBox(height: 16),

              // Option 1: Login Flow
              _buildOptionCard(
                context,
                title: "Login & Device Binding",
                subtitle: "Test New vs Known Device logic.",
                icon: Icons.login,
                color: Colors.blue.shade50,
                onTap: () => Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (_) => const LoginScreen())
                ),
              ),

              const SizedBox(height: 16),

              // Option 2: Transaction Flow
              _buildOptionCard(
                context,
                title: "Transaction Routing",
                subtitle: "Test Push/WA/SMS fallbacks.",
                icon: Icons.payment,
                color: Colors.green.shade50,
                onTap: () => Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (_) => const TransactionScreen())
                ),
              ),

              const SizedBox(height: 16),

              // Option 3: Secure Inbox 
              _buildOptionCard(
                context,
                title: "Secure Inbox",
                subtitle: "Verify messages (Mirror Box Protocol).",
                icon: Icons.mark_email_read, 
                color: Colors.purple.shade50,
                onTap: () => Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (_) => const InboxScreen())
                ),
              ),

              const Spacer(),
              const Center(
                child: Text(
                  "v2.1 • HDFC Bank",
                  style: TextStyle(color: Colors.grey, fontSize: 10),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard(BuildContext context, {
    required String title, 
    required String subtitle, 
    required IconData icon, 
    required Color color, 
    required VoidCallback onTap
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color, 
          borderRadius: BorderRadius.circular(16), 
          border: Border.all(color: Colors.black.withOpacity(0.05))
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white, 
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
                ]
              ),
              child: Icon(icon, color: const Color(0xFF1E3A8A), size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, 
                children: [
                  Text(
                    title, 
                    style: const TextStyle(
                      fontSize: 16, 
                      fontWeight: FontWeight.bold, 
                      color: Color(0xFF1E3A8A)
                    )
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle, 
                    style: const TextStyle(fontSize: 12, color: Colors.black54)
                  ),
                ]
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}