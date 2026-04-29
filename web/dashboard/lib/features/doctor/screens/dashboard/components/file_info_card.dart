import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:tbcare_main/core/app_constants.dart';
import 'package:tbcare_main/features/doctor/models/doctor_stats.dart';

class FileInfoCard extends StatelessWidget {
  const FileInfoCard({super.key, required this.info});

  final DoctorStat info;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(defaultPadding),
      decoration: BoxDecoration(
        color: Colors.white, // ✅ Light card background
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        border: Border.all(
          color: primaryColor.withOpacity(0.15), // subtle border
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(defaultPadding * 0.25),
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: info.color.withOpacity(0.15), // ✅ soft background tint
                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                ),
                child: SvgPicture.asset(
                  info.icon,
                  colorFilter: ColorFilter.mode(
                    info.color, // icon uses main color
                    BlendMode.srcIn,
                  ),
                ),
              ),
              const Icon(Icons.more_vert, color: Colors.black38),
            ],
          ),
          const SizedBox(height: defaultPadding / 2),
          Text(
            info.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.black54), // ✅ lighter label
          ),
          const SizedBox(height: defaultPadding / 2),
          Text(
            "${info.value}",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: primaryColor, // ✅ strong teal for numbers
            ),
          ),
        ],
      ),
    );
  }
}
