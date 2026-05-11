import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'community_view.dart';
import 'settings_view.dart';
import 'test_view.dart';

class MainHeader extends StatelessWidget implements PreferredSizeWidget {
	const MainHeader({super.key});

	@override
	Size get preferredSize => const Size.fromHeight(kToolbarHeight);

	@override
	Widget build(BuildContext context) {
		return AppBar(
			title: const Text(''),
			backgroundColor: const Color.fromARGB(255, 213, 248, 255),
			actions: [
				// Developer-only entry point to the TestScreen cheat panel.
				// Hidden in release builds so it can't be tapped during a demo.
				if (kDebugMode)
					IconButton(
						icon: const Icon(Icons.bug_report),
						tooltip: 'Test Screen',
						onPressed: () {
							Navigator.push(
								context,
								MaterialPageRoute(builder: (context) => TestScreen()),
							);
						},
					),
				IconButton(
					icon: const Icon(Icons.diversity_1),
					tooltip: 'Community',
					onPressed: () {
						Navigator.push(
							context,
							MaterialPageRoute(builder: (context) => CommunityScreen()),
						);
					},
				),
				IconButton(
					icon: const Icon(Icons.settings),
					tooltip: 'Settings',
					onPressed: () {
						Navigator.push(
							context,
							MaterialPageRoute(builder: (context) => SettingsScreen()),
						);
					},
				),
			],
		);
	}
}

