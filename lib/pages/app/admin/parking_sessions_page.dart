import 'package:flutter/material.dart';
import 'package:uniparkpay/widgets/app/content_page.dart';
import 'parking_guest_tab.dart';
import 'parking_non_guest_tab.dart';

class ParkingSessionsPage extends ContentPage {
  const ParkingSessionsPage({super.key})
      : super(title: 'Parking Sessions');

  @override
  State<ParkingSessionsPage> createState() => _ParkingSessionsPageState();
}

class _ParkingSessionsPageState extends State<ParkingSessionsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(text: 'Guest Sessions'),
          Tab(text: 'Lecturer/Student Sessions'),
        ],
        labelColor: Theme.of(context).primaryColor,
        unselectedLabelColor: Colors.grey,
        indicatorColor: Theme.of(context).primaryColor,
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          ParkingGuestTab(),
          ParkingNonGuestTab(),
        ],
      ),
    );
  }
}