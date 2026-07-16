import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  final supabase = SupabaseClient('https://atmtdpapsvhobjkwpqpx.supabase.co', 'sb_publishable_O241Plm1tKzOCUI498OBJQ_1bgIPKk3');
  try {
    final data = await supabase.rpc('get_schema_info'); // or something else.
    // just try to insert a fake record into sessions and catch the error to see schema
  } catch (e) {
    print(e);
  }
}
