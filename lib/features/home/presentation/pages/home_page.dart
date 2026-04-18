import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:smartquizai/core/services/auth_service.dart';
import 'package:smartquizai/core/services/service_locator.dart';
import 'package:smartquizai/core/theme/app_gradients.dart';
import 'package:smartquizai/core/theme/app_palette.dart';
import 'package:smartquizai/core/theme/theme_cubit.dart';
import 'package:smartquizai/shared/widgets/app_card.dart';
import 'package:smartquizai/shared/widgets/app_button.dart';
import 'package:smartquizai/shared/widgets/app_logo.dart';
import 'package:smartquizai/features/group/presentation/pages/group_tests_tab.dart';
import 'package:smartquizai/shared/widgets/gradient_background.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  User? get _user => sl<AuthService>().currentUser;

  void _signOut() async {
    await sl<AuthService>().signOut();
    if (mounted) {
      context.go('/login');
    }
  }

  void _goToHistory() {
    context.go('/history');
  }

  int _selectedIndex = 0;

  void _openQuizSetup(String type) {
    context.go('/quiz-setup?type=$type');
  }

  void _onTabSelected(int index) {
    setState(() => _selectedIndex = index);
  }

  Widget _buildQuizCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String quizType,
  }) {
    return AppCard(
      onTap: () => _openQuizSetup(quizType),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: AppGradients.primary,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppPalette.primaryB.withOpacity(0.22),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Icon(icon, size: 26, color: AppPalette.textPrimary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppPalette.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            'Welcome${_user != null ? ', ${_user!.email?.split('@').first ?? ''}' : ''}',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose a quiz experience and configure your AI session.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppPalette.textSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 20),
          AppButton(
            onPressed: () => _openQuizSetup('text'),
            text: 'Start a Quiz',
            icon: Icons.auto_awesome,
          ),
          const SizedBox(height: 20),
          Text(
            'Categories',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          _buildQuizCard(
            icon: Icons.text_snippet,
            title: 'Text Quiz',
            subtitle: 'Fast knowledge quizzes with smart AI questions.',
            quizType: 'text',
          ),
          _buildQuizCard(
            icon: Icons.image_outlined,
            title: 'Image Quiz',
            subtitle: 'Visual prompts and image-style reasoning practice.',
            quizType: 'image',
          ),
          _buildQuizCard(
            icon: Icons.description_outlined,
            title: 'Document Quiz',
            subtitle:
                'Quizzes inspired by document-based topics and summaries.',
            quizType: 'document',
          ),
          const SizedBox(height: 16),
          AppCard(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Icon(Icons.history, color: AppPalette.textPrimary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Review results',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Open quiz history and see AI explanations.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppPalette.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: _goToHistory,
                  icon: const Icon(Icons.arrow_forward),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: AppPalette.background,
      appBar: AppBar(
        title: Text(_selectedIndex == 0 ? 'SmartQuiz' : 'Group Tests'),
        actions: [
          IconButton(
            onPressed: () => context.read<ThemeCubit>().toggleTheme(),
            icon: Icon(
              Theme.of(context).brightness == Brightness.light
                  ? Icons.dark_mode
                  : Icons.light_mode,
            ),
          ),
          IconButton(onPressed: _goToHistory, icon: const Icon(Icons.history)),
          IconButton(onPressed: _signOut, icon: const Icon(Icons.logout)),
        ],
      ),
      body: _selectedIndex == 0
          ? GradientBackground(
              gradient: AppGradients.deepPurpleToBlue,
              child: SafeArea(child: _buildHomeContent()),
            )
          : const GroupTestsTab(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onTabSelected,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.school),
            label: 'Self Learning',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: 'Group Tests',
          ),
        ],
      ),
    );
  }
}
