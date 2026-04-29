import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme_provider.dart';

class ThemeToggleButton extends StatefulWidget {
  final double size;
  final EdgeInsetsGeometry? padding;
  final bool showLabel;

  const ThemeToggleButton({
    Key? key,
    this.size = 24.0,
    this.padding,
    this.showLabel = false,
  }) : super(key: key);

  @override
  State<ThemeToggleButton> createState() => _ThemeToggleButtonState();
}

class _ThemeToggleButtonState extends State<ThemeToggleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        // Sync animation with theme state
        if (themeProvider.isDarkMode) {
          _animationController.forward();
        } else {
          _animationController.reverse();
        }

        if (widget.showLabel) {
          return _buildWithLabel(context, themeProvider);
        } else {
          return _buildIconOnly(context, themeProvider);
        }
      },
    );
  }

  Widget _buildIconOnly(BuildContext context, ThemeProvider themeProvider) {
    return Container(
      padding: widget.padding ?? const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          themeProvider.toggleTheme();
          // Add haptic feedback
          // HapticFeedback.lightImpact();
        },
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Stack(
              alignment: Alignment.center,
              children: [
                // Sun icon (light mode)
                AnimatedOpacity(
                  opacity: themeProvider.isDarkMode ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: Transform.rotate(
                    angle: _animation.value * 0.5,
                    child: Icon(
                      Icons.wb_sunny_outlined,
                      size: widget.size,
                      color: const Color(
                        0xFF726DA8,
                      ), // Ultra Violet for light theme
                    ),
                  ),
                ),
                // Moon icon (dark mode)
                AnimatedOpacity(
                  opacity: themeProvider.isDarkMode ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Transform.rotate(
                    angle: _animation.value * -0.5,
                    child: Icon(
                      Icons.nightlight_round_outlined,
                      size: widget.size,
                      color: const Color(0xFF2697FF), // Blue for dark theme
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildWithLabel(BuildContext context, ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: Theme.of(context).dividerColor, width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          themeProvider.toggleTheme();
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // Sun icon (light mode)
                    AnimatedOpacity(
                      opacity: themeProvider.isDarkMode ? 0.0 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.wb_sunny_outlined,
                        size: 18,
                        color: const Color(0xFF726DA8),
                      ),
                    ),
                    // Moon icon (dark mode)
                    AnimatedOpacity(
                      opacity: themeProvider.isDarkMode ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.nightlight_round_outlined,
                        size: 18,
                        color: const Color(0xFF2697FF),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(width: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                themeProvider.isDarkMode ? 'Dark' : 'Light',
                key: ValueKey(themeProvider.isDarkMode),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Alternative toggle switch style
class ThemeToggleSwitch extends StatelessWidget {
  final double width;
  final double height;

  const ThemeToggleSwitch({Key? key, this.width = 60, this.height = 30})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return GestureDetector(
          onTap: () => themeProvider.toggleTheme(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: width,
            height: height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(height / 2),
              color: themeProvider.isDarkMode
                  ? const Color(0xFF2697FF)
                  : const Color(0xFF726DA8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 300),
              alignment: themeProvider.isDarkMode
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              child: Container(
                width: height - 4,
                height: height - 4,
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Icon(
                  themeProvider.isDarkMode
                      ? Icons.nightlight_round
                      : Icons.wb_sunny,
                  size: 16,
                  color: themeProvider.isDarkMode
                      ? const Color(0xFF2697FF)
                      : const Color(0xFF726DA8),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
