import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:js' as js;
import '../screens/interestSelection_screen.dart';
import '../controllers/auth_controller.dart';
import '../controllers/interestSelection_controller.dart';
import '../theme/colors.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_button.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onLogin;
  final VoidCallback onRegister;
  final VoidCallback onForgotPassword;

  const LoginScreen({
    super.key,
    required this.onLogin,
    required this.onRegister,
    required this.onForgotPassword,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // ================== CONTROLLERS ==================
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthController _authController = Get.find<AuthController>();

  // ================== STATE ==================
  bool _rememberMe = false;
  bool _isGoogleInitialized = false;

  // ================== INIT ==================
  @override
  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _initializeGoogleGIS();
      _registerGlobalHandler();
      _handleOAuthResponse();
    }
  }

  // 👇 NUEVO MÉTODO para registrar el handler global
  void _registerGlobalHandler() {
    try {
      js.context['handleFlutterGoogleSignIn'] = js.allowInterop((credential) {
        print('🎯 Global handler received credential: [36m${credential.length} chars[0m');
        _handleGISCredential(credential);
      });
      print('✅ Global handler registered successfully');
    } catch (e) {
      print('❌ Error registering global handler: $e');
    }
  }

  // ================== LOGIN ==================
  void _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showErrorDialog(translate('login.validation_error'));
      return;
    }

    print('🔐 Attempting normal login with: ${_emailController.text}');

    final success = await _authController.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (success) {
      widget.onLogin();
    } else {
      _showErrorDialog(_authController.error);
    }
  }

  // ================== GOOGLE LOGIN WEB ==================
  // ================== GOOGLE LOGIN WEB ==================
