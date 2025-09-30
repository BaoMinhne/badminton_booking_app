import 'package:flutter/material.dart';
import 'package:badminton_booking_app/pages/court/tabs/image_tab.dart';
import 'package:badminton_booking_app/pages/court/tabs/review_tab.dart';
import 'package:badminton_booking_app/pages/court/tabs/rule_tab.dart';
import 'package:badminton_booking_app/pages/court/tabs/service_tab.dart';

class CourtDetail extends StatefulWidget {
  const CourtDetail({super.key});

  @override
  State<CourtDetail> createState() => _CourtDetailState();
}

class _CourtDetailState extends State<CourtDetail>
    with TickerProviderStateMixin {
  bool _isFavorite = false;

  void _toggleFavorite() => setState(() => _isFavorite = !_isFavorite);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                pinned: true,
                floating: false,
                expandedHeight: MediaQuery.of(context).size.height * 0.24,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                actions: [
                  _circleBtn(
                    icon: _isFavorite ? Icons.favorite : Icons.favorite_border,
                    onTap: _toggleFavorite,
                    cs: cs,
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade400,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: const Text("Đặt lịch"),
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/images/court_cover.jpg'),
                        fit: BoxFit.cover,
                        alignment: Alignment.topCenter,
                      ),
                    ),
                  ),
                ),
              ),

              // infoCard có thể cao bao nhiêu cũng được
              SliverToBoxAdapter(
                child: _infoCard(cs),
              ),

              // TabBar ghim ở trên cùng khi cuộn
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverTabBarDelegate(
                  TabBar(
                    labelColor: cs.primary,
                    unselectedLabelColor: cs.onSurface,
                    indicatorColor: cs.primary,
                    isScrollable: true,
                    padding: const EdgeInsets.only(left: 5),
                    tabAlignment: TabAlignment.start,
                    tabs: const [
                      Tab(text: "Dịch vụ"),
                      Tab(text: "Hình ảnh"),
                      Tab(text: "Điều khoản & quy định"),
                      Tab(text: "Đánh giá"),
                    ],
                  ),
                ),
              ),
            ];
          },

          // Nội dung từng Tab
          body: TabBarView(
            children: [
              PricingTableMini(
                items: const [
                  ServicePrice(name: "Thuê sân đơn", unit: "giờ", price: 60000),
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
                  ServicePrice(name: "Thuê giày", unit: "đôi", price: 30000),
                  ServicePrice(
                      name: "Mua cầu lông",
                      unit: "ống",
                      price: 320000,
                      note: "Loại trung cấp"),
                ],
              ),
              CourtImageGallery(
                images: const [
                  'assets/images/court_cover.jpg',
                  'assets/images/badminton_logo.jpg',
                  'https://picsum.photos/seed/court1/1200/800',
                  'https://picsum.photos/seed/court2/1200/800',
                  'https://picsum.photos/seed/court3/1200/800',
                  'https://picsum.photos/seed/court4/1200/800',
                ],
              ),
              Rules(items: const [
                "Đặt cọc 50% cho giờ cao điểm",
                "Hủy trước 6h hoàn 100%, sau đó không hoàn",
                "Đi giày cầu lông, không hút thuốc trong sân",
                "Giữ vệ sinh chung, không xả rác bừa bãi",
                "Tuân thủ quy định của sân và nhân viên sân",
                "Không mang đồ ăn thức uống có cồn vào sân",
                "Giữ gìn tài sản cá nhân, sân không chịu trách nhiệm",
              ]),
              const ReviewTab(initialReviews: []),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoCard(ColorScheme cs) {
    return Padding(
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
              const ListTile(
                leading: CircleAvatar(
                  backgroundImage:
                      AssetImage('assets/images/badminton_logo.jpg'),
                  radius: 28,
                ),
                title: Text("Minh Nghĩa Badminton",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Chip(
                    label: Text("Cầu lông",
                        style: TextStyle(color: Color(0xFF0E5A3A))),
                    backgroundColor: Color(0xFFE7F5EE),
                    visualDensity: VisualDensity(horizontal: 0, vertical: -4),
                  ),
                ),
              ),
              const Divider(),
              const Row(
                children: [
                  Icon(Icons.place, size: 20),
                  SizedBox(width: 6),
                  Expanded(
                      child: Text(
                          "55D Đ. Trần Nam Phú, Xuân Khánh, Ninh Kiều, Cần Thơ")),
                ],
              ),
              const SizedBox(height: 12),
              const Row(
                children: [
                  Icon(Icons.schedule, size: 20),
                  SizedBox(width: 6),
                  Text("05:00 - 22:00"),
                ],
              ),
              const SizedBox(height: 12),
              const Row(
                children: [
                  Icon(Icons.call, size: 20),
                  SizedBox(width: 6),
                  Text("0329672505", style: TextStyle(color: Colors.blue)),
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
          child: Icon(icon, color: cs.primary),
        ),
      ),
    );
  }
}

/// Delegate để ghim TabBar như một Sliver header
class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  _SliverTabBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      color: cs.surface, // giữ nền khi ghim
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(covariant _SliverTabBarDelegate oldDelegate) {
    return oldDelegate._tabBar != _tabBar;
  }
}
