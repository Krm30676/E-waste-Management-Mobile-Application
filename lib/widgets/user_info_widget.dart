import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart' as myAuth;

class UserInfoWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<myAuth.AuthProvider>(context);
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundImage: NetworkImage(authProvider.user?.photoURL ?? 'https://via.placeholder.com/150'),
        ),
        SizedBox(width: 20),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome, ${authProvider.user?.displayName ?? 'User'}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            SizedBox(height: 5),
            Text(
              'Email: ${authProvider.user?.email ?? 'No Email'}',
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
          ],
        ),
      ],
    );
  }
}
