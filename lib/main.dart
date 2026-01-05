import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(const FootballSquaresApp());
}

class FootballSquaresApp extends StatelessWidget {
  const FootballSquaresApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Football Squares',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const BoardScreen(),
    );
  }
}

class BoardScreen extends StatefulWidget {
  const BoardScreen({super.key});

  @override
  State<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends State<BoardScreen> {
  static const int gridSize = 10;

  /// When these are non-null, numbers are "generated" and claiming is locked.
  List<int>? colHeaders; // 10 across the top
  List<int>? rowHeaders; // 10 down the left

  // 10x10 claimed state
  final List<List<bool>> claimed =
      List.generate(gridSize, (_) => List.generate(gridSize, (_) => false));

  // 10x10 claimed names (empty string = unclaimed)
  final List<List<String>> names =
      List.generate(gridSize, (_) => List.generate(gridSize, (_) => ''));

  bool get _locked => (colHeaders != null || rowHeaders != null);

  bool _allClaimed() {
    for (final row in claimed) {
      for (final cell in row) {
        if (!cell) return false;
      }
    }
    return true;
  }

  List<int> _shuffledDigits() {
    final digits = List<int>.generate(10, (i) => i);
    digits.shuffle(Random());
    return digits;
  }

  void _generateNumbers() {
    if (!_allClaimed()) return;

    setState(() {
      colHeaders = _shuffledDigits();
      rowHeaders = _shuffledDigits();
    });
  }

  void _resetBoard() {
    setState(() {
      colHeaders = null;
      rowHeaders = null;

      for (int r = 0; r < gridSize; r++) {
        for (int c = 0; c < gridSize; c++) {
          claimed[r][c] = false;
          names[r][c] = '';
        }
      }
    });
  }

  String _formatNameForCell(String raw) {
    final parts = raw.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts[0];
    return '${parts.first}\n${parts.sublist(1).join(' ')}';
  }

  Future<void> _toggleClaim(int row, int col) async {
    // Lock the board once numbers are generated
    if (_locked) return;

    // Tap again to unclaim (clears name)
    if (claimed[row][col]) {
      setState(() {
        claimed[row][col] = false;
        names[row][col] = '';
      });
      return;
    }

    final controller = TextEditingController();

    final String? enteredName = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Claim square'),
          content: TextField(
            controller: controller,
            autofocus: true,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'Name',
              hintText: 'First Last',
            ),
            onSubmitted: (_) =>
                Navigator.of(context).pop(controller.text.trim()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(context).pop(controller.text.trim()),
              child: const Text('Claim'),
            ),
          ],
        );
      },
    );

    final name = (enteredName ?? '').trim();
    if (name.isEmpty) return;

    setState(() {
      claimed[row][col] = true;
      names[row][col] = name;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool canGenerate = _allClaimed() && !_locked;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Football Squares'),
        actions: [
          IconButton(
            tooltip: 'Reset',
            onPressed: _resetBoard,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Controls / status (this area can take some height)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FilledButton(
                    onPressed: canGenerate ? _generateNumbers : null,
                    child: const Text('Generate Numbers'),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      _locked
                          ? 'Locked (numbers generated)'
                          : (_allClaimed()
                              ? 'All claimed — ready to generate'
                              : 'Claim all squares to unlock'),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // Grid area (Expanded prevents bottom overflow)
            Expanded(
              child: Center(
                child: LayoutBuilder(
                  builder: (context, gridConstraints) {
                    // Make the grid fit inside the available expanded area
                    final side =
                        min(gridConstraints.maxWidth, gridConstraints.maxHeight);
                    final cellSize = side / (gridSize + 1);

                    return SizedBox(
                      width: cellSize * (gridSize + 1),
                      height: cellSize * (gridSize + 1),
                      child: Column(
                        children: List.generate(gridSize + 1, (r) {
                          return Row(
                            children: List.generate(gridSize + 1, (c) {
                              // Top-left blank
                              if (r == 0 && c == 0) {
                                return _headerCell(
                                  size: cellSize,
                                  child: const SizedBox.shrink(),
                                );
                              }

                              // Top headers (columns)
                              if (r == 0 && c > 0) {
                                final idx = c - 1;
                                final text = colHeaders == null
                                    ? ''
                                    : '${colHeaders![idx]}';
                                return _headerCell(
                                  size: cellSize,
                                  child: Text(
                                    text,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                );
                              }

                              // Left headers (rows)
                              if (c == 0 && r > 0) {
                                final idx = r - 1;
                                final text = rowHeaders == null
                                    ? ''
                                    : '${rowHeaders![idx]}';
                                return _headerCell(
                                  size: cellSize,
                                  child: Text(
                                    text,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                );
                              }

                              // Claimable squares
                              final row = r - 1;
                              final col = c - 1;
                              final isClaimed = claimed[row][col];
                              final displayName =
                                  isClaimed ? _formatNameForCell(names[row][col]) : '';

                              return GestureDetector(
                                onTap: () => _toggleClaim(row, col),
                                child: Container(
                                  width: cellSize,
                                  height: cellSize,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                        color: Theme.of(context).dividerColor),
                                    color: isClaimed
                                        ? Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withOpacity(0.15)
                                        : null,
                                  ),
                                  padding: const EdgeInsets.all(4),
                                  child: Center(
  child: FittedBox(
    fit: BoxFit.scaleDown,
    child: Text(
      displayName,
      textAlign: TextAlign.center,
      softWrap: false, // IMPORTANT: prevents breaking "Jeremy" into "Jere/my"
      maxLines: 2,
      style: TextStyle(
        fontSize: 14, // base size; FittedBox will shrink if needed
        height: 1.05,
        fontWeight: isClaimed ? FontWeight.w600 : FontWeight.normal,
      ),
    ),
  ),
),

                                ),
                              );
                            }),
                          );
                        }),
                      ),
                    );
                  },
                ),
              ),
            ),

            // Footer note (small)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Text(
                _locked
                    ? 'Reset to unlock claiming again.'
                    : 'Tap a square to claim it with a name. Tap again to unclaim.',
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerCell({required double size, required Widget child}) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: child,
    );
  }
}
