import 'dart:convert';
import 'package:http/http.dart' as http;

class SupabaseService {
  final String supabaseUrl = "https://uvrwqhuzjttktlqerruc.supabase.co";
  final String functionName = "manage-users";
  final String anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InV2cndxaHV6anR0a3RscWVycnVjIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTczODIzMjYzOSwiZXhwIjoyMDUzODA4NjM5fQ.9KkZjb8TZq4f5vIBWsi0GF1ZX-_yqWSyCWeX_J-EQ-Y"; 

  Future<void> callFunction(String name) async {
    final url = Uri.parse("$supabaseUrl/functions/v1/$functionName");

    final response = await http.post(
      url,
      headers: {
        "Authorization": "Bearer $anonKey",
        "Content-Type": "application/json",
      },
      body: jsonEncode({"name": name}),
    );

    if (response.statusCode == 200) {
      print("Response: ${response.body}");
    } else {
      print("Error: ${response.statusCode} - ${response.body}");
    }
  }
}
