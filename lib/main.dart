import 'package:flutter/material.dart';

void main() {
  runApp(const FootballSquaresApp());
}

class FootballSquaresApp extends StatelessWidget {
  const FootballSquaresApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Must be a String (this is NOT the AppBar text)
      title: 'Football Squares',
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

  // 10x10 claimed state
  final List<List<bool>> claimed =
      List.generate(gridSize, (_) => List.generate(gridSize, (_) => false));

  // Header numbers (blank until generated)
  List<int>? colHeaders; // top row (10 numbers)
  List<int>? rowHeaders; // left column (10 numbers)

  void _toggleClaim(int row, int col) {
  // Lock the board once numbers are generated
  if (colHeaders != null || rowHeaders != null) return;

  setState(() {
    claimed[row][col] = !claimed[row][col];
  });
}


  bool _allClaimed() {
    for (final row in claimed) {
      for (final v in row) {
        if (!v) return false;
      }
    }
    return true;
  }

  void _generateHeaders() {
    if (!_allClaimed()) return;

    final cols = List<int>.generate(10, (i) => i)..shuffle();
    final rows = List<int>.generate(10, (i) => i)..shuffle();

    setState(() {
      colHeaders = cols;
      rowHeaders = rows;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 11x11: [0,0] is the blank corner, top row is column headers,
    // left column is row headers, and the 10x10 claimable squares are the rest.
    return Scaffold(
      appBar: AppBar(
        title: const Text('Football Squares'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Reserve space for the button + spacing so the grid doesn't overflow.
const double controlsHeight = 70; // button + gap (tweak if needed)

final double usableHeight =
    (constraints.maxHeight - controlsHeight).clamp(0, constraints.maxHeight);

final double side =
    (constraints.maxWidth < usableHeight ? constraints.maxWidth : usableHeight);

final double cellSize = side / (gridSize + 1);


            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: cellSize * (gridSize + 1),
                    height: cellSize * (gridSize + 1),
                    child: Column(
                      children: List.generate(gridSize + 1, (r) {
                        return Row(
                          children: List.generate(gridSize + 1, (c) {
                            // Top-left corner (blank)
                            if (r == 0 && c == 0) {
                              return _HeaderCell(size: cellSize, label: '');
                            }

                            // Top header row (blank until generated)
                            if (r == 0 && c > 0) {
                              final label = (colHeaders == null)
                                  ? ''
                                  : '${colHeaders![c - 1]}';
                              return _HeaderCell(size: cellSize, label: label);
                            }

                            // Left header column (blank until generated)
                            if (c == 0 && r > 0) {
                              final label = (rowHeaders == null)
                                  ? ''
                                  : '${rowHeaders![r - 1]}';
                              return _HeaderCell(size: cellSize, label: label);
                            }

                            // Claimable cell (10x10 area)
                            final int row = r - 1;
                            final int col = c - 1;
                            final bool isClaimed = claimed[row][col];

                            return GestureDetector(
                              onTap: () => _toggleClaim(row, col),
                              child: _SquareCell(
                                size: cellSize,
                                row: row,
                                col: col,
                                label: '',
                                isClaimed: isClaimed,
                              ),
                            );
                          }),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _allClaimed() ? _generateHeaders : null,
                    child: Text(
                      _allClaimed()
                          ? 'Generate Numbers'
                          : 'Claim all squares to generate',
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final double size;
  final String label;

  const _HeaderCell({required this.size, required this.label});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black26),
          color: Colors.black12,
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}

class _SquareCell extends StatelessWidget {
  final double size;
  final int row;
  final int col;
  final String label;
  final bool isClaimed;

  const _SquareCell({
    required this.size,
    required this.row,
    required this.col,
    required this.label,
    required this.isClaimed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black26),
          color: isClaimed ? Colors.black12 : Colors.white,
        ),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ),
    );
  }
}
