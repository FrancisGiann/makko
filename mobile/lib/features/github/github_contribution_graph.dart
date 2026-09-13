import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_theme.dart';

class ContributionDay {
  final String date;
  final int level;
  final int? row;
  final int? col;

  const ContributionDay({
    required this.date,
    required this.level,
    this.row,
    this.col,
  });
}

class GithubContributionsData {
  final int totalContributions;
  final List<ContributionDay> days;
  final Map<String, int> dateToLevel;

  const GithubContributionsData({
    required this.totalContributions,
    required this.days,
    required this.dateToLevel,
  });

  static GithubContributionsData parseHtml(String html) {
    // 1. Total contributions count
    final totalMatch = RegExp(
      r'<h2[^>]*>\s*([\d,]+)\s*contributions',
      caseSensitive: false,
    ).firstMatch(html);
    final total = totalMatch != null
        ? int.tryParse(totalMatch.group(1)!.replaceAll(',', '')) ?? 0
        : 0;

    // 2. Contribution days parsing
    final days = <ContributionDay>[];
    final dateToLevel = <String, int>{};

    final dayTagRegex = RegExp(
      r'<td\b[^>]*class="[^"]*ContributionCalendar-day[^"]*"[^>]*>',
    );
    final tagMatches = dayTagRegex.allMatches(html);

    final dateRegex = RegExp(r'data-date="(\d{4}-\d{2}-\d{2})"');
    final levelRegex = RegExp(r'data-level="(\d+)"');
    final idRegex = RegExp(r'id="contribution-day-component-(\d+)-(\d+)"');

    for (final m in tagMatches) {
      final tag = m.group(0)!;
      final dateStr = dateRegex.firstMatch(tag)?.group(1);
      final levelStr = levelRegex.firstMatch(tag)?.group(1);
      if (dateStr != null && levelStr != null) {
        final level = int.tryParse(levelStr) ?? 0;
        final idMatch = idRegex.firstMatch(tag);
        final row = idMatch != null ? int.tryParse(idMatch.group(1)!) : null;
        final col = idMatch != null ? int.tryParse(idMatch.group(2)!) : null;
        days.add(ContributionDay(
          date: dateStr,
          level: level,
          row: row,
          col: col,
        ));
        dateToLevel[dateStr] = level;
      }
    }

    // Fallback if class regex didn't match
    if (days.isEmpty) {
      final simpleRegex = RegExp(
        r'<td[^>]*data-date="(\d{4}-\d{2}-\d{2})"[^>]*data-level="(\d+)"',
      );
      for (final m in simpleRegex.allMatches(html)) {
        final dateStr = m.group(1)!;
        final level = int.tryParse(m.group(2)!) ?? 0;
        days.add(ContributionDay(date: dateStr, level: level));
        dateToLevel[dateStr] = level;
      }
    }

    return GithubContributionsData(
      totalContributions: total,
      days: days,
      dateToLevel: dateToLevel,
    );
  }
}

class GithubContributionGraph extends StatefulWidget {
  final String? initialUsername;
  final GithubContributionsData? initialData;

  const GithubContributionGraph({
    super.key,
    this.initialUsername,
    this.initialData,
  });

  // Level purple colors exactly as specified
  static const Color level0 = Color(0xFF161B22);
  static const Color level1 = Color(0xFF392A57);
  static const Color level2 = Color(0xFF5A3D8A);
  static const Color level3 = Color(0xFF7D55C4);
  static const Color level4 = Color(0xFFA475F9);

  static const Color darkCardBackground = Color(0xFF0D1117);
  static const Color cardBorderColor = Color(0xFF30363D);
  static const Color purpleAccent = Color(0xFFA475F9);
  static const Color textMuted = Color(0xFF8B949E);

  static Color getLevelColor(int level) => switch (level) {
        1 => level1,
        2 => level2,
        3 => level3,
        4 => level4,
        _ => level0,
      };

  @override
  State<GithubContributionGraph> createState() =>
      _GithubContributionGraphState();
}

