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

  @override
  void initState() {
    super.initState();
    _fetchReport();
  }

  /// 🔹 리포트 데이터 불러오기 (AI 감정 분석 완료될 때까지 재시도)
  Future<void> _fetchReport({int retryCount = 0}) async {
    const maxRetries = 12; // 최대 재시도 횟수 (12 * 5초 = 60초)
    const retryDelay = Duration(seconds: 5);

    try {
      debugPrint("📥 리포트 요청 시도 #$retryCount → ${widget.chatSessionId}");
      final report =
      await ChatReportService.fetchReportBySession(widget.chatSessionId);

      // 1️⃣ 404 또는 응답 null → 아직 리포트 생성 안 됨
      if (report == null) {
        if (retryCount < maxRetries) {
          debugPrint("⏳ 리포트 없음 (null) → ${retryDelay.inSeconds}초 후 재시도");
          await Future.delayed(retryDelay);
          return _fetchReport(retryCount: retryCount + 1);
        } else {
          debugPrint("❌ 최대 재시도 횟수 초과 (리포트 생성 안 됨)");
          setState(() {
            _error = "리포트를 불러오지 못했습니다. (생성 지연)";
            _loading = false;
          });
          return;
        }
      }

      // 2️⃣ detailedEmotions가 비어 있으면 분석이 아직 완료되지 않은 상태
      if (report['detailedEmotions'] == null ||
          (report['detailedEmotions'] as List).isEmpty) {
        if (retryCount < maxRetries) {
          debugPrint("⏳ 감정 분석 진행 중... ${retryDelay.inSeconds}초 후 재시도");
          await Future.delayed(retryDelay);
          return _fetchReport(retryCount: retryCount + 1);
        } else {
          debugPrint("⚠️ 분석 결과 없음 (시간 초과)");
          setState(() {
            _error = "감정 분석이 완료되지 않았습니다.";
            _loading = false;
          });
          return;
        }
      }

      // 3️⃣ 모든 조건 통과 → 리포트 데이터 세팅
      setState(() {
        _report = report;
        _loading = false;
      });
      debugPrint("✅ 리포트 로드 완료: ${report['reportId'] ?? 'N/A'}");

    } catch (e, st) {
      debugPrint("🚨 리포트 로드 오류: $e\n$st");
      setState(() {
        _error = "데이터를 불러오지 못했습니다: $e";
        _loading = false;
      });
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
                ? Center(child: Text(_error!, style: const TextStyle(fontFamily: 'GowunBatang')))
                : _buildReportContent(screenHeight),
          ),
        ),
      ),
    );
  }

  Widget _buildReportContent(double screenHeight) {
    final timeline = _report?['aggregatedTimeline'] ?? {};
    final points = (timeline['points'] ?? []) as List;

    /// 🔹 감정별 데이터 점(분 단위)
    final Map<String, List<FlSpot>> emotionSpots = {};
    for (var point in points) {
      final minute = (point['minute'] ?? 0).toDouble();
      final avgScores = Map<String, dynamic>.from(point['avgScores'] ?? {});
      avgScores.forEach((emotion, score) {
        emotionSpots.putIfAbsent(emotion, () => []);
        emotionSpots[emotion]!.add(FlSpot(minute, (score as num).toDouble()));
      });
    }

    /// 🔹 문장별 상세 감정
    final detailedEmotions =
    List<Map<String, dynamic>>.from(_report?['detailedEmotions'] ?? []);

    final colors = [
      Colors.amber,
      Colors.pinkAccent,
      Colors.blueAccent,
      Colors.redAccent,
      Colors.green,
      Colors.purple,
      Colors.orange,
      Colors.teal,
    ];

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

        /// 🔹 감정 추이 그래프
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
                maxY: 8,
                gridData: FlGridData(show: true, drawVerticalLine: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
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
                lineBarsData: emotionSpots.entries.toList().asMap().entries.map(
                      (entry) {
                    final idx = entry.key;
                    final emotion = entry.value.key;
                    final spots = entry.value.value;
                    return LineChartBarData(
                      isCurved: true,
                      barWidth: 2,
                      spots: spots,
                      color: colors[idx % colors.length],
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: colors[idx % colors.length].withOpacity(0.1),
                      ),
                      // 감정 이름 툴팁
                    );
                  },
                ).toList(),
              ),
            ),
          ),
        ),

        const SizedBox(height: 10),

        /// 🔹 문장별 감정 분석 결과 리스트
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85),
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListView.separated(
              itemCount: detailedEmotions.length,
              separatorBuilder: (_, __) => const Divider(height: 8),
              itemBuilder: (context, index) {
                final item = detailedEmotions[index];
                return ListTile(
                  leading: Text(
                    item['speaker'] ?? 'N/A',
                    style: const TextStyle(
                      fontFamily: 'GowunBatang',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  title: Text(
                    item['sentence'] ?? '',
                    style: const TextStyle(fontFamily: 'GowunBatang'),
                  ),
                  subtitle: Text(
                    "${item['topEmotion']} "
                        "(${((item['confidence'] ?? 0) * 100).toStringAsFixed(1)}%)",
                    style: const TextStyle(fontFamily: 'GowunBatang'),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
