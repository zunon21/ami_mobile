import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _pages = [
    {
      'title': 'Semer la graine du salut dans les nations',
      'description':
          'L’Action Missionnaire Interafricaine (AMI) se consacre à porter la lumière de l’Évangile là où elle n’a pas encore été annoncée. En devenant partenaire, vous participez activement à transformer des vies et à ouvrir le chemin du salut à des multitudes.',
      'image': 'assets/images/onboarding1.jpg',
    },
    {
      'title': 'Orientez votre générosité avec impact',
      'description':
          'Soutenez des projets missionnaires, accompagnez un missionnaire sur le terrain, financez un champ missionnaire ou contribuez à une zone spécifique. Selon la conviction que Dieu met dans votre cœur, choisissez où votre don agit pour l’éternité.',
      'image': 'assets/images/onboarding2.jpg',
    },
    {
      'title': 'Votre engagement fait la différence',
      'description':
          'Chaque engagement compte. Rejoignez la grande famille des partenaires de l’AMI Côte d’Ivoire. Que ce soit par un soutien mensuel ou un don ponctuel, votre participation devient un instrument puissant entre les mains de Dieu. Ensemble, faisons avancer l’œuvre et impactons les nations.',
      'image': 'assets/images/onboarding3.jpg',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              const Color(0xFFFFF5E6),
              const Color(0xFFFCE4B2),
            ],
            stops: const [0.0, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (int page) {
                    setState(() {
                      _currentPage = page;
                    });
                  },
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    final page = _pages[index];
                    final isActive = _currentPage == index;
                    return AnimatedOpacity(
                      duration: const Duration(milliseconds: 600),
                      opacity: isActive ? 1.0 : 0.4,
                      child: Transform.scale(
                        scale: isActive ? 1.0 : 0.95,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 280,
                                height: 280,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(32),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.15),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                  image: DecorationImage(
                                    image: AssetImage(page['image'] as String),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 48),
                              Text(
                                page['title'] as String,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF3E2723),
                                  letterSpacing: 0.5,
                                  shadows: [
                                    Shadow(blurRadius: 2, color: Colors.black12, offset: Offset(0, 1)),
                                  ],
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 20),
                              Text(
                                page['description'] as String,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF5D4037),
                                  height: 1.4,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pages.length, (index) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    width: _currentPage == index ? 28 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      gradient: _currentPage == index
                          ? const LinearGradient(
                              colors: [Color(0xFFD4A017), Color(0xFFF57C00)],
                            )
                          : const LinearGradient(
                              colors: [Colors.grey, Colors.grey],
                            ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(40),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFD4A017), Color(0xFFF57C00)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD4A017).withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () async {
                      if (_currentPage == _pages.length - 1) {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool('onboarding_completed', true);
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => LoginScreen()),
                        );
                      } else {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: const Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(40),
                      ),
                    ),
                    child: Text(
                      _currentPage == _pages.length - 1 ? 'COMMENCER' : 'CONTINUER',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}