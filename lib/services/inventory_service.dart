import 'dart:convert';
import 'package:connectbeat/models/inventory_models.dart';
import 'package:connectbeat/models/store_models.dart';
import 'package:connectbeat/services/auth_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class InventoryService {
  final String baseUrl = dotenv.env['BASE_URL'] ?? '';

  Future<List<InventoryItemDTO>> fetchInventory() async {
    final headers = await AuthService.buildAuthHeader();
    final resp = await http.get(Uri.parse('$baseUrl/store/inventory'), headers: headers);
    if (resp.statusCode == 200) {
      final List data = json.decode(resp.body);
      return data.map((e) => InventoryItemDTO.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception('인벤토리 조회 실패: ${resp.statusCode}');
  }

  Future<void> applyDecoration(int itemId) async {
    final headers = await AuthService.buildAuthHeader();
    headers['Content-Type'] = 'application/json';
    final resp = await http.post(
      Uri.parse('$baseUrl/store/decoration/apply'),
      headers: headers,
      body: json.encode({'itemId': itemId}),
    );
    if (resp.statusCode != 200) throw Exception('데코 적용 실패: ${resp.statusCode}');
  }

  Future<CurrentDecorationDTO> fetchCurrentDecoration() async {
    final headers = await AuthService.buildAuthHeader();
    final resp = await http.get(Uri.parse('$baseUrl/store/decoration'), headers: headers);
    if (resp.statusCode == 200) {
      final data = json.decode(resp.body) as Map<String, dynamic>;
      return CurrentDecorationDTO.fromJson(data);
    }
    throw Exception('현재 데코 조회 실패: ${resp.statusCode}');
  }
}

/// 현재 적용된 데코 DTO
class CurrentDecorationDTO {
  final StoreItemDTO? backgroundItem;
  final StoreItemDTO? clothesItem; // 옷도 포함

  CurrentDecorationDTO({this.backgroundItem, this.clothesItem});

  factory CurrentDecorationDTO.fromJson(Map<String, dynamic> json) {
    return CurrentDecorationDTO(
      backgroundItem: json['backgroundItem'] != null
          ? StoreItemDTO.fromJson(json['backgroundItem'] as Map<String, dynamic>)
          : null,
      clothesItem: json['clothesItem'] != null
          ? StoreItemDTO.fromJson(json['clothesItem'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'backgroundItem': backgroundItem?.toJson(),
      'clothesItem': clothesItem?.toJson(),
    };
  }
}
