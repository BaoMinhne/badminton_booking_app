import 'package:badminton_booking_app/pages/tabs/image_tab.dart';
import 'package:badminton_booking_app/pages/tabs/reivew_tab.dart';
import 'package:badminton_booking_app/pages/tabs/rule_tab.dart';
import 'package:badminton_booking_app/pages/tabs/service_tab.dart';
import 'package:flutter/material.dart';

class CourtDetail extends StatefulWidget {
  const CourtDetail({super.key});

  @override
  State<CourtDetail> createState() => _CourtDetailState();
}

class _CourtDetailState extends State<CourtDetail> {
  bool _isFavorite = false;

  void _toggleFavorite() {
    setState(() {
      _isFavorite = !_isFavorite;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Container(
        child: Stack(
          children: [
            Container(
              padding: EdgeInsets.only(),
              height: MediaQuery.of(context).size.height / 2,
              width: screenWidth,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(
                    'assets/images/court_cover.jpg',
                  ),
                  fit: BoxFit.contain,
                  alignment: Alignment.topCenter,
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _circleBtn(
                    icon: Icons.arrow_back,
                    onTap: () {
                      Navigator.pop(context);
                    },
                    cs: cs,
                  ),
                  Row(
                    children: [
                      _circleBtn(
                        icon: _isFavorite
                            ? Icons.favorite
                            : Icons.favorite_border,
                        onTap: _toggleFavorite,
                        cs: cs,
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade400,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: const Text("Đặt lịch"),
                      )
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  EdgeInsets.only(left: 20, top: 40, right: 20, bottom: 40),
              margin: EdgeInsets.only(
                top: MediaQuery.of(context).size.height / 4,
              ),
              height: MediaQuery.of(context).size.height,
              width: screenWidth,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: screenWidth / 4.5),
              child: _infoTab(cs),
            ),
            Container(
              padding: EdgeInsets.only(
                top: screenWidth - 65,
              ),
              child: DefaultTabController(
                length: 4,
                child: Column(
                  children: [
                    TabBar(
                      labelColor: cs.primary,
                      unselectedLabelColor: cs.onSurface,
                      indicatorColor: cs.primary,
                      isScrollable: true,
                      padding: EdgeInsets.only(left: 5),
                      tabAlignment: TabAlignment.start,
                      tabs: const [
                        Tab(text: "Dịch vụ"),
                        Tab(text: "Hình ảnh"),
                        Tab(text: "Điều khoản & quy định"),
                        Tab(text: "Đánh giá"),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          PricingTableMini(
                            items: const [
                              ServicePrice(
                                  name: "Thuê sân đơn",
                                  unit: "giờ",
                                  price: 60000),
                              ServicePrice(
                                  name: "Thuê sân (cao điểm)",
                                  unit: "giờ",
                                  price: 150000,
                                  isPeak: true,
                                  note: "17:00–21:00 T2–T6"),
                              ServicePrice(
                                  name: "Mượn vợt",
                                  unit: "cây",
                                  price: 20000,
                                  note: "Kèm 1 quả cầu"),
                              ServicePrice(
                                  name: "Thuê giày", unit: "đôi", price: 30000),
                              ServicePrice(
                                  name: "Mua cầu lông",
                                  unit: "ống",
                                  price: 320000,
                                  note: "Loại trung cấp"),
                            ],
                          ),
                          CourtImageGallery(
                            images: const [
                              // Có thể dùng cả asset lẫn URL
                              'assets/images/court_cover.jpg',
                              'assets/images/badminton_logo.jpg',
                              'https://picsum.photos/seed/court1/1200/800',
                              'https://picsum.photos/seed/court2/1200/800',
                              'https://picsum.photos/seed/court3/1200/800',
                              'https://picsum.photos/seed/court4/1200/800',
                            ],
                          ),
                          Rules(items: [
                            "Đặt cọc 50% cho giờ cao điểm",
                            "Hủy trước 6h hoàn 100%, sau đó không hoàn",
                            "Đi giày cầu lông, không hút thuốc trong sân",
                            "Giữ vệ sinh chung, không xả rác bừa bãi",
                            "Tuân thủ quy định của sân và nhân viên sân",
                            "Không mang đồ ăn thức uống có cồn vào sân",
                            "Giữ gìn tài sản cá nhân, sân không chịu trách nhiệm",
                          ]),
                          ReviewTab(initialReviews: []),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoTab(ColorScheme cs) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Material(
        elevation: 5,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: cs.surface,
            border: Border.all(color: cs.outline, width: 1),
          ),
          child: Column(
            children: [
              ListTile(
                leading: const CircleAvatar(
                  backgroundImage:
                      AssetImage('assets/images/badminton_logo.jpg'),
                  radius: 28,
                ),
                title: const Text("Minh Nghĩa Badminton",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Container(
                  margin: const EdgeInsets.only(top: 6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE7F5EE),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text("Cầu lông",
                      style: TextStyle(color: Color(0xFF0E5A3A))),
                ),
              ),
              const Divider(),
              Row(
                children: const [
                  Icon(Icons.place, size: 20),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                        "55D Đ. Trần Nam Phú, Xuân Khánh, Ninh Kiều, Cần Thơ"),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: const [
                  Icon(Icons.schedule, size: 20),
                  SizedBox(width: 6),
                  Text("05:00 - 22:00"),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: const [
                  Icon(Icons.call, size: 20),
                  SizedBox(width: 6),
                  Text(
                    "0329672505",
                    style: TextStyle(color: Colors.blue),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _circleBtn({
    required IconData icon,
    required VoidCallback onTap,
    required ColorScheme cs,
  }) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            color: cs.primary,
          ),
        ),
      ),
    );
  }
}
