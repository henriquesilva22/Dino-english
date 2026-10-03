import 'package:flutter/material.dart';

import '../core/single_navigation_guard.dart';
import '../widgets/home/dino_chat_card.dart';
import '../widgets/home/dino_showcase.dart';
import '../widgets/home/exam_card.dart';
import '../widgets/home/home_top_bar.dart';
import '../widgets/home/pet_adventure_card.dart';
import '../widgets/home/primary_study_button.dart';
import '../widgets/home/sentence_builder_card.dart';
import '../widgets/home/word_slash_card.dart';
import '../widgets/mastery_progress_card.dart';
import '../widgets/neon_background.dart';
import 'dino_chat_screen.dart';
import 'exam_screen.dart';
import 'sentence_builder_screen.dart';
import 'word_slash_game_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NeonBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const HomeTopBar(),
                const SizedBox(height: 260, child: DinoShowcase()),
                const SizedBox(height: 16),
                const PrimaryStudyButton(),
                const SizedBox(height: 14),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 1.3,
                  children: [
                    const PetAdventureCard(),
                    const MasteryProgressCard(),
                    ExamCard(
                      onTap: () => SingleNavigationGuard.run(
                        () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const ExamScreen()),
                        ),
                      ),
                    ),
                    SentenceBuilderCard(
                      onTap: () => SingleNavigationGuard.run(
                        () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const SentenceBuilderScreen(),
                          ),
                        ),
                      ),
                    ),
                    WordSlashCard(
                      onTap: () => SingleNavigationGuard.run(
                        () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const WordSlashGameScreen(),
                          ),
                        ),
                      ),
                    ),
                    DinoChatCard(
                      onTap: () => SingleNavigationGuard.run(
                        () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const DinoChatScreen(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
