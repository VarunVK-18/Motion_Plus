import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  await Supabase.initialize(
    url: 'https://atmtdpapsvhobjkwpqpx.supabase.co',
    anonKey: 'sb_publishable_O241Plm1tKzOCUI498OBJQ_1bgIPKk3',
  );
  final supabase = Supabase.instance.client;
  try {
    final result = await supabase.from('profiles').select().limit(1);
    print('Result: $result');
  } catch (e) {
    print('Error: $e');
  }
}
