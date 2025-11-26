import 'package:flutter/material.dart';
import 'dart:async';
import '../theme/colors.dart';
import '../widgets/gradient_button.dart';

class PanicScreen extends StatefulWidget {
  final VoidCallback onBack;
  
  const PanicScreen({super.key, required this.onBack});

  @override
  State<PanicScreen> createState() => _PanicScreenState();
}

class _PanicScreenState extends State<PanicScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;
  
  int? _countdown;
  bool _isCalling = false;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    
    _glowAnimation = Tween<double>(begin: 0.2, end: 0.6).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startEmergencyCall() {
    setState(() {
      _isCalling = true;
      _countdown = 3;
    });

    const oneSec = Duration(seconds: 1);
    var timer = Timer.periodic(oneSec, (Timer timer) {
      setState(() {
        if (_countdown! > 1) {
          _countdown = _countdown! - 1;
        } else {
          timer.cancel();
          _makeEmergencyCall();
        }
      });
    });
  }

  void _makeEmergencyCall() {
    // In a real app, this would actually call emergency services
    // For demo purposes, we'll just show a dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Emergency Call',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Calling emergency services...\n\nYour location has been shared with emergency responders.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _isCalling = false;
                _countdown = null;
              });
            },
            child: const Text('OK', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Warning pattern background
          _buildWarningBackground(),
          // Pulsing red glow
          _buildPulsingGlow(),
          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Header
                  _buildHeader(),
                  const Spacer(),
                  // Main content
                  _buildMainContent(),
                  const Spacer(),
                  // Emergency actions
                  _buildEmergencyActions(),
                  // Footer
                  _buildFooter(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.black,
            Colors.red.shade900.withOpacity(0.3),
            Colors.black,
          ],
        ),
      ),
      child: Opacity(
        opacity: 0.1,
        child: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/warning_pattern.png'), // You'd need to create this
              repeat: ImageRepeat.repeat,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPulsingGlow() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.0,
              colors: [
                Colors.red.withOpacity(_glowAnimation.value),
                Colors.transparent,
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.red.withOpacity(0.3)),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
            onPressed: widget.onBack,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.withOpacity(0.3)),
          ),
          child: const Row(
            children: [
              Icon(Icons.security, color: Colors.red, size: 16),
              SizedBox(width: 6),
              Text(
                'Emergency Mode',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMainContent() {
    return Column(
      children: [
        // Alert icon with pulse animation
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer glow
                  Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.red, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.5),
                          blurRadius: 30,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                  ),
                  // Inner circle
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.3),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.red, width: 2),
                    ),
                    child: const Icon(
                      Icons.warning,
                      color: Colors.red,
                      size: 60,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 32),
        // Title
        const Text(
          'EMERGENCY',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Help is one tap away',
          style: TextStyle(
            fontSize: 18,
            color: Colors.red,
          ),
        ),
        const SizedBox(height: 32),
        // Countdown
        if (_countdown != null)
          Text(
            '$_countdown',
            style: const TextStyle(
              fontSize: 72,
              fontWeight: FontWeight.bold,
              color: Colors.red,
              fontFamily: 'Monospace',
            ),
          ),
      ],
    );
  }

  Widget _buildEmergencyActions() {
    return Column(
      children: [
        // Emergency call button
        Container(
          width: double.infinity,
          height: 80,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.red, Colors.redAccent],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.5),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
            border: Border.all(color: Colors.redAccent, width: 2),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _isCalling ? null : _startEmergencyCall,
              borderRadius: BorderRadius.circular(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.phone, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    _isCalling ? 'CALLING...' : 'CALL 112 EMERGENCY',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Secondary actions
        Row(
          children: [
            Expanded(
              child: _buildSecondaryAction(
                icon: Icons.location_on,
                text: 'Share Location',
                onTap: () {
                  // Share location logic
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSecondaryAction(
                icon: Icons.people,
                text: 'Alert Friends',
                onTap: () {
                  // Alert friends logic
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        // Warning message
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.withOpacity(0.3)),
          ),
          child: const Text(
            'Press the button above to immediately call emergency services. Your location will be shared automatically with first responders.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.red,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSecondaryAction({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.red, size: 20),
              const SizedBox(width: 8),
              Text(
                text,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.red.withOpacity(0.2)),
        ),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.security, color: Colors.red, size: 16),
          SizedBox(width: 8),
          Text(
            'Your safety is our priority',
            style: TextStyle(
              color: Colors.red,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}