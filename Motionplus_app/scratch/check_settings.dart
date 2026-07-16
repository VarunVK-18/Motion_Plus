import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  final supabase = SupabaseClient('https://atmtdpapsvhobjkwpqpx.supabase.co', 'sb_publishable_O241Plm1tKzOCUI498OBJQ_1bgIPKk3');
  try {
    final data = await supabase.from('platform_settings').select();
    print(data);
  } catch (e) {
    print(e);
  }
}
