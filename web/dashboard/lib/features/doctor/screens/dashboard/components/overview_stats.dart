import 'dart:async';
import 'package:flutter/material.dart';
import 'package:tbcare_main/core/app_constants.dart';
import 'package:tbcare_main/features/doctor/models/doctor_stats.dart';
import 'package:tbcare_main/features/doctor/services/doctor_service.dart';
import 'file_info_card.dart';

class OverviewStats extends StatefulWidget {
  const OverviewStats({super.key});

  @override
  State<OverviewStats> createState() => _OverviewStatsState();
}

class _OverviewStatsState extends State<OverviewStats> {
  List<DoctorStat> stats = [];
  bool isLoading = true;

  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadStats();
    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      _loadStats(silent: true);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadStats({bool silent = false}) async {
    if (!silent) setState(() => isLoading = true);
    final fetchedStats = await DoctorService.fetchDoctorStats();
    if (mounted) {
      setState(() {
        stats = fetchedStats;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size _size = MediaQuery.of(context).size;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                "Overview",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87, // stays neutral for light bg
                    ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor, // dark teal
                foregroundColor: Colors.white, // contrast text
                padding: const EdgeInsets.symmetric(
                  horizontal: defaultPadding * 1.5,
                  vertical: defaultPadding,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: _loadStats,
              icon: const Icon(Icons.refresh),
              label: const Text("Refresh"),
            ),
          ],
        ),
        const SizedBox(height: defaultPadding),
        if (isLoading)
          const Center(child: CircularProgressIndicator())
        else
          GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: stats.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _size.width < 650 ? 2 : 4,
              crossAxisSpacing: defaultPadding,
              mainAxisSpacing: defaultPadding,
              childAspectRatio: 1.2,
            ),
            itemBuilder: (context, index) => FileInfoCard(info: stats[index]),
          ),
      ],
    );
  }
}
