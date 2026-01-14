import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'Namer App',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
              seedColor: const Color.fromARGB(255, 45, 15, 214)),
        ),
        home: MyHomePage(),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  var current = WordPair.random();
  void getNext() {
    current = WordPair.random();
    notifyListeners();
  }

  var favorites = <WordPair>{};

  void toggleFavorite() {
    if (favorites.contains(current)) {
      favorites.remove(current);
    } else {
      favorites.add(current);
    }
    notifyListeners();
  }
}

class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var selectedIndex = 0;
  @override
  Widget build(BuildContext context) {
    Widget page;
    switch (selectedIndex) {
      case 0:
        page = InteractionPage1();
        break;
      case 1:
        page = FavoritePage(); // Placeholder for another page
        break;
      default:
        throw UnimplementedError('no widget for $selectedIndex');
    }
    return LayoutBuilder(builder: (context, constraints) {
      return Scaffold(
        body: Row(
          children: [
            SafeArea(
              child: NavigationRail(
                extended: constraints.maxWidth >= 600,
                destinations: [
                  NavigationRailDestination(
                    icon: Icon(Icons.home),
                    label: Text('Home'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.favorite),
                    label: Text('Favorites'),
                  ),
                ],
                selectedIndex: selectedIndex,
                onDestinationSelected: (value) {
                  setState(() {
                    selectedIndex = value;
                  });
                },
              ),
            ),
            Expanded(
              child: Container(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: page,
              ),
            ),
          ],
        ),
      );
    });
  }
}

class InteractionPage1 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var pair = appState.current;

    IconData favor = appState.favorites.contains(pair)
        ? Icons.favorite
        : Icons.favorite_border;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          BigCard(pair: pair),
          SizedBox(height: 20),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: appState.getNext,
                child: Text('Next'),
              ),
              SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: appState.toggleFavorite,
                icon: Icon(favor),
                label: Text('Like'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class BigCard extends StatelessWidget {
  const BigCard({
    super.key,
    required this.pair,
  });

  final WordPair pair;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          pair.asLowerCase,
          style: TextStyle(fontSize: 40),
        ),
      ),
    );
  }
}

class FavoritePage extends StatelessWidget {
  FavoritePage({super.key});

  // 你可以按需调一下这个“每行占用高度”和“字号步进”
  static const double _minFontSize = 20.0;
  static const double _fontStep = 10.0;
  static const double _gap = 20.0;
  static const double _rowBaseHeight = 56.0; // 行内容的基础高度（不含间隔）
  static const double _stride = _rowBaseHeight + _gap; // 一行 + 间隔

  final ScrollController _controller = ScrollController();

  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<MyAppState>().favorites.toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportH = constraints.maxHeight;

        // 计算屏幕里大概能显示多少“行”（包含间隔），据此决定中心能长到多大字号
        final visibleCount = (viewportH / _stride).floor().clamp(1, 9999);
        final stepsToCenter = (visibleCount - 1) ~/ 2; // 顶部到中心有多少级
        final maxFontSize = _minFontSize + stepsToCenter * _fontStep;

        return AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final offset = _controller.hasClients ? _controller.offset : 0.0;
            final viewportCenterY = viewportH / 2;

            double fontSizeForIndex(int index) {
              final itemCenterY = index * _stride + _stride / 2 - offset;
              final diffSteps =
                  ((itemCenterY - viewportCenterY) / _stride).round().abs();

              final level = (stepsToCenter - diffSteps).clamp(0, stepsToCenter);
              return _minFontSize + level * _fontStep;
            }

            return ListView.builder(
              controller: _controller,
              itemCount: favorites.length,
              itemBuilder: (context, i) {
                final pair = favorites[i];
                final size = fontSizeForIndex(i);

                return SizedBox(
                  height: _stride,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: _gap),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.favorite),
                          const SizedBox(width: 10),
                          Text(
                            pair.asLowerCase,
                            style: TextStyle(
                              fontSize: size,
                              fontWeight:
                                  size >= maxFontSize ? FontWeight.w700 : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
