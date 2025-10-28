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

  final List<String> colorsEmotions = [
    "Joy","Love","Sadness","Disappointment","Regret","Anger","Anxiety","Neutral"
  ];

  final List<Color> colors = [
    const Color(0xFFFFFC2A), // Joy
    const Color(0xFFA6FF76), // Love
    const Color(0xFF1F3580), // Sadness
    const Color(0xFF98FFF0), // Disappointment
    const Color(0xFFFF6C6C), // Regret
    const Color(0xFFFFA665), // Anger
    const Color(0xFFB56EFF), // Anxiety
    const Color(0xFFAAAAAA), // Neutral
  ];

  Set<String> _selectedEmotions = {};
  Map<String, List<FlSpot>> emotionSpots = {};

  @override
  void initState() {
    super.initState();
    _fetchReport();
  }

  Future<void> _fetchReport() async {
    setState(() => _loading = true);
    try {
      final report = await ChatReportService.generateReport(widget.chatSessionId);
      if (report == null) {
        setState(() => _error = "리포트를 불러오지 못했습니다.");
        return;
      }

      final points = (report['aggregatedTimeline']?['points'] ?? []) as List;
      if (points.isEmpty) {
        for (int i = 0; i <= 9; i++) {
          points.add({"minute": i,"avgScores": {for (var e in colorsEmotions) e: 0.0}});
        }
      }

      points.sort((a,b) => (a['minute']??0).compareTo(b['minute']??0));

      emotionSpots = {};
      for (var point in points) {
        final minute = (point['minute']??0).toDouble();
        final avgScores = Map<String,dynamic>.from(point['avgScores']??{});
        for (var emotion in colorsEmotions) {
          final score = (avgScores[emotion] ?? 0).toDouble();
          emotionSpots.putIfAbsent(emotion, () => []);
          emotionSpots[emotion]!.add(FlSpot(minute, score));
        }
      }

      setState(() {
        _report = report;
        if (_selectedEmotions.isEmpty && colorsEmotions.isNotEmpty) {
          _selectedEmotions.add(colorsEmotions[0]);
        }
      });
    } catch (e) {
      setState(() => _error = "리포트 로드 오류: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  Widget _buildEmotionButtons() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: colorsEmotions.map((emotion) {
            final isSelected = _selectedEmotions.contains(emotion);
            final colorIdx = colorsEmotions.indexOf(emotion);
            final color = colors[colorIdx % colors.length];

            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) _selectedEmotions.remove(emotion);
                  else _selectedEmotions.add(emotion);
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 6),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? color.withOpacity(0.3) : Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? color : Colors.grey.shade400,
                    width: 1.2,
                  ),
                ),
                child: Text(
                  emotionMap[emotion] ?? emotion,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.black : Colors.black87,
                    fontSize: 14,
                    fontFamily: 'GowunBatang',
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildLineChart() {
    double maxX = emotionSpots.values.expand((list)=>list).fold<double>(0, (prev, spot)=>spot.x>prev?spot.x:prev);
    if (maxX==0) maxX=1;

    return LineChart(
      LineChartData(
        minX:0,
        maxX:maxX,
        minY:0,
        maxY:1,
        gridData: FlGridData(
          show:true,
          drawVerticalLine:true,
          getDrawingHorizontalLine:(v)=>FlLine(color:Colors.grey.withOpacity(0.15), strokeWidth:1),
          getDrawingVerticalLine:(v)=>FlLine(color:Colors.grey.withOpacity(0.15), strokeWidth:1),
        ),
        borderData: FlBorderData(
          show:true,
          border: Border.all(color:Colors.black12,width:1.5),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles:true, interval:1, getTitlesWidget:(value,meta)=>Text("${value.toInt()}분", style:const TextStyle(fontFamily:'GowunBatang', fontSize:10,color:Colors.black87)))),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles:true, interval:0.2, getTitlesWidget:(v,meta)=>Text(v.toStringAsFixed(1), style:const TextStyle(fontFamily:'GowunBatang', fontSize:10,color:Colors.black87)))),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles:false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles:false)),
        ),
        lineBarsData: emotionSpots.entries.where((e)=>_selectedEmotions.contains(e.key)).map((e){
          final idx = colorsEmotions.indexOf(e.key);
          final color = colors[idx % colors.length];
          return LineChartBarData(
            isCurved:true,
            barWidth:3.5,
            isStrokeCapRound:true,
            shadow: Shadow(color:Colors.black.withOpacity(0.25), blurRadius:6, offset:const Offset(2,4)),
            spots:e.value,
            gradient: LinearGradient(colors:[color.withOpacity(0.95), color.withOpacity(0.4)], begin:Alignment.topCenter,end:Alignment.bottomCenter),
            dotData: FlDotData(show:true, getDotPainter:(spot,percent,barData,index)=>FlDotCirclePainter(radius:3.5, color:Colors.white, strokeWidth:2, strokeColor:color.withOpacity(0.9))),
            belowBarData: BarAreaData(show:true, gradient: LinearGradient(begin:Alignment.topCenter,end:Alignment.bottomCenter, colors:[color.withOpacity(0.4), color.withOpacity(0.05)])),
          );
        }).toList(),
      ),
      duration: const Duration(milliseconds:600),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      extendBodyBehindAppBar:true,
      appBar: AppBar(
        title: const Text("감정 분석 리포트", style: TextStyle(fontFamily:'GowunBatang', fontSize:22,fontWeight:FontWeight.bold,color:Colors.black87)),
        backgroundColor:Colors.transparent,
        foregroundColor:Colors.black,
        elevation:0,
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(image: AssetImage(AppConstants.backgroundPath), fit: BoxFit.cover),
        ),
        child: SafeArea(
          child: _loading? const Center(child:CircularProgressIndicator(color:Colors.black))
              : _error!=null? Center(child:Text(_error!, style:const TextStyle(fontFamily:'GowunBatang', fontSize:16,color:Colors.black)))
              : SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal:16,vertical:12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children:[
                // 1. LineChart
                Container(
                  height: screenHeight*0.35,
                  decoration: BoxDecoration(
                    color:Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow:[BoxShadow(color:Colors.black.withOpacity(0.2), blurRadius:12, offset:const Offset(0,6))],
                  ),
                  padding: const EdgeInsets.all(12),
                  child: _buildLineChart(),
                ),
                const SizedBox(height:12),
                // 2. 감정 버튼
                _buildEmotionButtons(),
                const SizedBox(height:16),
                // 3. 방사형 그래프
                Container(
                  height:screenHeight*0.35,
                  decoration: BoxDecoration(
                    color:Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow:[BoxShadow(color:Colors.black.withOpacity(0.2), blurRadius:12, offset:const Offset(0,6))],
                  ),
                  padding: const EdgeInsets.all(12),
                  child: const Center(child:Text("여기에 방사형 그래프 들어감")),
                ),
                const SizedBox(height:20),
                // 4. 피드백 노트
                Container(
                  constraints: const BoxConstraints(minHeight:400),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    image: const DecorationImage(image: AssetImage("assets/images/ConnectBeat_Note.png"), fit: BoxFit.cover),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.fromLTRB(45,40,45,32),
                  child: Text(_report?['gptFeedback'] ?? '피드백 데이터가 없습니다.',
                    style: const TextStyle(fontSize:16, height:1.6, fontFamily:'GowunBatang', color:Colors.black87),
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