void _handleGISCredential(String credential) async {
  print('✅ Received Google credential: ${credential.length} characters');
  
  final result = await _authController.googleLoginWeb(credential);
  
  if (result['success'] == true) {
    final isNewUser = result['isNewUser'] ?? false;
    
    if (isNewUser) {
      print('🎯 New user detected, navigating to interests screen');
      
      // AÑADE ESTE DELAY PARA EVITAR CONFLICTOS
      await Future.delayed(Duration(milliseconds: 50));
      
      // NAVEGA USANDO TU SISTEMA DE APP.DART
      Get.offAll(
        GetBuilder<InterestSelectionController>(
          init: InterestSelectionController(),
          builder: (controller) => InterestSelectionScreen(),
        )
      );
      
    } else {
      print('🎯 Existing user, navigating to home');
      widget.onLogin();
    }
  } else {
    _showErrorDialog(_authController.error);
  }
}

  void _initializeGoogleGIS() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isGoogleInitialized) {
        _isGoogleInitialized = true;
        _loadAndInitializeGIS();
      }
    });
  }

  void _loadAndInitializeGIS() {
    try {
      const clientId = '750097459792-9cbl6emgs6j9vbpip10q8ddo1ru3i2s3.apps.googleusercontent.com';

      if (js.context['google'] == null) {
        final script = js.JsObject.fromBrowserObject(
            js.context['document'].callMethod('createElement', ['script']));
        script['src'] = 'https://accounts.google.com/gsi/client';
        script['async'] = true;
        script['defer'] = true;
        script['onload'] = js.allowInterop(() => _initializeGIS(clientId));
        js.context['document']['head'].callMethod('appendChild', [script]);
      } else {
        _initializeGIS(clientId);
      }
    } catch (e) {
      print('❌ Error loading GIS: $e');
    }
  }

  void _initializeGIS(String clientId) {
    try {
      js.context.callMethod('eval', [
        '''
      console.log('🔧 Initializing Google Identity Services with client: $clientId');
      
      if (typeof google !== 'undefined' && google.accounts && google.accounts.id) {
        // Limpiar cualquier inicialización previa
        google.accounts.id.cancel();
        
        google.accounts.id.initialize({
          client_id: "$clientId",
          callback: (response) => {
            console.log('🔐 Google auth response received');
            if (response.credential) {
              console.log('✅ Google token received, length:', response.credential.length);
              if (window.handleFlutterGoogleSignIn) {
                window.handleFlutterGoogleSignIn(response.credential);
                console.log('✅ Token sent to Flutter handler');
              } else {
                console.error('❌ Flutter callback not registered');
              }
            } else {
              console.error('❌ No credential in response');
            }
          },
          auto_select: false,
          cancel_on_tap_outside: true,
          context: 'use',
          ux_mode: 'popup',
          use_fedcm_for_prompt: true,
          itp_support: true
        });
        
        console.log('✅ GIS initialized successfully');
        
        // Intentar one-tap automático
        google.accounts.id.prompt((notification) => {
          console.log('Prompt notification:', notification);
          if (notification.isNotDisplayed() || notification.isSkippedMoment()) {
            console.log('🔧 One Tap not displayed, user can use button');
          }
        });
        
      } else {
        console.error('❌ Google Identity Services not available');
        // Cargar GIS dinámicamente
        const script = document.createElement('script');
        script.src = 'https://accounts.google.com/gsi/client';
        script.async = true;
        script.defer = true;
        script.onload = () => {
          console.log('✅ GIS script loaded dynamically');
          _initializeGIS("$clientId");
        };
        document.head.appendChild(script);
      }
      '''
      ]);
    } catch (e) {
      print('❌ Error initializing GIS: $e');
      // Reintentar después de un delay
      Future.delayed(const Duration(seconds: 2), () {
        _initializeGIS(clientId);
      });
    }
  }

  // ================== ERROR DIALOG ==================
  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        title: Text(
          translate('error.title'),
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          error,
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              translate('common.ok'),
              style: const TextStyle(color: AppColors.neonPink),
            ),
          ),
        ],
      ),
    );
  }

  // ================== BUILD ==================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _buildBackgroundGradients(),
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 60),
              child: Column(
                children: [
                  _buildLogo(),
                  const SizedBox(height: 40),
                  _buildLoginForm(),
                  const SizedBox(height: 20),
                  _buildRegisterPrompt(),
                ],
              ),
            ),
          ),
          if (_authController.isLoading) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  // ================== LOADING ==================
  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black54,
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.neonPink),
        ),
      ),
    );
  }

  // ================== BACKGROUND ==================
  Widget _buildBackgroundGradients() {
    return Stack(
      children: [
        Positioned(
          top: -100,
          right: -100,
          child: Container(
            width: 250,
            height: 250,
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                colors: [AppColors.neonPink, AppColors.neonPurple],
                radius: 1.0,
              ),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          bottom: -100,
          left: -100,
          child: Container(
            width: 250,
            height: 250,
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                colors: [AppColors.neonMagenta, AppColors.primary],
                radius: 1.0,
              ),
              shape: BoxShape.circle,
            ),
          ),
        ),
        _buildNeonParticles(),
      ],
    );
  }

  Widget _buildNeonParticles() {
    final particles = [
      [const Color(0x66FF00FF), 50.0, 100.0],
      [const Color(0x99FF00FF), 150.0, 200.0],
      [const Color(0x4DFF00FF), 300.0, 80.0],
      [const Color(0x80FF00FF), 80.0, 400.0],
      [const Color(0x66FF00FF), 250.0, 350.0],
      [const Color(0x99FF00FF), 320.0, 150.0],
    ];

    return Stack(
      children: particles
          .map((p) => _buildNeonParticle(p[0] as Color, p[1] as double, p[2] as double))
          .toList(),
    );
  }

  Widget _buildNeonParticle(Color color, double left, double top) {
    return Positioned(
      left: left,
      top: top,
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: color, blurRadius: 8, spreadRadius: 2),
          ],
        ),
      ),
    );
  }

  // ================== LOGO ==================
  Widget _buildLogo() {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [AppColors.neonPink, AppColors.neonMagenta, AppColors.primary],
            stops: [0.0, 0.5, 1.0],
          ).createShader(bounds),
          child: Text(
            translate('app.name'),
            style: const TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [
                Shadow(blurRadius: 10, color: AppColors.neonPink),
                Shadow(blurRadius: 20, color: AppColors.neonPink),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          translate('app.slogan'),
          style: const TextStyle(
            color: Color(0xCCFFFFFF),
            fontSize: 16,
            shadows: [Shadow(blurRadius: 5, color: Color(0x80FF00FF))],
          ),
        ),
      ],
    );
  }

  // ================== LOGIN FORM ==================
  Widget _buildLoginForm() {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildEmailField(),
            const SizedBox(height: 16),
            _buildPasswordField(),
            const SizedBox(height: 16),
            _buildRememberForgot(),
            const SizedBox(height: 16),
            GradientButton(onPressed: _login, text: translate('login.login_button')),
            const SizedBox(height: 16),
            kIsWeb ? _buildGoogleWebButton() : _buildGoogleMobileButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailField() {
    return TextField(
      controller: _emailController,
      decoration: InputDecoration(
        labelText: translate('login.email_label'),
        labelStyle: const TextStyle(color: Color(0xB3FFFFFF)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder:
            OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.glassBorder)),
        focusedBorder:
            OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.neonPink)),
        prefixIcon: const Icon(Icons.person, color: Color(0xB3FFFFFF)),
      ),
      style: const TextStyle(color: Colors.white),
    );
  }

  Widget _buildPasswordField() {
    return TextField(
      controller: _passwordController,
      obscureText: true,
      decoration: InputDecoration(
        labelText: translate('login.password_label'),
        labelStyle: const TextStyle(color: Color(0xB3FFFFFF)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder:
            OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.glassBorder)),
        focusedBorder:
            OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.neonPink)),
        prefixIcon: const Icon(Icons.lock, color: Color(0xB3FFFFFF)),
      ),
      style: const TextStyle(color: Colors.white),
    );
  }

  Widget _buildRememberForgot() {
    return Column(
      children: [
        Row(
          children: [
            Theme(
              data: ThemeData(
                checkboxTheme: const CheckboxThemeData(
                  fillColor: MaterialStatePropertyAll(AppColors.neonPink),
                ),
              ),
              child: Checkbox(
                value: _rememberMe,
                onChanged: (value) => setState(() => _rememberMe = value!),
              ),
            ),
            Text(
              translate('login.remember_me'),
              style: const TextStyle(color: Color(0xCCFFFFFF), shadows: [Shadow(blurRadius: 5, color: Color(0x4DFF00FF))]),
            ),
          ],
        ),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: widget.onForgotPassword,
            child: Text(
              translate('login.forgot_password'),
              style: const TextStyle(
                color: AppColors.neonPink,
                fontWeight: FontWeight.w600,
                shadows: [Shadow(blurRadius: 5, color: Color(0x80FF00FF))],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ================== GOOGLE BUTTONS ==================
  Widget _buildGoogleMobileButton() {
    return OutlinedButton(
      onPressed: () async {
        final success = await _authController.googleLogin();
        if (success) {
          widget.onLogin();
        } else {
          _showErrorDialog(_authController.error);
        }
      },
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: AppColors.glassBorder),
        backgroundColor: AppColors.glassWhite,
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/images/google.png', width: 20, height: 20),
          const SizedBox(width: 8),
          Text(
            translate('login.google_login'),
            style: const TextStyle(shadows: [Shadow(blurRadius: 5, color: Color(0x4DFF00FF))]),
          ),
        ],
      ),
    );
  }

  Widget _buildGoogleWebButton() {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.glassBorder),
        color: AppColors.glassWhite,
      ),
      child: InkWell(
        onTap: _showGoogleSignInModal,
        borderRadius: BorderRadius.circular(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/google.png', width: 20, height: 20),
            const SizedBox(width: 8),
            Text(
              translate('login.google_login'),
              style: const TextStyle(
                color: Colors.white,
                shadows: [Shadow(blurRadius: 5, color: Color(0x4DFF00FF))],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showGoogleSignInModal() {
    print('🔄 Showing Google Sign-In modal...');
    try {
      js.context.callMethod('eval', [
        '''
      if (typeof google !== 'undefined' && google.accounts && google.accounts.id) {
        console.log('🎯 Opening Google Sign-In prompt...');
        
        // Usar prompt directo para one-tap
        google.accounts.id.prompt((notification) => {
          console.log('One Tap notification:', notification);
          
          if (notification.isNotDisplayed() || notification.isSkippedMoment()) {
            console.log('🔧 One Tap not shown, showing fallback button');
            
            // Crear contenedor para el botón
            let container = document.getElementById('googleButtonContainer');
            if (!container) {
              container = document.createElement('div');
              container.id = 'googleButtonContainer';
              container.style.position = 'fixed';
              container.style.top = '50%';
              container.style.left = '50%';
              container.style.transform = 'translate(-50%, -50%)';
              container.style.zIndex = '10000';
              document.body.appendChild(container);
            }
            
            // Renderizar botón de Google
            google.accounts.id.renderButton(
              container,
              {
                type: 'standard',
                theme: 'outline',
                size: 'large',
                text: 'signin_with',
                shape: 'rectangular',
                logo_alignment: 'left',
                width: '300'
              }
            );
          }
        });
        
      } else {
        console.error('❌ GIS not available');
      }
      '''
    ]);
    } catch (e) {
      print('❌ Error showing Google modal: $e');
    }
  }

  // ================== REGISTER PROMPT ==================
  Widget _buildRegisterPrompt() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          translate('login.no_account'),
          style: const TextStyle(color: Color(0xCCFFFFFF), shadows: [Shadow(blurRadius: 5, color: Color(0x4DFF00FF))]),
        ),
        GestureDetector(
          onTap: widget.onRegister,
          child: Text(
            translate('login.register_here'),
            style: const TextStyle(
              color: AppColors.neonPink,
              fontWeight: FontWeight.w600,
              shadows: [
                Shadow(blurRadius: 8, color: Color(0x99FF00FF)),
                Shadow(blurRadius: 15, color: Color(0x4DFF00FF)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _handleOAuthResponse() {
    try {
      js.context.callMethod('eval', [
        '''
      // Verificar si hay código de autorización en la URL
      const urlParams = new URLSearchParams(window.location.search);
      const authCode = urlParams.get('code');
      const error = urlParams.get('error');
      
      if (authCode) {
        console.log('✅ OAuth code received:', authCode);
        // Aquí deberías enviar el código a tu backend para intercambiarlo por tokens
        if (window.handleFlutterOAuthCode) {
          window.handleFlutterOAuthCode(authCode);
        }
      } else if (error) {
        console.error('❌ OAuth error:', error);
        if (window.handleFlutterOAuthError) {
          window.handleFlutterOAuthError(error);
        }
      }
      
      // Registrar handler para código OAuth
      window.handleFlutterOAuthCode = function(code) {
        console.log('🔄 OAuth code handler called');
        // Enviar código al backend
      };
      
      window.handleFlutterOAuthError = function(error) {
        console.error('❌ OAuth error handler called:', error);
      };
      '''
      ]);
    } catch (e) {
      print('❌ Error handling OAuth response: $e');
    }
  }
}
