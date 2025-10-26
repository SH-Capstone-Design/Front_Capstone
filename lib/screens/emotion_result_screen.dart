import 'package:connectbeat/screens/chathistory_screen.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:connectbeat/core/constants.dart';
import 'package:connectbeat/services/chat_report_service.dart';

class EmotionResultScreen extends StatefulWidget {
  final String chatSessionId;
  const EmotionResultScreen({super.key, required this.chatSessionId});

  @override
  State<EmotionResultScreen> createState() => _EmotionResultScreenState();
}

class _EmotionResultScreenState extends State<EmotionResultScreen> {
  bool _loading = true;
  Map<String, dynamic>? _report;
  String? _error;

  /// 🔹 감정 매핑 (영문 → 한글)
  final Map<String, String> emotionMap = {
    "Joy": "기쁨",
    "Love": "설렘",
    "Sadness": "슬픔",
    "Disappointment": "실망",
    "Regret": "후회",
    "Anger": "짜증",
    "Anxiety": "불안",
    "Neutral": "중립",
  };

  final List<String> emotions = [
    "기쁨",
    "설렘",
    "슬픔",
    "실망",
    "후회",
    "짜증",
    "불안",
    "중립",
  ];

  final List<Color> colors = [
    const Color(0xFFFFFC2A), // 기쁨
    const Color(0xFFA6FF76), // 설렘
    const Color(0xFF1F3580), // 슬픔
    const Color(0xFF98FFF0), // 실망
    const Color(0xFFFF6C6C), // 후회
    const Color(0xFFFFA665), // 짜증
    const Color(0xFFB56EFF), // 불안
    const Color(0xFFAAAAAA), // 중립
  ];

  Set<String> _selectedEmotions = {}; // 멀티 선택
  Map<String, List<FlSpot>> emotionSpots = {};

  @override
  void initState() {
    super.initState();
    _fetchReport();
  }

  Future<void> _fetchReport() async {
    setState(() => _loading = true);

    try {
      // ✅ GET 방식 호출: feedback 제거
      final report = await ChatReportService.generateReport(
        widget.chatSessionId,
      );

      if (report == null) {
        setState(() {
          _error = "리포트를 불러오지 못했습니다.";
        });
        return;
      }

      // 🔹 감정 데이터 매핑 및 그래프용 변환
      final timeline = report['aggregatedTimeline'] ?? {};
      final points = (timeline['points'] ?? []) as List;

      // 🔹 minute 기준 오름차순 정렬
      points.sort((a, b) {
        final minA = (a['minute'] ?? 0) as num;
        final minB = (b['minute'] ?? 0) as num;
        return minA.compareTo(minB);
      });

      emotionSpots = {};
      for (var point in points) {
        final minute = (point['minute'] ?? 0).toDouble();
        final avgScores = Map<String, dynamic>.from(point['avgScores'] ?? {});

        avgScores.forEach((engEmotion, score) {
          final krEmotion = emotionMap[engEmotion] ?? engEmotion;
          emotionSpots.putIfAbsent(krEmotion, () => []);
          emotionSpots[krEmotion]!.add(FlSpot(minute, (score as num).toDouble()));
        });
      }

      setState(() {
        _report = report;
        if (_selectedEmotions.isEmpty && emotions.isNotEmpty) {
          _selectedEmotions.add(emotions[0]); // 기본 선택: 기쁨
        }
      });
    } catch (e) {
      setState(() {
        _error = "리포트 로드 오류: $e";
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(AppConstants.backgroundPath),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Colors.black))
                : _error != null
                    ? Center(
                        child: Text(
                          _error!,
                          style: const TextStyle(
                            fontFamily: 'GowunBatang',
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                      )
                    : _buildReportContent(screenHeight),
          ),
        ),
      ),
    );
  }

  Widget _buildReportContent(double screenHeight) {
    final detailedEmotions =
        List<Map<String, dynamic>>.from(_report?['detailedEmotions'] ?? []);

    // 🔹 maxX 계산
    double maxX = emotionSpots.values
        .expand((list) => list)
        .fold<double>(0, (prev, spot) => spot.x > prev ? spot.x : prev);

    // 🔹 bottom interval 계산 (x축 라벨 5~6개 정도)
    double bottomInterval = (maxX / 5).ceilToDouble();
    bottomInterval = bottomInterval > 0 ? bottomInterval : 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 10),
        const Text(
          "감정 분석 리포트",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            fontFamily: 'GowunBatang',
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),

        /// 🔹 감정 그래프
        Container(
          height: screenHeight * 0.35,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.85),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: 1,
                minX: 0,
                maxX: maxX,
                gridData: FlGridData(show: true, drawVerticalLine: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: bottomInterval,
                      getTitlesWidget: (value, meta) => Text(
                        "${value.toInt()}분",
                        style: const TextStyle(
                          fontFamily: 'GowunBatang',
                          color: Colors.black,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 0.2,
                      getTitlesWidget: (value, meta) => Text(
                        value.toStringAsFixed(1),
                        style: const TextStyle(
                          fontFamily: 'GowunBatang',
                          color: Colors.black,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: emotionSpots.entries
                    .where((e) => _selectedEmotions.contains(e.key))
                    .map((e) {
                  final idx = emotions.indexOf(e.key);
                  return LineChartBarData(
                    isCurved: true,
                    barWidth: 2,
                    spots: e.value,
                    color: colors[idx % colors.length],
                    dotData: FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: colors[idx % colors.length].withOpacity(0.1),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),

        const SizedBox(height: 10),

        /// 🔹 감정 선택 버튼
        Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(emotions.length, (index) {
                final emotion = emotions[index];
                final isSelected = _selectedEmotions.contains(emotion);

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedEmotions.remove(emotion);
                      } else {
                        _selectedEmotions.add(emotion);
                      }
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colors[index % colors.length].withOpacity(0.3)
                          : Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      emotion,
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.black : Colors.black87,
                        fontSize: 14,
                        fontFamily: 'GowunBatang',
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),

        const SizedBox(height: 10),

        /// 🔹 피드백
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "감정 분석에 대한 레포트",
                  style: TextStyle(
                    fontFamily: 'GowunBatang',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Text(
                          _report?['gptFeedback'] ?? '피드백 데이터가 없습니다.',
                          style: const TextStyle(
                            fontFamily: 'GowunBatang',
                            fontSize: 16,
                            color: Colors.black87,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 20),
                        // ✅ ChatReportListScreen 이동 버튼
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                '/reportlist',
                                arguments: {'coupleId': _report?['coupleId'] ?? 0},
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text(
                              "대화 리포트 목록으로 가기",
                              style: TextStyle(
                                fontFamily: 'GowunBatang',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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
      ],
    );
  }
}
