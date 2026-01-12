import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class DownloadAppButton extends StatelessWidget {
  final bool isMobileLayout;

  const DownloadAppButton({
    super.key,
    this.isMobileLayout = false,
  });

  static const String apkDownloadUrl = 'https://github.com/hail-dev/PAWrtal-App/releases/download/v1.0.0/PAWrtal.apk';

  @override
  Widget build(BuildContext context) {
    // Only show on web platform
    if (!kIsWeb) return const SizedBox.shrink();

    if (isMobileLayout) {
      // Mobile web layout - icon button
      return IconButton(
        icon: const Icon(Icons.download),
        tooltip: 'Download PAWrtal App',
        onPressed: () => _showDownloadDialog(context),
      );
    }

    // Desktop web layout - text button
    return TextButton.icon(
      onPressed: () => _showDownloadDialog(context),
      icon: const Icon(Icons.download, size: 18),
      label: const Text(
        'Download App',
        style: TextStyle(fontSize: 15),
      ),
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF517399),
      ),
    );
  }

  void _showDownloadDialog(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 600;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          width: isDesktop ? 450 : double.infinity,
          padding: const EdgeInsets.all(24),
          child: isDesktop
              ? _buildDesktopContent(context)
              : _buildMobileContent(context),
        ),
      ),
    );
  }

  Widget _buildDesktopContent(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Download PAWrtal App',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: QrImageView(
            data: apkDownloadUrl,
            version: QrVersions.auto,
            size: 250.0,
            backgroundColor: Colors.white,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Scan this QR code with your mobile device to download the PAWrtal app',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () => _launchUrl(apkDownloadUrl),
          icon: const Icon(Icons.download),
          label: const Text('Or download directly'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF517399),
            side: const BorderSide(color: Color(0xFF517399)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileContent(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text(
                'Download PAWrtal App',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Icon(
          Icons.phone_android,
          size: 80,
          color: Colors.grey.shade400,
        ),
        const SizedBox(height: 16),
        const Text(
          'Get the full PAWrtal experience with our mobile app!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _launchUrl(apkDownloadUrl);
            },
            icon: const Icon(Icons.download),
            label: const Text('Download APK'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF517399),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Text(
        //   'Version 1.0.0 • ${(0.0).toStringAsFixed(1)} MB',
        //   style: TextStyle(
        //     fontSize: 12,
        //     color: Colors.grey.shade600,
        //   ),
        // ),
      ],
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}