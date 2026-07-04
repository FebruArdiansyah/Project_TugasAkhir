import 'package:flutter/material.dart';
import 'pages/splash_screen.dart';
import 'pages/login.dart';
import 'pages/home.dart';
import 'pages/barang_masuk.dart';
import 'pages/tambah_barang_masuk.dart';
import 'pages/barang_keluar.dart';
import 'pages/tambah_barang_keluar.dart';
import 'pages/riwayat_transaksi.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NSA Mobile',
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/barang-masuk': (context) => const BarangMasukScreen(),
        '/tambah-barang-masuk': (context) => const TambahBarangMasukScreen(),
        '/barang-keluar': (context) => const BarangKeluarScreen(),
        '/tambah-barang-keluar': (context) => const TambahBarangKeluarScreen(),
        '/riwayat-transaksi': (context) => const RiwayatTransaksiScreen(),
      },
    );
  }
}