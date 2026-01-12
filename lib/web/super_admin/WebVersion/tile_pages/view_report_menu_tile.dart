import 'package:capstone_app/web/super_admin/WebVersion/view_report/user_app_feedback/app_feedback.dart';
import 'package:flutter/material.dart';

class ViewReportTile extends StatelessWidget {
  const ViewReportTile({super.key});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    final isMediumScreen = screenSize.width < 1200;

    // Responsive sizing
    double tileWidth = screenSize.width * 0.8;
    double tileHeight = screenSize.height * 0.75;

    if (isSmallScreen) {
      tileWidth = screenSize.width * 0.9;
      tileHeight = screenSize.height * 0.6;
    } else if (isMediumScreen) {
      tileWidth = screenSize.width * 0.85;
      tileHeight = screenSize.height * 0.65;
    }

    // Constrain maximum dimensions to prevent excessive sizes on large screens
    tileWidth = tileWidth.clamp(200.0, 400.0);
    tileHeight = tileHeight.clamp(250.0, 500.0);

    return InkWell(
      highlightColor: Colors.transparent,
      splashColor: Colors.transparent,
      hoverColor: Colors.transparent,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const AdminFeedbackManagement(),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 8.0 : 5.0),
        child: Container(
          height: tileHeight,
          width: tileWidth,
          constraints: const BoxConstraints(
            minHeight: 200,
            maxHeight: 500,
            minWidth: 150,
            maxWidth: 400,
          ),
          decoration: BoxDecoration(
            color: const Color.fromRGBO(81, 115, 153, 0.8),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Flexible image container to prevent overflow
                Flexible(
                  flex: 3,
                  child: Container(
                    constraints: BoxConstraints(
                      maxHeight: tileHeight * 0.6,
                      maxWidth: tileWidth * 0.8,
                    ),
                    child: AspectRatio(
                      aspectRatio:
                          1.0, // Square aspect ratio for consistent look
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          'lib/images/view_report_icon.png',
                          fit: BoxFit
                              .contain, // Changed to contain to prevent cropping
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.assessment,
                                size: isSmallScreen ? 40 : 60,
                                color: Colors.grey[600],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),

                // Spacing between image and text
                SizedBox(height: isSmallScreen ? 8.0 : 12.0),

                // Flexible text container to prevent overflow
                Flexible(
                  flex: 1,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'View Reports',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 16 : 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
