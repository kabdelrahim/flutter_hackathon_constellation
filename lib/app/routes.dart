import 'package:flutter/material.dart';
import '../views/home/home_view.dart';
import '../views/auth/login_view.dart';
import '../views/association/association_list_view.dart';
import '../views/association/association_detail_view.dart';

final Map<String, WidgetBuilder> appRoutes = {
  '/': (context) => const HomeView(),
  '/login': (context) => const LoginView(),
  '/associations': (context) => const AssociationListView(),
  '/association-detail': (context) => const AssociationDetailView(),
};
