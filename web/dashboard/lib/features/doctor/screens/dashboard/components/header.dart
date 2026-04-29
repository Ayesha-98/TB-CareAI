import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:tbcare_main/core/app_constants.dart';
import 'package:tbcare_main/core/responsive.dart';
import 'package:tbcare_main/features/doctor/models/doctor_profile_model.dart';
import 'package:tbcare_main/features/doctor/screens/patients/patient_details_screen.dart';
import 'package:tbcare_main/features/doctor/services/doctor_profile_service.dart';
import '../../../models/patient_model.dart';
import '../../../services/patient_service.dart';

class Header extends StatelessWidget {
  const Header({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (Responsive.isTablet(context))
          IconButton(
            onPressed: () => Scaffold.of(context).openDrawer(),
            icon: const Icon(Icons.menu, color: Colors.black87),
          ),
        if (Responsive.isDesktop(context))
          const Text(
            "Dashboard",
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 30,
            ),
          ),
        if (!Responsive.isMobile(context))
          Spacer(flex: Responsive.isDesktop(context) ? 2 : 1),
        const Expanded(child: SearchField()),
        const ProfileMenu(),
      ],
    );
  }
}

class SearchField extends StatefulWidget {
  const SearchField({super.key});

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  OverlayEntry? _overlayEntry;

  List<PatientModel> allPatients = [];
  List<PatientModel> suggestions = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPatients();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) _removeOverlay();
  }

  Future<void> _loadPatients() async {
    try {
      final patients = await PatientService.fetchAllPatients();
      if (!mounted) return;
      setState(() {
        allPatients = patients;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      debugPrint('Error loading patients: $e');
    }
  }

  void _onSearchChanged(String query) {
    final filtered = query.isEmpty
        ? <PatientModel>[]
        : allPatients
            .where((p) => p.name.toLowerCase().contains(query.toLowerCase()))
            .take(3)
            .toList();

    setState(() => suggestions = filtered);

    if (suggestions.isNotEmpty) {
      _showOverlay();
    } else {
      _removeOverlay();
    }
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showOverlay() {
    _removeOverlay();
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final offset = renderBox.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx,
        top: offset.dy + renderBox.size.height + 8,
        width: renderBox.size.width,
        child: Material(
          elevation: 8,
          shadowColor: Colors.black.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: ListView.separated(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              itemCount: suggestions.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                color: Colors.grey.withOpacity(0.1),
              ),
              itemBuilder: (context, index) {
                final patient = suggestions[index];
                return ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: primaryColor.withOpacity(0.1),
                    child: Text(
                      patient.name[0].toUpperCase(),
                      style: const TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    patient.name,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    "ID: ${patient.uid.substring(0, 8)}...",
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                  onTap: () {
                    _removeOverlay();
                    _controller.clear();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PatientDetailScreen(patient: patient),
                      ),
                    );
                  },
                  hoverColor: primaryColor.withOpacity(0.05),
                );
              },
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  @override
  void dispose() {
    _removeOverlay();
    _focusNode.removeListener(_onFocusChange);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        onChanged: _onSearchChanged,
        style: const TextStyle(color: Colors.black87),
        decoration: InputDecoration(
          hintText: "Search patients...",
          hintStyle: TextStyle(color: Colors.grey.shade400),
          fillColor: Colors.transparent,
          filled: true,
          border: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
          suffixIcon: InkWell(
            onTap: () => _onSearchChanged(_controller.text),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: SvgPicture.asset(
                "assets/icons/search-svgrepo-com.svg",
                colorFilter:
                    const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                width: 16,
                height: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ProfileMenu extends StatefulWidget {
  const ProfileMenu({super.key});

  @override
  State<ProfileMenu> createState() => _ProfileMenuState();
}

class _ProfileMenuState extends State<ProfileMenu> {
  final DoctorProfileService _profileService = DoctorProfileService();
  late final Stream<Doctor?> _doctorStream;

  @override
  void initState() {
    super.initState();
    _doctorStream = _profileService.getCurrentDoctorProfile();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Doctor?>(
      stream: _doctorStream,
      builder: (context, snapshot) {
        final doctor = snapshot.data;
        final isLoading = snapshot.connectionState == ConnectionState.waiting;
        final hasError = snapshot.hasError;

        return InkWell(
          onTap: () => Navigator.pushNamed(context, '/doctor_profile'),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
            child: Row(
              children: [
                _buildAvatar(doctor, isLoading, hasError),
                const SizedBox(width: defaultPadding / 2),
                _buildName(doctor, isLoading, hasError),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAvatar(Doctor? doctor, bool isLoading, bool hasError) {
    if (isLoading) {
      return const CircleAvatar(
        radius: 18,
        backgroundColor: Colors.grey,
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        ),
      );
    }

    final imageUrl = doctor?.profileImageUrl;
    final hasValidImage = imageUrl != null && imageUrl.isNotEmpty;

    if (hasValidImage) {
      return CircleAvatar(
        radius: 18,
        backgroundColor: Colors.grey.shade300,
        backgroundImage: NetworkImage(imageUrl),
        onBackgroundImageError: (_, __) {},
        child: null,
      );
    }

    return CircleAvatar(
      radius: 18,
      backgroundColor: primaryColor.withOpacity(0.2),
      child: Icon(
        Icons.person,
        size: 20,
        color: primaryColor,
      ),
    );
  }

  Widget _buildName(Doctor? doctor, bool isLoading, bool hasError) {
    if (isLoading) {
      return Container(
        width: 80,
        height: 14,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(4),
        ),
      );
    }

    if (hasError || doctor == null) {
      return const Text(
        "Doctor",
        style: TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      );
    }

    return Text(
      doctor.name.isNotEmpty ? doctor.name : "Doctor",
      style: const TextStyle(
        color: Colors.black87,
        fontWeight: FontWeight.w500,
      ),
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
    );
  }
}