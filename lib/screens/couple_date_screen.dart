import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:connectbeat/core/constants.dart';
import 'package:connectbeat/widgets/rounded_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CoupleDateInputScreen extends StatefulWidget {
  const CoupleDateInputScreen({super.key});

  @override
  State<CoupleDateInputScreen> createState() => _CoupleDateInputScreenState();
}

class _CoupleDateInputScreenState extends State<CoupleDateInputScreen> {
  FixedExtentScrollController? yearController;
  FixedExtentScrollController? monthController;
  FixedExtentScrollController? dayController;

  late List<int> years;
  late List<int> months;
  late List<int> days;

  int selectedYearIndex = 0;
  int selectedMonthIndex = 0;
  int selectedDayIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadSavedDate();
  }

  Future<void> _loadSavedDate() async {
    final prefs = await SharedPreferences.getInstance();
    final dateStr = prefs.getString('coupleDate');

    DateTime now = DateTime.now();
    DateTime selectedDate;

    if (dateStr != null) {
      try {
        selectedDate = DateTime.parse(dateStr);
      } catch (e) {
        selectedDate = now;
      }
    } else {
      selectedDate = now;
    }

    final currentYear = now.year;
    years = List.generate(currentYear - 1900 + 1, (index) => 1900 + index);
    months = List.generate(12, (index) => index + 1);

    selectedYearIndex = years.indexOf(selectedDate.year);
    if (selectedYearIndex == -1) selectedYearIndex = years.length - 1;

    selectedMonthIndex = selectedDate.month - 1;

    _updateDays();
    selectedDayIndex = (selectedDate.day - 1).clamp(0, days.length - 1);

    yearController?.dispose();
    monthController?.dispose();
    dayController?.dispose();

    yearController = FixedExtentScrollController(initialItem: selectedYearIndex);
    monthController = FixedExtentScrollController(initialItem: selectedMonthIndex);
    dayController = FixedExtentScrollController(initialItem: selectedDayIndex);

    setState(() {});
  }

  void _updateDays() {
    int year = years[selectedYearIndex];
    int month = months[selectedMonthIndex];
    int lastDay = DateTime(year, month + 1, 0).day;
    days = List.generate(lastDay, (index) => index + 1);

    if (selectedDayIndex >= days.length) {
      selectedDayIndex = days.length - 1;
      dayController?.jumpToItem(selectedDayIndex);
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

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('coupleDate', selectedDate.toIso8601String());

    Navigator.pop(context, selectedDate);
  }

  Widget _buildPicker(List<int> items, FixedExtentScrollController? controller,
      ValueChanged<int> onSelectedItemChanged, String suffix) {
    return Expanded(
      child: CupertinoPicker(
        scrollController: controller,
        itemExtent: 32,
        backgroundColor: Colors.white.withOpacity(0.8),
        onSelectedItemChanged: onSelectedItemChanged,
        children: items
            .map((e) => Center(
          child: Text(
            '$e $suffix',
            style: const TextStyle(color: Colors.black87),
          ),
        ))
            .toList(),
      ),
    );
  }

  @override
  void dispose() {
    yearController?.dispose();
    monthController?.dispose();
    dayController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final paddingHorizontal = size.width * 0.06;
    final topPadding = size.height * 0.02;
    final spacingLarge = size.height * 0.05;
    final spacingMedium = size.height * 0.03;

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
            padding: EdgeInsets.symmetric(
              horizontal: paddingHorizontal,
              vertical: topPadding,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: size.height * 0.15,
                  child: Image.asset(
                    AppConstants.logoPath,
                    fit: BoxFit.contain,
                  ),
                ),
                SizedBox(height: spacingLarge),
                const Text(
                  '사귄 날짜를 선택해주세요',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
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
                SizedBox(height: spacingMedium),
                SizedBox(
                  height: size.height * 0.22,
                  child: Row(
                    children: [
                      _buildPicker(years, yearController, _onYearChanged, '년'),
                      _buildPicker(months, monthController, _onMonthChanged, '월'),
                      _buildPicker(days, dayController, _onDayChanged, '일'),
                    ],
                  ),
                ),
                SizedBox(height: spacingLarge),
                RoundedButton(
                  text: '저장',
                  onPressed: _saveDate,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
