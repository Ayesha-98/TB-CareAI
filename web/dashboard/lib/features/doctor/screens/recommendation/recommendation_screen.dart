import 'package:flutter/material.dart';
import 'package:tbcare_main/core/app_constants.dart';
import '../../models/patient_model.dart';
import '../../services/patient_service.dart';
import 'components/recommendation_card.dart';

class RecommendationScreen extends StatefulWidget {
  const RecommendationScreen({super.key});

  @override
  State<RecommendationScreen> createState() => _RecommendationScreenState();
}

class _RecommendationScreenState extends State<RecommendationScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  late Future<List<PatientModel>> _tbPatientsFuture;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    setState(() {
      _tbPatientsFuture = PatientService.fetchDeepTBPatients();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          "Recommendations",
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: false,
        leading: null,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2), // Semi-transparent white
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.refresh, size: 20, color: Colors.white),
            ),
            onPressed: _refreshData,
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // Summary Card
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(defaultPadding),
            padding: const EdgeInsets.all(largePadding),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor, primaryColor.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(largeRadius),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: FutureBuilder<List<PatientModel>>(
              future: _tbPatientsFuture,
              builder: (context, snapshot) {
                final count = snapshot.hasData ? snapshot.data!.length : 0;
                final isLoading = snapshot.connectionState == ConnectionState.waiting;

                return Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.medical_services_outlined,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Confirmed TB Cases',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : snapshot.hasError
                                  ? const Icon(Icons.error_outline, color: Colors.white)
                                  : Text(
                                      "$count Patients",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // List Header and Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      "Patient List",
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: secondaryColor,
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.filter_list, size: 20, color: secondaryColor.withOpacity(0.5)),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: "Search patients by name...",
                    prefixIcon: const Icon(Icons.search, color: primaryColor),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: primaryColor, width: 2),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Patient List
          Expanded(
            child: FutureBuilder<List<PatientModel>>(
              future: _tbPatientsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: primaryColor),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: errorColor.withOpacity(0.5)),
                        const SizedBox(height: 16),
                        Text(
                          "Error loading patients",
                          style: TextStyle(
                            color: secondaryColor.withOpacity(0.7),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                var tbPatients = snapshot.data ?? [];
                
                // Apply Search Filter
                if (_searchQuery.isNotEmpty) {
                  tbPatients = tbPatients.where((p) => p.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
                }

                if (tbPatients.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 64,
                          color: secondaryColor.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "No patients found",
                          style: TextStyle(
                            color: secondaryColor.withOpacity(0.6),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: defaultPadding),
                  itemCount: tbPatients.length,
                  itemBuilder: (context, index) {
                    final patient = tbPatients[index];
                    return PatientRecommendationCard(patient: patient);
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