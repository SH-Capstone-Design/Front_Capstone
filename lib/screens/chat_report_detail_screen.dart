import 'dart:convert';
import 'package:connectbeat/screens/chat_report_list_screen.dart';
import 'package:connectbeat/screens/chathistory_screen.dart';
import 'package:connectbeat/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:connectbeat/core/constants.dart';
import 'package:connectbeat/services/chat_report_service.dart';
import 'package:connectbeat/services/couple_service.dart';

class ChatReportDetailScreen extends StatefulWidget {
  final String reportId;
  const ChatReportDetailScreen({super.key, required this.reportId});

  @override
  State<ChatReportDetailScreen> createState() => _ChatReportDetailScreenState();
}

class _ChatReportDetailScreenState extends State<ChatReportDetailScreen>
    with TickerProviderStateMixin {
  bool _loading = true;
  Map<String, dynamic>? _report;
  String? _error;

  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();

  String? myUserId;
  String? partnerId;
  String? partnerNickname;

  final List<String> colorsEmotions = [
    "Joy",
    "Love",
    "Sadness",
    "Disappointment",
    "Regret",
    "Anger",
    "Anxiety",
    "Neutral",
  ];

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

  final Map<String, String> emotionMapBack = {
    "Joy": "기쁨",
    "Love": "설렘",
    "Sadness": "슬픔",
    "Disappointment": "실망",
    "Regret": "후회",
    "Anger": "짜증",
    "Anxiety": "불안",
    "Neutral": "중립",
  };

  final List<Color> colors = [
    const Color(0xFFFFFD93),
    const Color(0xFFB9FF93),
    const Color(0xFF8AA2FF),
    const Color(0xFFF8ACDA),
    const Color(0xFFFF8F8F),
    const Color(0xFFFFBE90),
    const Color(0xFFD0A4FD),
    const Color(0xFFAAAAAA),
  ];

  Set<int> selectedIndicesLine = {0};
  Set<int> selectedIndicesBar = {0};
  Map<String, List<FlSpot>> emotionSpots = {};

  final GlobalKey _sectionMinuteAnalysis = GlobalKey();
  final GlobalKey _sectionRadarAnalysis = GlobalKey();
  final GlobalKey _sectionUserCompare = GlobalKey();
  final GlobalKey _sectionGPTFeedback = GlobalKey();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
    _fetchCoupleStatus();
    _fetchReport();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) return;

    final targetKey = [
      _sectionMinuteAnalysis,
      _sectionRadarAnalysis,
      _sectionUserCompare,
      _sectionGPTFeedback
    ][_tabController.index];

    Scrollable.ensureVisible(
      targetKey.currentContext!,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _fetchCoupleStatus() async {
    try {
      // JWT에서 내 userId 가져오기
      final String? myId = await AuthService.getUserId();

      // 커플 상태 API 호출
      final Map<String, dynamic>? coupleStatus = await CoupleService.fetchCoupleStatus();

      setState(() {
        myUserId = myId ?? ""; // JWT에서 못 가져오면 빈 문자열
        partnerId = coupleStatus?['partnerId'] ?? ""; // API에서 못 가져오면 빈 문자열
        partnerNickname = coupleStatus?['partnerNickname'] ?? "";
      });
    } catch (e) {
      debugPrint("❌ _fetchCoupleStatus 에러: $e");

      setState(() {
        myUserId = "";
        partnerId = "";
        partnerNickname = "";
      });
    }
  }

  Future<void> _fetchReport() async {
    setState(() => _loading = true);
    try {
      final report = await ChatReportService.getReportById(widget.reportId);
      if (report == null) {
        setState(() => _error = "리포트를 불러오지 못했습니다.");
        return;
      }

      final aggregatedTimeline = report['aggregatedTimeline'];
      final points = aggregatedTimeline != null &&
          aggregatedTimeline['points'] is List
          ? aggregatedTimeline['points'] as List
          : [];

      if (points.isEmpty) {
        setState(() {
          _error = "분 단위 감정 데이터가 없습니다.";
          _report = report;
        });
        return;
      }

      // -----------------------------
      // ✅ 모든 분에 대해 FlSpot 채우기
      // -----------------------------
      int maxMinute = points.isNotEmpty
          ? points
          .map((p) => (p['minute'] ?? 0) as int)
          .reduce((a, b) => a > b ? a : b)
          : 10;

      Map<int, Map<String, double>> minuteScores = {};
      for (var point in points) {
        final int minute = (point['minute'] ?? 0) as int;
        final avgScoresRaw = point['avgScores'] ?? '{}';
        final Map<String, dynamic> avgScores = avgScoresRaw is String
            ? json.decode(avgScoresRaw)
            : avgScoresRaw as Map<String, dynamic>;

        minuteScores[minute] = {};
        for (var emotion in colorsEmotions) {
          minuteScores[minute]![emotion] =
              (avgScores[emotionMapBack[emotion]] ?? 0.0).toDouble();
        }
      }

      emotionSpots = {};
      for (var emotion in colorsEmotions) {
        emotionSpots[emotion] = [];
        for (int m = 0; m <= maxMinute; m++) {
          final score = minuteScores[m]?[emotion] ?? 0.0;
          emotionSpots[emotion]!.add(FlSpot((m + 1).toDouble(), score)); // 0분 -> 1분
        }
      }

      setState(() {
        _report = report;
      });
    } catch (e) {
      setState(() => _error = "리포트 로드 오류: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        automaticallyImplyLeading: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context); // 이전 화면으로 돌아가기
          },
        ),
        title: const Text(
          "감정 리포트 상세",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            fontFamily: 'GowunBatang',
          ),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.black54,
          indicatorColor: const Color(0xFFFDAAFF),
          indicatorWeight: 3,
          tabs: const [
            Tab(child: FittedBox(fit: BoxFit.scaleDown, child: Text('분당 분석'))),
            Tab(child: FittedBox(fit: BoxFit.scaleDown, child: Text('종합 분석'))),
            Tab(child: FittedBox(fit: BoxFit.scaleDown, child: Text('사용자별 분석'))),
            Tab(child: FittedBox(fit: BoxFit.scaleDown, child: Text('피드백'))),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(AppConstants.backgroundPath),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
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
              : SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildLineChartSection(screenHeight),
                const SizedBox(height: 30),
                _buildBarChartSection(screenHeight),
                const SizedBox(height: 30),
                _buildUserComparisonSection(screenHeight),
                const SizedBox(height: 30),
                _buildFeedbackSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ✅ 사용자별 감정 비교 그래프
  Widget _buildUserComparisonSection(double screenHeight) {
    final userScores =
        _report?['overallScores']?['userAvgScores'] ?? {} as Map<String, dynamic>;

    if (userScores.isEmpty || myUserId == null || partnerId == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16.0),
        child: Text(
          "사용자별 감정 데이터가 없습니다.",
          style: TextStyle(
            fontSize: 14,
            fontFamily: 'GowunBatang',
            color: Colors.black87,
          ),
        ),
      );
    }

    final myScores = userScores["${myUserId}_avg_scores"] ?? {};
    final partnerScores = userScores["${partnerId}_avg_scores"] ?? {};

    return Container(
      key: _sectionUserCompare,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              "사용자별 감정 비교",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'GowunBatang',
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            // 높이 고정 제거하고 내부 Column이 필요한 만큼만 차지하도록
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85),
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min, // 중요: Column이 content만큼만 차지
              children: [
                // 감정별 막대
                ...colorsEmotions.asMap().entries.map((entry) {
                  final index = entry.key;
                  final emotion = entry.value;
                  final myScore = (myScores[emotionMapBack[emotion]] ?? 0.0).toDouble();
                  final partnerScore = (partnerScores[emotionMapBack[emotion]] ?? 0.0).toDouble();

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      children: [
                        // 나
                        Expanded(
                          flex: (myScore * 100).toInt().clamp(1, 100),
                          child: Container(
                            height: 24,
                            decoration: BoxDecoration(
                              color: colors[index % colors.length].withOpacity(0.9), // 위 차트 색상과 통일
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(12),
                                bottomLeft: Radius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        // 감정 이름
                        Container(
                          width: 80,
                          alignment: Alignment.center,
                          child: Text(
                            emotionMap[emotion] ?? emotion,
                            style: const TextStyle(
                              fontSize: 14,
                              fontFamily: 'GowunBatang',
                            ),
                          ),
                        ),
                        // 상대
                        Expanded(
                          flex: (partnerScore * 100).toInt().clamp(1, 100),
                          child: Container(
                            height: 24,
                            decoration: BoxDecoration(
                              color: colors[index % colors.length].withOpacity(0.9), // 연하게 해서 구분
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(12),
                                bottomRight: Radius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),

                const SizedBox(height: 6), // 아래 레이블과 막대 간격
                // 아래 레이블
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        "나",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, fontFamily: 'GowunBatang'),
                      ),
                    ),
                    const SizedBox(width: 80), // 감정 이름 공간
                    Expanded(
                      child: Text(
                        partnerNickname ?? "", // 커플 서비스에서 가져온 닉네임 사용
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'GowunBatang',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackSection() {
    return Container(
      key: _sectionGPTFeedback,
      constraints: const BoxConstraints(minHeight: 400),
      width: double.infinity,
      decoration: BoxDecoration(
        image: const DecorationImage(
            image: AssetImage("assets/images/ConnectBeat_Note.png"), fit: BoxFit.cover),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.fromLTRB(45, 40, 45, 32),
      child: Text(
        _report?['gptFeedback'] ?? '피드백 데이터가 없습니다.',
        style: const TextStyle(
          fontSize: 16,
          height: 1.6,
          fontFamily: 'GowunBatang',
          color: Colors.black87,
        ),
      ),
    );
  }

  DateTime? _lastTapTime;

  Widget _buildLineChartSection(double screenHeight) {
    return Container(
      key: _sectionMinuteAnalysis,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              "분당 감정 분석 결과",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'GowunBatang',
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 4),
          // 안내 문구
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              "그래프를 더블클릭하면 해당 분의 대화를 확인할 수 있습니다.",
              style: TextStyle(
                fontSize: 12,
                fontFamily: 'GowunBatang',
                color: Colors.black54,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            height: screenHeight * 0.3,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 800),
                child: LineChart(
                  key: ValueKey(selectedIndicesLine),
                  LineChartData(
                    minX: 0,
                    maxX: selectedIndicesLine.isNotEmpty
                        ? selectedIndicesLine
                        .map((i) => emotionSpots[colorsEmotions[i]]?.last.x ?? 0)
                        .reduce((a, b) => a > b ? a : b)
                        : 1.0,
                    minY: 0,
                    maxY: 1.0,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 0.2,
                      getDrawingHorizontalLine: (v) =>
                          FlLine(color: Colors.grey.withOpacity(0.2), strokeWidth: 1),
                    ),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
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

                    lineTouchData: LineTouchData(
                    enabled: true,
                    handleBuiltInTouches: true,
                    touchTooltipData: LineTouchTooltipData(
                      tooltipRoundedRadius: 8,
                      tooltipPadding: const EdgeInsets.all(8),
                      tooltipBorder: BorderSide(color: Colors.white),
                      fitInsideHorizontally: true,
                      fitInsideVertically: true,
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          String emotionName = "";
                          for (var i in selectedIndicesLine) {
                            final emotion = colorsEmotions[i];
                            if (emotionSpots[emotion]!.contains(spot)) {
                              emotionName = emotion;
                              break;
                            }
                          }
                          return LineTooltipItem(
                            '${emotionMap[emotionName] ?? emotionName}\n 점수: ${spot.y.toStringAsFixed(2)}',
                            const TextStyle(
                              fontSize: 12,
                              color: Colors.black,
                              fontFamily: 'GowunBatang',
                            ),
                          );
                        }).toList();
                      },
                      getTooltipColor: (touchedSpot) => Colors.white.withOpacity(0.9),
                    ),
                    touchCallback: (FlTouchEvent event, LineTouchResponse? response) {
                      if (event is FlTapUpEvent && response?.lineBarSpots != null) {
                        final tappedSpot = response!.lineBarSpots!.first;
                        final tappedMinute = tappedSpot.x.round();
                        final now = DateTime.now();

                        if (_lastTapTime != null &&
                            now.difference(_lastTapTime!) < const Duration(milliseconds: 300)) {
                          // 더블 탭 감지
                          _lastTapTime = null; // 초기화
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatHistoryScreen(
                                reportId: widget.reportId,
                                minute: tappedMinute,
                              ),
                            ),
                          );
                        } else {
                          // 첫 번째 탭 -> 시간 기록
                          _lastTapTime = now;
                        }
                      }
                    },
                  ),

                    lineBarsData: selectedIndicesLine.map((index) {
                      final emotion = colorsEmotions[index];

                      // ★ 여기서 emotionSpots 데이터를 복제해서 수정 가능하게 만듦
                      List<FlSpot> data = List.from(emotionSpots[emotion] ?? []);

                      // ★★ 바로 여기가 핵심! 0분 기준점 추가
                      if (data.isEmpty || data.first.x != 0) {
                        data.insert(0, FlSpot(0, 0));
                      }

                      final color = colors[index % colors.length].withOpacity(0.9);

                      return LineChartBarData(
                        spots: data,
                        isCurved: true,
                        color: color,
                        barWidth: 3,
                        dotData: FlDotData(show: true),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildEmotionSelector(isLineChart: true),
        ],
      ),
    );
  }


  Widget _buildBarChartSection(double screenHeight) {
    return Container(
      key: _sectionRadarAnalysis,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              "종합 감정 분석 결과",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'GowunBatang',
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            height: screenHeight * 0.3,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 800),
                child: BarChart(
                  key: ValueKey(selectedIndicesBar),
                    BarChartData(
                      maxY: 1.0,
                      barGroups: selectedIndicesBar.map((index) {
                        final emotion = colorsEmotions[index];
                        final score = (_report?['overallScores']?['avgScores']?[emotionMapBack[emotion]] ?? 0.0).toDouble();
                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: score,
                              color: colors[index % colors.length].withOpacity(0.9),
                              width: 22,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ],
                        );
                      }).toList(),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final emotion = colorsEmotions[value.toInt()];
                              return Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  emotionMap[emotion] ?? emotion,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontFamily: 'GowunBatang',
                                      color: Colors.black),
                                ),
                              );
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
                      gridData: FlGridData(
                        show: true,
                        drawHorizontalLine: true, // 가로선 유지
                        drawVerticalLine: false,  // 세로선 제거
                        horizontalInterval: 0.2,  // 눈금 간격
                        getDrawingHorizontalLine: (value) =>
                            FlLine(color: Colors.grey.withOpacity(0.2), strokeWidth: 1),
                      ),
                      barTouchData: BarTouchData(enabled: true),
                    ),
                    swapAnimationDuration: const Duration(milliseconds: 800),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildEmotionSelector(isLineChart: false),
        ],
      ),
    );
  }

  Widget _buildEmotionSelector({required bool isLineChart}) {
    final selectedIndices = isLineChart ? selectedIndicesLine : selectedIndicesBar;

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(14),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    if (selectedIndices.length == colorsEmotions.length) {
                      if (isLineChart) {
                        selectedIndicesLine = {0};
                      } else {
                        selectedIndicesBar = {0};
                      }
                    } else {
                      if (isLineChart) {
                        selectedIndicesLine = Set<int>.from(List.generate(colorsEmotions.length, (i) => i));
                      } else {
                        selectedIndicesBar = Set<int>.from(List.generate(colorsEmotions.length, (i) => i));
                      }
                    }
                  });
                },
                child: Container(
                  width: 70,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selectedIndices.length == colorsEmotions.length
                        ? Colors.grey.withOpacity(0.3)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "전체",
                    style: TextStyle(
                      fontWeight: selectedIndices.length == colorsEmotions.length
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: Colors.black,
                      fontSize: 14,
                      fontFamily: 'GowunBatang',
                    ),
                  ),
                ),
              ),
            ),
            ...List.generate(colorsEmotions.length, (index) {
              final isSelected = selectedIndices.contains(index);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isLineChart) {
                        if (isSelected) {
                          selectedIndicesLine.remove(index);
                          if (selectedIndicesLine.isEmpty) selectedIndicesLine.add(index);
                        } else {
                          selectedIndicesLine.add(index);
                        }
                      } else {
                        if (isSelected) {
                          selectedIndicesBar.remove(index);
                          if (selectedIndicesBar.isEmpty) selectedIndicesBar.add(index);
                        } else {
                          selectedIndicesBar.add(index);
                        }
                      }
                    });
                  },
                  child: Container(
                    width: 70,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected ? colors[index].withOpacity(0.2) : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      emotionMap[colorsEmotions[index]] ?? colorsEmotions[index],
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: Colors.black,
                        fontSize: 14,
                        fontFamily: 'GowunBatang',
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
