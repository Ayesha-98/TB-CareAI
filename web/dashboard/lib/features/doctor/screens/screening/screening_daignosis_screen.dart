import 'package:flutter/material.dart';
import 'package:tbcare_main/core/app_constants.dart';
import '../../models/ai_case_model.dart';
import 'components/ai_case_card.dart';
import '../../services/screening_service.dart';

class ScreeningDiagnosisScreen extends StatefulWidget {
  const ScreeningDiagnosisScreen({super.key});

  @override
  State<ScreeningDiagnosisScreen> createState() =>
      _ScreeningDiagnosisScreenState();
}

class _ScreeningDiagnosisScreenState extends State<ScreeningDiagnosisScreen> {
  List<AiCaseModel> _allCases = [];
  List<AiCaseModel> _filteredCases = [];
  bool isLoading = true;
  String? errorMessage;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchScreeningCases();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredCases = List.from(_allCases);
      } else {
        _filteredCases = _allCases.where((caseData) {
          return caseData.patientName.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  Future<void> fetchScreeningCases() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      final fetched = await ScreeningService.fetchAiCasesForDoctorDashboard();
      if (!mounted) return;
      setState(() {
        _allCases = fetched;
        _filteredCases = fetched;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching cases: $e");
      if (!mounted) return;
      setState(() {
        isLoading = false;
        errorMessage = "Failed to load screening cases.";
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error loading cases.'), backgroundColor: errorColor),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor, // Use standard background
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: false,
        title: Text(
          "Screening & Diagnosis",
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white, // White text on primary color
                fontWeight: FontWeight.w700,
              ),
        ),
        backgroundColor: primaryColor, // Required by user
        elevation: 0,
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2), // Semi-transparent white
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.refresh, color: Colors.white, size: 20),
            ),
            onPressed: fetchScreeningCases,
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // Search Bar Section - Keep it clean but on primary/bg boundary
          Container(
            color: bgColor,
            padding: const EdgeInsets.fromLTRB(largePadding, largePadding, largePadding, smallPadding),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: "Search by patient name...",
                  hintStyle: TextStyle(color: secondaryColor.withOpacity(0.4)),
                  prefixIcon: Icon(Icons.search, color: secondaryColor.withOpacity(0.4)),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: secondaryColor.withOpacity(0.4)),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
              ),
            ),
          ),

          // Content
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (isLoading) {
                  return const Center(child: CircularProgressIndicator(color: primaryColor));
                }
                
                if (errorMessage != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: errorColor),
                        const SizedBox(height: 16),
                        Text(
                          errorMessage!,
                          style: TextStyle(
                            color: errorColor.withOpacity(0.8),
                            fontSize: bodySize,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: fetchScreeningCases,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                          style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white),
                        ),
                      ],
                    ),
                  );
                }

                if (_filteredCases.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _allCases.isEmpty
                              ? Icons.assignment_outlined
                              : Icons.search_off,
                          size: 64,
                          color: secondaryColor.withOpacity(0.2),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _allCases.isEmpty
                              ? "No screenings found"
                              : "No patients found matching '${_searchController.text}'",
                          style: TextStyle(
                            color: secondaryColor.withOpacity(0.5),
                            fontSize: bodySize,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Calculate optimal responsive sizing
                const double minCardWidth = 340.0;
                const double maxCardWidth = 400.0;
                
                double availableWidth = constraints.maxWidth - (2 * largePadding); // Accounting for ListView padding
                int crossAxisCount = (availableWidth / (minCardWidth + largePadding)).floor();
                if (crossAxisCount < 1) crossAxisCount = 1;
                
                double totalSpacing = (crossAxisCount - 1) * largePadding;
                double calculatedWidth = (availableWidth - totalSpacing) / crossAxisCount;
                double itemWidth = calculatedWidth > maxCardWidth ? maxCardWidth : calculatedWidth;

                return ListView.builder(
                  padding: const EdgeInsets.all(largePadding),
                  itemCount: (_filteredCases.length / crossAxisCount).ceil(),
                  itemBuilder: (context, rowIndex) {
                    int startIndex = rowIndex * crossAxisCount;
                    int endIndex = startIndex + crossAxisCount;
                    if (endIndex > _filteredCases.length) endIndex = _filteredCases.length;
                    
                    List<AiCaseModel> rowCases = _filteredCases.sublist(startIndex, endIndex);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: largePadding),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: List.generate(rowCases.length, (index) {
                          return Padding(
                            padding: EdgeInsets.only(
                              right: index < rowCases.length - 1 ? largePadding : 0,
                            ),
                            child: SizedBox(
                              width: itemWidth,
                              child: AiCaseCard(caseData: rowCases[index]),
                            ),
                          );
                        }),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}