class _GithubContributionGraphState extends State<GithubContributionGraph> {
  static const String _prefsKey = 'github_username';

  final _usernameController = TextEditingController();
  String? _username;
  bool _loadingPrefs = true;
  bool _fetching = false;
  String? _error;
  GithubContributionsData? _data;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _data = widget.initialData;
    }
    _loadStoredUsername();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _loadStoredUsername() async {
    if (widget.initialUsername != null && widget.initialUsername!.isNotEmpty) {
      setState(() {
        _username = widget.initialUsername;
        _usernameController.text = widget.initialUsername!;
        _loadingPrefs = false;
      });
      if (_data == null) {
        _fetchContributions(widget.initialUsername!);
      }
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_prefsKey)?.trim();
      if (mounted) {
        setState(() {
          _username = (stored != null && stored.isNotEmpty) ? stored : null;
          if (_username != null) {
            _usernameController.text = _username!;
          }
          _loadingPrefs = false;
        });
        if (_username != null && _data == null) {
          _fetchContributions(_username!);
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loadingPrefs = false);
      }
    }
  }

  Future<void> _saveUsername(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, trimmed);
    } catch (_) {}

    setState(() {
      _username = trimmed;
      _error = null;
    });
    _fetchContributions(trimmed);
  }

  Future<void> _clearUsername() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsKey);
    } catch (_) {}

    setState(() {
      _username = null;
      _data = null;
      _error = null;
      _usernameController.clear();
    });
  }

  Future<void> _fetchContributions(String user) async {
    if (_fetching) return;
    setState(() {
      _fetching = true;
      _error = null;
    });

    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 12);
      final uri = Uri.parse('https://github.com/users/$user/contributions');
      final request = await client.getUrl(uri);
      request.headers.set('User-Agent', 'Makko/1.0 (Mobile Flutter)');
      final response = await request.close();

      if (response.statusCode == 404) {
        throw Exception('User "$user" not found on GitHub.');
      } else if (response.statusCode != 200) {
        throw Exception('GitHub returned status ${response.statusCode}.');
      }

      final html = await response.transform(utf8.decoder).join();
      client.close();

      final parsed = GithubContributionsData.parseHtml(html);
      if (mounted) {
        setState(() {
          _data = parsed;
          _fetching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '').trim();
          _fetching = false;
        });
      }
    }
  }

  void _showChangeUsernameDialog() {
    final controller = TextEditingController(text: _username ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: GithubContributionGraph.darkCardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MakkoShapes.radiusLg),
          side: const BorderSide(
            color: GithubContributionGraph.cardBorderColor,
          ),
        ),
        title: const Text(
          'Change GitHub Username',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'GitHub Username',
            hintText: 'e.g. FrancisGiann',
            prefixIcon: Icon(Icons.alternate_email_rounded, color: GithubContributionGraph.purpleAccent),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          if (_username != null)
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _clearUsername();
              },
              child: const Text('Disconnect', style: TextStyle(color: Colors.redAccent)),
            ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: GithubContributionGraph.level3,
            ),
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                Navigator.of(ctx).pop();
                _saveUsername(newName);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: GithubContributionGraph.darkCardBackground,
        borderRadius: BorderRadius.circular(MakkoShapes.radiusXl),
        border: Border.all(
          color: GithubContributionGraph.cardBorderColor,
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          _buildHeader(),
          const SizedBox(height: 16),

          // Content based on state
          if (_loadingPrefs)
            const SizedBox(
              height: 120,
              child: Center(
                child: CircularProgressIndicator(
                  color: GithubContributionGraph.purpleAccent,
                ),
              ),
            )
          else if (_username == null || _username!.isEmpty)
            _buildUsernameInputView()
          else if (_fetching && _data == null)
            const SizedBox(
              height: 140,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      color: GithubContributionGraph.purpleAccent,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Fetching contribution activity…',
                      style: TextStyle(
                        color: GithubContributionGraph.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (_error != null && _data == null)
            _buildErrorView()
          else if (_data != null)
            _buildGraphView(_data!),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title "G I T H U B"
            const Text(
              'G I T H U B',
              style: TextStyle(
                color: GithubContributionGraph.purpleAccent,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 2.2,
              ),
            ),
            const SizedBox(height: 4),
            // Main title "Activity"
            const Text(
              'Activity',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            // Subtitle "Live contribution graph from @username"
            Text(
              _username != null && _username!.isNotEmpty
                  ? 'Live contribution graph from @$_username'
                  : 'Live contribution graph from GitHub',
              style: const TextStyle(
                color: GithubContributionGraph.textMuted,
                fontSize: 12,
              ),
            ),
          ],
        ),
        if (_username != null && _username!.isNotEmpty)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Refresh contributions',
                icon: _fetching
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: GithubContributionGraph.purpleAccent,
                        ),
                      )
                    : const Icon(
                        Icons.refresh_rounded,
                        color: GithubContributionGraph.textMuted,
                        size: 20,
                      ),
                onPressed: _fetching ? null : () => _fetchContributions(_username!),
              ),
              IconButton(
                tooltip: 'Edit username',
                icon: const Icon(
                  Icons.edit_outlined,
                  color: GithubContributionGraph.textMuted,
                  size: 20,
                ),
                onPressed: _showChangeUsernameDialog,
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildUsernameInputView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Enter your GitHub username to load your activity calendar.',
          style: TextStyle(
            color: GithubContributionGraph.textMuted,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _usernameController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'e.g. FrancisGiann',
                  hintStyle: const TextStyle(
                    color: Color(0xFF484F58),
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(
                    Icons.alternate_email_rounded,
                    color: GithubContributionGraph.purpleAccent,
                    size: 18,
                  ),
                  fillColor: const Color(0xFF161B22),
                  filled: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(MakkoShapes.radius),
                    borderSide: const BorderSide(
                      color: GithubContributionGraph.cardBorderColor,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(MakkoShapes.radius),
                    borderSide: const BorderSide(
                      color: GithubContributionGraph.cardBorderColor,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(MakkoShapes.radius),
                    borderSide: const BorderSide(
                      color: GithubContributionGraph.purpleAccent,
                      width: 1.5,
                    ),
                  ),
                ),
                onSubmitted: _saveUsername,
              ),
            ),
            const SizedBox(width: 10),
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, MakkoShapes.touchTarget),
                backgroundColor: GithubContributionGraph.level3,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(MakkoShapes.radius),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              ),
              onPressed: () => _saveUsername(_usernameController.text),
              child: const Text('Connect', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildErrorView() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1427),
        borderRadius: BorderRadius.circular(MakkoShapes.radius),
        border: Border.all(color: const Color(0xFF4C2A57)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Color(0xFFE28585),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _error ?? 'Unable to fetch GitHub contributions.',
                  style: const TextStyle(color: Color(0xFFF0B2B2), fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, MakkoShapes.touchTarget),
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFF5A3D8A)),
                ),
                onPressed: () => _fetchContributions(_username!),
                child: const Text('Retry'),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: _showChangeUsernameDialog,
                child: const Text(
                  'Change username',
                  style: TextStyle(color: GithubContributionGraph.purpleAccent),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGraphView(GithubContributionsData data) {
    // 53 columns x 7 rows
    // Build 2D matrix: row (0=Sun..6=Sat) x col (0..52)
    final grid = List.generate(
      7,
      (_) => List<ContributionDay?>.filled(53, null),
    );

    for (final day in data.days) {
      if (day.row != null &&
          day.col != null &&
          day.row! >= 0 &&
          day.row! < 7 &&
          day.col! >= 0 &&
          day.col! < 53) {
        grid[day.row!][day.col!] = day;
      }
    }

    // Fallback if row/col weren't populated: derive from date
    if (grid[0][0] == null && data.days.isNotEmpty) {
      try {
        final firstDate = DateTime.parse(data.days.first.date);
        final firstSunday =
            firstDate.subtract(Duration(days: firstDate.weekday % 7));

        for (final day in data.days) {
          final d = DateTime.parse(day.date);
          final diffDays = d.difference(firstSunday).inDays;
          final c = diffDays ~/ 7;
          final r = d.weekday % 7;
          if (c >= 0 && c < 53 && r >= 0 && r < 7) {
            grid[r][c] = day;
          }
        }
      } catch (_) {}
    }

    const double cellSize = 11.0;
    const double cellMargin = 1.5;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Grid scrollable horizontally
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Weekday labels column on the left
              Padding(
                padding: const EdgeInsets.only(top: 18, right: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWeekdayLabel('', cellSize, cellMargin), // Sun
                    _buildWeekdayLabel('Mon', cellSize, cellMargin), // Mon
                    _buildWeekdayLabel('', cellSize, cellMargin), // Tue
                    _buildWeekdayLabel('Wed', cellSize, cellMargin), // Wed
                    _buildWeekdayLabel('', cellSize, cellMargin), // Thu
                    _buildWeekdayLabel('Fri', cellSize, cellMargin), // Fri
                    _buildWeekdayLabel('', cellSize, cellMargin), // Sat
                  ],
                ),
              ),

              // 53 week columns
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(53, (colIndex) {
                  // Check if this column starts a new month or is column 0
                  String monthLabel = '';
                  final sundayDay = grid[0][colIndex];
                  final mondayDay = grid[1][colIndex];
                  final refDay = sundayDay ?? mondayDay;

                  if (refDay != null) {
                    try {
                      final dt = DateTime.parse(refDay.date);
                      if (colIndex == 0 || dt.day <= 7) {
                        monthLabel = DateFormat('MMM').format(dt);
                      }
                    } catch (_) {}
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 0.5),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Month label header
                        SizedBox(
                          height: 18,
                          child: Text(
                            monthLabel,
                            style: const TextStyle(
                              color: GithubContributionGraph.textMuted,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        // 7 days in this week column (Sun=0, Mon=1, ..., Sat=6)
                        ...List.generate(7, (rowIndex) {
                          final cell = grid[rowIndex][colIndex];
                          if (cell == null) {
                            return const SizedBox(
                              width: cellSize + cellMargin * 2,
                              height: cellSize + cellMargin * 2,
                            );
                          }

                          final color =
                              GithubContributionGraph.getLevelColor(cell.level);
                          final tooltip = '${cell.date}: Level ${cell.level}';

                          return Tooltip(
                            message: tooltip,
                            child: Container(
                              width: cellSize,
                              height: cellSize,
                              margin: const EdgeInsets.all(cellMargin),
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(
                                  MakkoShapes.radiusXs,
                                ),
                                border: Border.all(
                                  color: const Color(0xFF272A30),
                                  width: 0.5,
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Footer: Total contributions on left, Level color legend on right
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${data.totalContributions} contributions in the last year',
              style: const TextStyle(
                color: GithubContributionGraph.textMuted,
                fontSize: 11,
              ),
            ),
            Row(
              children: [
                const Text(
                  'Less',
                  style: TextStyle(
                    color: GithubContributionGraph.textMuted,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(width: 4),
                for (var lvl = 0; lvl <= 4; lvl++)
                  Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.symmetric(horizontal: 1.5),
                    decoration: BoxDecoration(
                      color: GithubContributionGraph.getLevelColor(lvl),
                      borderRadius: BorderRadius.circular(MakkoShapes.radiusXs),
                      border: Border.all(
                        color: const Color(0xFF272A30),
                        width: 0.5,
                      ),
                    ),
                  ),
                const SizedBox(width: 4),
                const Text(
                  'More',
                  style: TextStyle(
                    color: GithubContributionGraph.textMuted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWeekdayLabel(String text, double size, double margin) {
    return SizedBox(
      height: size + margin * 2,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: const TextStyle(
            color: GithubContributionGraph.textMuted,
            fontSize: 9,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
