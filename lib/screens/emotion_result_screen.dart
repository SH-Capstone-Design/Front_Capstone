import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:connectbeat/core/constants.dart'; // AppConstants.backgroundPath

// 예시 대화 기록 화면
class ChatHistoryScreen extends StatelessWidget {
  final String emotion;
  final int minute;

  const ChatHistoryScreen({super.key, required this.emotion, required this.minute});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "$emotion 대화 기록",
          style: const TextStyle(fontFamily: 'GowunBatang', color: Colors.black),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Center(
        child: Text(
          "$minute분 시점의 $emotion 감정 대화 기록",
          style: const TextStyle(fontSize: 16, fontFamily: 'GowunBatang', color: Colors.black),
        ),
      ),
    );
  }
}

class EmotionResultScreen extends StatefulWidget {
  const EmotionResultScreen({super.key});

  @override
  State<EmotionResultScreen> createState() => _EmotionResultScreenState();
}

class _EmotionResultScreenState extends State<EmotionResultScreen> {
  final List<String> emotions = ["기쁨", "슬픔", "분노", "불안", "당황", "혐오"];
  final List<Color> colors = [
    const Color(0xFFFBF74D),
    const Color(0xFF84C8FF),
    const Color(0xFFFF8888),
    const Color(0xFF95FF98),
    const Color(0xFFFFCF80),
    const Color(0xFFEC9FFF),
  ];

  int selectedIndex = 0;
  DateTime? _lastTapTime; // 더블탭 감지용

  final Map<String, List<double>> emotionData = {
    "기쁨": [0.0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0],
    "슬픔": [0.1, 0.2, 0.2, 0.3, 0.3, 0.4, 0.5, 0.5, 0.6, 0.7, 0.8],
    "분노": [0.2, 0.3, 0.3, 0.4, 0.5, 0.5, 0.6, 0.7, 0.7, 0.8, 0.9],
    "불안": [0.1, 0.2, 0.2, 0.3, 0.3, 0.4, 0.5, 0.5, 0.6, 0.6, 0.7],
    "당황": [0.0, 0.1, 0.1, 0.2, 0.2, 0.3, 0.3, 0.4, 0.4, 0.5, 0.5],
    "혐오": [0.1, 0.1, 0.2, 0.2, 0.3, 0.3, 0.4, 0.5, 0.5, 0.6, 0.6],
  };

  @override
  Widget build(BuildContext context) {
    String selectedEmotion = emotions[selectedIndex];
    Color selectedColor = colors[selectedIndex];
    List<double> selectedData = emotionData[selectedEmotion]!;

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
            child: Column(
              children: [
                SizedBox(height: screenHeight * 0.01),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    "감정 분석 결과",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      fontFamily: 'GowunBatang',
                    ),
                  ),
                ),

                // 🔹 그래프 영역
                SizedBox(
                  height: screenHeight * 0.3,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 800),
                        child: LineChart(
                          key: ValueKey(selectedIndex),
                          LineChartData(
                            backgroundColor: Colors.transparent,
                            minX: 0,
                            maxX: (selectedData.length - 1).toDouble(),
                            minY: 0,
                            maxY: 1.0,
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              horizontalInterval: 0.2,
                              getDrawingHorizontalLine: (value) => FlLine(
                                  color: Colors.grey.withOpacity(0.3), strokeWidth: 1),
                            ),
                            titlesData: FlTitlesData(
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  interval: 1,
                                  getTitlesWidget: (value, meta) {
                                    if (value >= 0 && value <= 10) {
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 4.0),
                                        child: Text(
                                          "${value.toInt()}분",
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontFamily: 'GowunBatang',
                                            color: Colors.black,
                                          ),
                                        ),
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  },
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  interval: 0.2,
                                  reservedSize: 28,
                                  getTitlesWidget: (value, meta) {
                                    return Text(
                                      value.toStringAsFixed(1),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontFamily: 'GowunBatang',
                                        color: Colors.black,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            ),
                            borderData: FlBorderData(show: false),
                            lineBarsData: [
                              LineChartBarData(
                                spots: List.generate(
                                  selectedData.length,
                                      (index) => FlSpot(index.toDouble(), selectedData[index]),
                                ),
                                isCurved: true,
                                color: selectedColor,
                                barWidth: 3,
                                dotData: FlDotData(show: true),
                              ),
                            ],
                            lineTouchData: LineTouchData(
                              enabled: true,
                              handleBuiltInTouches: true,
                              touchTooltipData: LineTouchTooltipData(
                                // 아예 배경 없앰, 글자만 표시
                                getTooltipItems: (spots) {
                                  return spots.map((spot) {
                                    return LineTooltipItem(
                                      "${spot.x.toInt()}분: ${spot.y.toStringAsFixed(1)}",
                                      const TextStyle(
                                        color: Colors.white,
                                        fontFamily: 'GowunBatang',
                                        fontSize: 14,
                                      ),
                                    );
                                  }).toList();
                                },
                              ),
                              touchCallback: (event, response) {
                                if (response == null || response.lineBarSpots == null) return;
                                if (event is FlTapUpEvent) {
                                  final now = DateTime.now();
                                  if (_lastTapTime == null ||
                                      now.difference(_lastTapTime!) >
                                          const Duration(milliseconds: 300)) {
                                    _lastTapTime = now;
                                  } else {
                                    final spot = response.lineBarSpots!.first;
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ChatHistoryScreen(
                                          emotion: selectedEmotion,
                                          minute: spot.x.toInt(),
                                        ),
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // 🔹 감정 선택 바
                Container(
                  height: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      double buttonWidth = constraints.maxWidth / emotions.length;

                      return Stack(
                        alignment: Alignment.centerLeft,
                        children: [
                          AnimatedPositioned(
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeInOut,
                            left: buttonWidth * selectedIndex + buttonWidth / 2 - 25,
                            top: 5,
                            child: Container(
                              width: 50,
                              height: 40,
                              decoration: BoxDecoration(
                                color: colors[selectedIndex].withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List.generate(emotions.length, (index) {
                              final isSelected = index == selectedIndex;
                              return SizedBox(
                                width: buttonWidth,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      selectedIndex = index;
                                    });
                                  },
                                  child: Center(
                                    child: Text(
                                      emotions[index],
                                      style: TextStyle(
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        color: Colors.black,
                                        fontSize: 16,
                                        fontFamily: 'GowunBatang',
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ],
                      );
                    },
                  ),
                ),

                // 🔹 감정 분석 리포트 공간
                Expanded(
                  child: Center(
                    child: Text(
                      "여기에 감정 분석 리포트가 들어갑니다.",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                        fontFamily: 'GowunBatang',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
