import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/coin_provider.dart';
import '../providers/attendance_provider.dart';
import '../widgets/rounded_button.dart';

class AttendanceDialog extends ConsumerStatefulWidget {
  const AttendanceDialog({
    super.key,
    required this.newTotalCoinBalance,
    required this.consecutiveDays,
  });

  final int newTotalCoinBalance;
  final int consecutiveDays;

  @override
  ConsumerState<AttendanceDialog> createState() => _AttendanceDialogState();
}

class _AttendanceDialogState extends ConsumerState<AttendanceDialog> {
  bool isStampAnimating = false;
  bool hasCheckedInToday = false;
  int currentDays = 0;

  final List<Offset> stampRatios = [
    const Offset(0.176, 0.55),
    const Offset(0.27, 0.55),
    const Offset(0.37, 0.55),
    const Offset(0.468, 0.55),
    const Offset(0.225, 0.656),
    const Offset(0.327, 0.656),
    const Offset(0.429, 0.656),
  ];

  @override
  void initState() {
    super.initState();
    currentDays = widget.consecutiveDays;
    _loadStatusFromServer();
  }

  Future<void> _loadStatusFromServer() async {
    final attendance = ref.read(attendanceCheckProvider);
    final result = await attendance.getStatus();

    if (!mounted) return;

    setState(() {
      if (result['success'] == true) {
        currentDays = result['consecutiveDays'] ?? 0;
        hasCheckedInToday = result['todayChecked'] ?? false;
        ref.read(coinProvider.notifier).updateCoin(result['newTotalCoinBalance'] ?? 0);
      } else {
        currentDays = 0;
        hasCheckedInToday = false;
      }
    });
  }

  Future<void> _onCheckIn() async {
    if (hasCheckedInToday || isStampAnimating) return;

    final attendance = ref.read(attendanceCheckProvider);
    final result = await attendance.checkIn();

    if (!mounted) return;

    if (result['success'] == true) {
      setState(() {
        currentDays = (currentDays + 1).clamp(0, 7);
        isStampAnimating = true;
        hasCheckedInToday = true;
      });

      ref.read(coinProvider.notifier).updateCoin(result['newTotalCoinBalance']);

      await Future.delayed(const Duration(seconds: 2));

      if (mounted) setState(() => isStampAnimating = false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? '이미 출석했습니다.')),
      );
      setState(() => hasCheckedInToday = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final width = screenWidth * 1.2;
    final height = width * 0.8;

    final boardImage = 'assets/images/atd/attendance_${currentDays}.png';
    final stampGif = 'assets/images/atd/stamp.gif';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              Image.asset(boardImage, width: width, height: height),
              if (isStampAnimating &&
                  currentDays > 0 &&
                  currentDays - 1 < stampRatios.length)
                Positioned(
                  left: width * stampRatios[currentDays - 1].dx,
                  top: height * stampRatios[currentDays - 1].dy,
                  child: Image.asset(stampGif, width: width * 0.1),
                ),
            ],
          ),
          const SizedBox(height: 16),
          RoundedButton(
            text: hasCheckedInToday ? '닫기' : '출석하기',
            onPressed: hasCheckedInToday
                ? () => Navigator.pop(context)
                : _onCheckIn,
          ),
          const SizedBox(height: 10),
          Consumer(
            builder: (context, ref, _) {
              final coin = ref.watch(coinProvider);
              return Text(
                '총 코인: $coin개',
                style: const TextStyle(color: Colors.white),
              );
            },
          ),
        ],
      ),
    );
  }
}
