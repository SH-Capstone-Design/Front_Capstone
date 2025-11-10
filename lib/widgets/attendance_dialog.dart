import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/coin_provider.dart';
import '../providers/attendance_provider.dart';
import '../widgets/rounded_button.dart';

class AttendanceDialog extends ConsumerStatefulWidget {
  final int consecutiveDays; // 현재 연속 출석일
  final int newTotalCoinBalance; // 총 코인 보유량

  const AttendanceDialog({
    super.key,
    required this.consecutiveDays,
    required this.newTotalCoinBalance,
  });

  @override
  ConsumerState<AttendanceDialog> createState() => _AttendanceDialogState();
}

class _AttendanceDialogState extends ConsumerState<AttendanceDialog> {
  bool isStampAnimating = false; // GIF 재생 여부
  late int currentDays; // 현재 연속 출석일
  bool hasCheckedInToday = false; // 출석 완료 여부

  // 도장 좌표 비율
  final List<Offset> stampRatios = [
    const Offset(0.176, 0.55), // 1일차
    const Offset(0.27, 0.55), // 2일차
    const Offset(0.37, 0.55), // 3일차
    const Offset(0.468, 0.55), // 4일차
    const Offset(0.225, 0.656), // 5일차
    const Offset(0.327, 0.656), // 6일차
    const Offset(0.429, 0.656), // 7일차
  ];

  @override
  void initState() {
    super.initState();
    currentDays = widget.consecutiveDays;
  }

  Future<void> _onCheckIn() async {
    if (hasCheckedInToday || isStampAnimating) return;

    setState(() => isStampAnimating = true);

    try {
      final attendanceCheck = ref.read(attendanceCheckProvider);
      final result = await attendanceCheck.checkIn();

      if (!result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('출석 실패!')),
        );
        setState(() => isStampAnimating = false);
        return;
      }

      // 코인 업데이트
      final coinNotifier = ref.read(coinProvider.notifier);
      coinNotifier.updateCoin(result['newTotalCoinBalance']);

      // 도장 GIF 2초 재생
      await Future.delayed(const Duration(seconds: 2));

      // GIF 재생 후 도장판 업데이트
      setState(() {
        currentDays = result['consecutiveDays'];
        isStampAnimating = false;
        hasCheckedInToday = true;
      });

      // 이미지 캐시 무효화 후 강제 리빌드
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) setState(() {});
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('출석 완료! +${result['coinGained']} 코인')),
      );
    } catch (e) {
      setState(() => isStampAnimating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('네트워크 오류로 출석 실패')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final width = screenWidth * 1.2;
    final height = width * 0.8;

    // 현재 도장판 이미지 결정 (캐시 무효화를 위해 timestamp 추가)
    final boardImage =
        'assets/images/atd/attendance_${currentDays == 0 ? widget.consecutiveDays : currentDays}.png?${DateTime.now().millisecondsSinceEpoch}';
    final stampGif = 'assets/images/atd/stamp.gif';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              // 출석판 이미지
              Image.asset(
                boardImage,
                width: width,
                height: height,
                fit: BoxFit.contain,
              ),

              // 오늘 출석 스탬프 GIF
              if (isStampAnimating && currentDays < stampRatios.length)
                Positioned(
                  left: width * stampRatios[currentDays].dx,
                  top: height * stampRatios[currentDays].dy,
                  child: Image.asset(
                    stampGif,
                    width: width * 0.1,
                    height: width * 0.1,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          RoundedButton(
            text: hasCheckedInToday ? '닫기' : '출석하기',
            onPressed:
            hasCheckedInToday ? () => Navigator.of(context).pop() : _onCheckIn,
          ),
          const SizedBox(height: 10),
          Text(
            '총 코인: ${widget.newTotalCoinBalance}개',
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
