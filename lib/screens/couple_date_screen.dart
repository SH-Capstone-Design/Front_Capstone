import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectbeat/core/constants.dart';
import 'package:connectbeat/widgets/rounded_button.dart';
import '../providers/couple_date_provider.dart';

class CoupleDateScreen extends ConsumerStatefulWidget {
  const CoupleDateScreen({super.key});

  @override
  ConsumerState<CoupleDateScreen> createState() => _CoupleDateScreenState();
}

class _CoupleDateScreenState extends ConsumerState<CoupleDateScreen> {
  late FixedExtentScrollController yearController;
  late FixedExtentScrollController monthController;
  late FixedExtentScrollController dayController;

  late List<int> years;
  final List<int> months = List.generate(12, (index) => index + 1);
  late List<int> days;

  int selectedYearIndex = 0;
  int selectedMonthIndex = 0;
  int selectedDayIndex = 0;

  @override
  void initState() {
    super.initState();
    _initDate();
  }

  void _initDate() {
    final savedDate = ref.read(coupleDateProvider) ?? DateTime.now();
    final currentYear = DateTime.now().year;

    years = List.generate(currentYear - 1900 + 1, (index) => 1900 + index);

    selectedYearIndex = years.indexOf(savedDate.year);
    if (selectedYearIndex == -1) selectedYearIndex = years.length - 1;

    selectedMonthIndex = savedDate.month - 1;

    _updateDays();
    selectedDayIndex = (savedDate.day - 1).clamp(0, days.length - 1);

    yearController = FixedExtentScrollController(initialItem: selectedYearIndex);
    monthController = FixedExtentScrollController(initialItem: selectedMonthIndex);
    dayController = FixedExtentScrollController(initialItem: selectedDayIndex);
  }

  void _updateDays() {
    final year = years[selectedYearIndex];
    final month = months[selectedMonthIndex];
    final lastDay = DateTime(year, month + 1, 0).day;
    days = List.generate(lastDay, (index) => index + 1);

    if (selectedDayIndex >= days.length) {
      selectedDayIndex = days.length - 1;
      dayController.jumpToItem(selectedDayIndex);
    }
  }

  void _onYearChanged(int index) {
    setState(() {
      selectedYearIndex = index;
      _updateDays();
    });
  }

  void _onMonthChanged(int index) {
    setState(() {
      selectedMonthIndex = index;
      _updateDays();
    });
  }

  void _onDayChanged(int index) {
    setState(() {
      selectedDayIndex = index;
    });
  }

  Future<void> _saveDate() async {
    final selectedDate = DateTime(
      years[selectedYearIndex],
      months[selectedMonthIndex],
      days[selectedDayIndex],
    );
    await ref.read(coupleDateProvider.notifier).save(selectedDate);
    Navigator.pop(context);
  }

  Widget _buildPicker(List<int> items, FixedExtentScrollController controller,
      ValueChanged<int> onChanged, String suffix) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: CupertinoPicker(
          scrollController: controller,
          itemExtent: 36,
          backgroundColor: Colors.transparent,
          onSelectedItemChanged: onChanged,
          children: items
              .map(
                (e) => Center(
              child: Text(
                '$e $suffix',
                style: const TextStyle(
                  fontFamily: 'GowunBatang',
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
          )
              .toList(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    yearController.dispose();
    monthController.dispose();
    dayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final horizontalPadding = size.width * 0.06;

    final dDayText = ref.watch(coupleDateProvider.notifier).getDDayText();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '디데이 설정',
          style: TextStyle(
            fontFamily: 'GowunBatang',
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SizedBox.expand(
            child: Image.asset(
              AppConstants.backgroundPath,
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: size.height * 0.15),
                    Text(
                      dDayText,
                      style: const TextStyle(
                        fontFamily: 'GowunBatang',
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                        shadows: [
                          Shadow(
                            blurRadius: 4,
                            color: Colors.black45,
                            offset: Offset(1, 1),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: size.height * 0.03),
                    SizedBox(
                      height: size.height * 0.25,
                      child: Row(
                        children: [
                          _buildPicker(years, yearController, _onYearChanged, '년'),
                          _buildPicker(months, monthController, _onMonthChanged, '월'),
                          _buildPicker(days, dayController, _onDayChanged, '일'),
                        ],
                      ),
                    ),
                    SizedBox(height: size.height * 0.05),
                    RoundedButton(
                      text: '저장',
                      onPressed: _saveDate,
                    ),
                    SizedBox(height: size.height * 0.05),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
