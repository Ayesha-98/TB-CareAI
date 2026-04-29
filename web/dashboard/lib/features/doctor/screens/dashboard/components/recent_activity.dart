import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:tbcare_main/core/app_constants.dart';
import 'package:tbcare_main/features/doctor/models/recent_cases.dart';
import 'package:tbcare_main/features/doctor/services/recent_cases_service.dart';

class RecentActivity extends StatefulWidget {
  const RecentActivity({super.key});

  @override
  State<RecentActivity> createState() => _RecentActivityState();
}

class _RecentActivityState extends State<RecentActivity> {
  List<RecentCase> _recentCases = [];
  bool _isLoading = true;
  String? _error;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _fetchRecentCases();
    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      _fetchRecentCases(silent: true);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchRecentCases({bool silent = false}) async {
    try {
      if (!silent) setState(() => _isLoading = true);
      final cases = await RecentCasesService.fetchRecentCases(limit: 5);
      if (mounted) {
        setState(() {
          _recentCases = cases;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(defaultPadding),
      decoration: BoxDecoration(
        color: Colors.white, // light card for dashboard
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Recent Activity",
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: defaultPadding / 2),

          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                "Error: $_error",
                style: const TextStyle(color: Colors.redAccent),
              ),
            )
          else if (_recentCases.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                "No recent activity found.",
                style: TextStyle(color: Colors.black54),
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: DataTable(
                columnSpacing: defaultPadding,
                horizontalMargin: 0,
                headingRowColor:
                    WidgetStateProperty.all(primaryColor.withOpacity(0.1)),
                columns: const [
                  DataColumn(label: Text("  Patient")),
                  DataColumn(label: Text("Diagnosis")),
                  DataColumn(label: Text("Date")),
                ],
                rows: List.generate(
                  _recentCases.length,
                  (index) => _recentCasesRow(_recentCases[index]),
                ),
              ),
            ),
        ],
      ),
    );
  }

  DataRow _recentCasesRow(RecentCase caseData) {
    return DataRow(
      cells: [
        DataCell(
          Row(
            children: [
              SvgPicture.asset(caseData.icon, height: 30, width: 30),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
                child: Text(
                  caseData.patientName,
                  style: const TextStyle(color: Colors.black87),
                ),
              ),
            ],
          ),
        ),
        DataCell(Text(
          caseData.diagnosis ?? "Pending",
          style: const TextStyle(color: Colors.black87),
        )),
        DataCell(Text(
          caseData.date.toString().split(" ").first,
          style: const TextStyle(color: Colors.black54),
        )),
      ],
    );
  }
}
