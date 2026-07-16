import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  final supabase = SupabaseClient('https://atmtdpapsvhobjkwpqpx.supabase.co', 'sb_publishable_O241Plm1tKzOCUI498OBJQ_1bgIPKk3');
  try {
    final data = await supabase.from('sessions').select().limit(1);
    if (data.isNotEmpty) {
      print("Sessions columns: ${data[0].keys}");
    } else {
      print("No sessions found to infer schema");
    }
  } catch (e) {
    print(e);
  }
}
