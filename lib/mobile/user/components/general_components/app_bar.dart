import 'package:capstone_app/mobile/user/components/general_components/user_mobile_notif_button.dart';
import 'package:capstone_app/components/download_app_button.dart';
import 'package:flutter/material.dart';

class MyAppBar extends StatelessWidget implements PreferredSizeWidget {
  @override
  final Size preferredSize;

  const MyAppBar({super.key})
  
  // to adjust appbar height  
  : preferredSize = const Size.fromHeight(50.0);

  @override

  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      title: Image.asset(
        'lib/images/PAWrtal_logo.png',
        width: 160, 
        fit: BoxFit.contain,
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1.0),
        child: Container(
          color: Colors.grey.shade400,
          height: 1,
        ),
      ),
      leading: Builder(
        builder: (context) {
          return IconButton(
            icon: const Icon(Icons.menu_outlined),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          );
        }
      ),
      actions: const [
        DownloadAppButton(isMobileLayout: true),
        SizedBox(width: 8),
        MyNotifButton()
      ],
    );
  }
}