import 'package:flutter/material.dart';
import 'package:tbcare_main/core/app_constants.dart';
import '../../models/patient_model.dart';
import 'components/patient_card.dart';
import '../../services/patient_service.dart';

class PatientsScreen extends StatefulWidget {
  const PatientsScreen({super.key});

  @override
  State<PatientsScreen> createState() => _PatientsScreenState();
}

class _PatientsScreenState extends State<PatientsScreen> {
  List<PatientModel> patients = [];
  String selectedFilter = 'All';
  String searchQuery = '';
  bool isLoading = true;
  String? errorMessage;

  final List<String> filters = ['All', 'TB', 'Not TB', 'TB Likely'];

  @override
  void initState() {
    super.initState();
    fetchPatients();
  }

  Future<void> fetchPatients() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      final data = await PatientService.fetchAllPatients();
      if (!mounted) return;
      setState(() {
        patients = data;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching patients: $e');
      if (!mounted) return;
      setState(() {
        isLoading = false;
        errorMessage = 'Failed to load patients. Please try again.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Error loading patients.'), backgroundColor: errorColor),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredPatients = patients.where((patient) {
      final matchFilter =
          selectedFilter == 'All' ||
          patient.diagnosisStatus.toLowerCase() == selectedFilter.toLowerCase();
      final matchSearch = patient.name.toLowerCase().contains(
        searchQuery.toLowerCase(),
      );
      return matchFilter && matchSearch;
    }).toList();

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        title: Text("Patients", style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: fetchPatients,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(defaultPadding),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(25,0,25,0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: (value) => setState(() => searchQuery = value),
                      style: const TextStyle(color: secondaryColor),
                      decoration: InputDecoration(
                        hintText: 'Search by name...',
                        hintStyle: TextStyle(color: secondaryColor.withOpacity(0.6)),
                        fillColor: Colors.white,
                        filled: true,
                        prefixIcon: Icon(
                          Icons.search,
                          color: secondaryColor.withOpacity(0.7),
                        ),
                        border: OutlineInputBorder(
                          borderSide: const BorderSide(color: secondaryColor),
                          borderRadius: BorderRadius.circular(defaultRadius),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: secondaryColor),
                          borderRadius: BorderRadius.circular(defaultRadius),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: primaryColor, width: 2),
                          borderRadius: BorderRadius.circular(defaultRadius),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: secondaryColor),
                      borderRadius: BorderRadius.circular(defaultRadius),
                    ),
                    child: DropdownButton<String>(
                      dropdownColor: Colors.white,
                      value: selectedFilter,
                      borderRadius: BorderRadius.circular(defaultRadius),
                      iconEnabledColor: secondaryColor,
                      style: const TextStyle(color: secondaryColor),
                      underline: const SizedBox(),
                      items: filters.map((filter) {
                        return DropdownMenuItem(
                          value: filter, 
                          child: Text(filter, style: const TextStyle(color: secondaryColor)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => selectedFilter = value);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: defaultPadding),
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator(color: primaryColor))
                    : errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 48, color: errorColor),
                            const SizedBox(height: 16),
                            Text(
                              errorMessage!,
                              style: const TextStyle(color: errorColor, fontSize: 16),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: fetchPatients,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                              style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white),
                            ),
                          ],
                        ),
                      )
                    : filteredPatients.isEmpty
                    ? Center(
                        child: Text(
                          "No patients found",
                          style: TextStyle(
                            color: secondaryColor.withOpacity(0.7),
                            fontSize: bodySize,
                          ),
                        ),
                      )
                    : GridView.builder(
                        itemCount: filteredPatients.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: MediaQuery.of(context).size.width > 800
                              ? 3
                              : 1,
                          crossAxisSpacing: defaultPadding,
                          mainAxisSpacing: defaultPadding,
                          childAspectRatio: 2.6,
                        ),
                        itemBuilder: (context, index) {
                          return PatientCard(patient: filteredPatients[index]);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}