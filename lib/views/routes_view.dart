import 'package:flutter/material.dart';

class RoutesView extends StatefulWidget {
	const RoutesView({super.key});

	@override
	State<RoutesView> createState() => _RoutesViewState();
}

class _RoutesViewState extends State<RoutesView> {
	final List<String> _savedRoutes = [
		'Campus Loop',
		'River Walk',
		'Downtown Dash',
	];

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			backgroundColor: const Color.fromARGB(255, 213, 248, 255),
			body: SafeArea(
				child: Padding(
					padding: const EdgeInsets.all(16),
					child: Column(
						crossAxisAlignment: CrossAxisAlignment.stretch,
						children: [
							SizedBox(
								height: 52,
								child: ElevatedButton(
									style: ElevatedButton.styleFrom(
										backgroundColor: Colors.green,
										foregroundColor: Colors.white,
										shape: RoundedRectangleBorder(
											borderRadius: BorderRadius.circular(12),
										),
									),
									onPressed: () {
										ScaffoldMessenger.of(context).showSnackBar(
											const SnackBar(content: Text('Create Route tapped')),
										);
									},
									child: const Text(
										'Create Route',
										style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
									),
								),
							),
							const SizedBox(height: 16),
							Expanded(
								child: Container(
									padding: const EdgeInsets.all(14),
									decoration: BoxDecoration(
										color: Colors.white,
										borderRadius: BorderRadius.circular(14),
										border: Border.all(color: Colors.green.shade300, width: 1.5),
									),
									child: Column(
										crossAxisAlignment: CrossAxisAlignment.start,
										children: [
											const Text(
												'Saved routes',
												style: TextStyle(
													fontSize: 18,
													fontWeight: FontWeight.bold,
													color: Colors.green,
												),
											),
											const SizedBox(height: 10),
											Expanded(
												child: ListView.separated(
													itemCount: _savedRoutes.length,
													separatorBuilder: (_, __) =>
															const Divider(height: 1, thickness: 1),
													itemBuilder: (context, index) {
														return ListTile(
															contentPadding: const EdgeInsets.symmetric(
																horizontal: 8,
															),
															leading: const Icon(
																Icons.route,
																color: Colors.green,
															),
															title: Text(_savedRoutes[index]),
														);
													},
												),
											),
										],
									),
								),
							),
						],
					),
				),
			),
		);
	}
}

