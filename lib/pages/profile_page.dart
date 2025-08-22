import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            Container(
              padding: EdgeInsets.only(),
              height: MediaQuery.of(context).size.height / 2,
              width: MediaQuery.of(context).size.width,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(
                    'assets/images/profile_background.jpeg',
                  ),
                  fit: BoxFit.contain,
                  alignment: Alignment.topCenter,
                ),
              ),
            ),
            Container(
              padding:
                  EdgeInsets.only(left: 20, top: 40, right: 20, bottom: 40),
              margin: EdgeInsets.only(
                top: MediaQuery.of(context).size.height / 4.5,
              ),
              height: MediaQuery.of(context).size.height,
              width: MediaQuery.of(context).size.width,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: 100),
                  // box chức năng
                  Container(
                    padding: EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline,
                        width: 2,
                      ),
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                          offset: Offset(0, 2), // bóng dưới
                        ),
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                          offset: Offset(0, -2), // bóng trên
                        ),
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                          offset: Offset(2, 0), // bóng phải
                        ),
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                          offset: Offset(-2, 0), // bóng trái
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMenuItem(
                          context,
                          Icons.person,
                          "Personal",
                          Theme.of(context).colorScheme.primary,
                        ),
                        _buildMenuItem(
                          context,
                          Icons.lock,
                          "Password",
                          Theme.of(context).colorScheme.primary,
                        ),
                        _buildMenuItem(
                          context,
                          Icons.card_giftcard,
                          "Voucher",
                          Theme.of(context).colorScheme.primary,
                        ),
                        _buildMenuItem(
                          context,
                          Icons.verified,
                          "Membership",
                          Theme.of(context).colorScheme.primary,
                        ),
                      ],
                    ),
                  ),

                  // list chức năng
                  SizedBox(height: 20),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Activities",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          SizedBox(height: 5),
                          _buildListItem(
                              context, Icons.calendar_month, "Booking History"),
                          SizedBox(height: 15),
                          Text(
                            "Systems",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          SizedBox(height: 5),
                          _buildListItem(context, Icons.info_outline_rounded,
                              "Version information: 1.0.0"),
                          SizedBox(height: 10),
                          _buildListItem(context, Icons.logout, "Logout"),
                          SizedBox(height: 80),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
            // Avatar
            Positioned(
              top: MediaQuery.of(context).size.height / 4 - 80,
              child: Column(
                children: [
                  SizedBox(
                    width: MediaQuery.of(context).size.width,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        SizedBox(width: 5),
                        _buildMenuItem(
                          context,
                          Icons.notifications,
                          "",
                          Theme.of(context).colorScheme.primary,
                        ),
                        CircleAvatar(
                          radius: 66,
                          backgroundColor: Colors.white, // viền ngoài
                          child: CircleAvatar(
                            radius: 62,
                            backgroundImage: AssetImage(
                              'assets/images/boy.jpg',
                            ),
                          ),
                        ),
                        _buildMenuItem(
                          context,
                          Icons.calendar_today,
                          "",
                          Theme.of(context).colorScheme.primary,
                        ),
                        SizedBox(width: 5),
                      ],
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Minh Bao',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildMenuItem(
    BuildContext context, IconData icon, String title, Color color) {
  return Column(
    children: [
      CircleAvatar(
          radius: 28,
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: Icon(
            icon,
            size: 28,
            color: Colors.white,
          )),
      SizedBox(height: 8),
      Text(title, style: TextStyle(fontSize: 14, color: Colors.black)),
    ],
  );
}

Widget _buildListItem(BuildContext context, IconData icon, String title) {
  return Container(
    decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onPrimary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 0), // bóng dưới
          ),
        ]),
    child: ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.secondary),
      title: Text(title),
      trailing: Icon(Icons.arrow_forward_ios, size: 20, color: Colors.grey),
      onTap: () {},
    ),
  );
}
