import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vitalmap/services/backend_analysis_service.dart';

void main() {
  Future<Map<String, dynamic>> scan(http.Client client) => http.runWithClient(
      () => BackendAnalysisService.scanLabReport(
          fileName: 'report.png', bytes: Uint8List.fromList([1, 2, 3])),
      () => client);
  test('public calculation URL does not receive report files', () async {
    final calls = <String>[];
    final result = await scan(MockClient((request) async {
      calls.add('${request.method} ${request.url.path}');
      expect(request.url.host, '127.0.0.1');
      if (request.method == 'GET') {
        return http.Response(
            jsonEncode(
                {'text_model_installed': true, 'vision_model_installed': true}),
            200);
      }
      expect(
          request.headers['content-type'], startsWith('multipart/form-data'));
      expect(request.body, contains('name="file"; filename="report.png"'));
      return http.Response(
          '{"fields":[{"key":"hdl","value":50,"unit":"mg/dL"}]}', 200);
    }));
    expect(calls, ['GET /tools/status', 'POST /tools/lab-report/scan']);
    expect((result['fields'] as List).single['value'], 50);
  });
  test('offline processor gives recovery steps without uploading report',
      () async {
    var calls = 0;
    await expectLater(scan(MockClient((request) async {
      calls++;
      throw http.ClientException('Connection refused');
    })),
        throwsA(isA<ReportProcessorException>().having((e) => e.message,
            'message', contains('START_LOCAL_REPORT_PROCESSOR.bat'))));
    expect(calls, 1);
  });
  test('missing vision model stops image upload', () async {
    final methods = <String>[];
    await expectLater(scan(MockClient((request) async {
      methods.add(request.method);
      return http.Response(
          '{"text_model_installed":true,"vision_model_installed":false}', 200);
    })),
        throwsA(isA<ReportProcessorException>()
            .having((e) => e.message, 'message', contains('qwen2.5vl:3b'))));
    expect(methods, ['GET']);
  });
  test('empty extraction explains how to choose a readable report', () async {
    await expectLater(scan(MockClient((request) async {
      return http.Response(
          request.method == 'GET'
              ? '{"text_model_installed":true,"vision_model_installed":true}'
              : '{"fields":[],"extras":[]}',
          200);
    })),
        throwsA(isA<ReportProcessorException>().having(
            (e) => e.message, 'message', contains('No readable lab values'))));
  });
  test('lost USB connection during upload gives retry instructions', () async {
    await expectLater(scan(MockClient((request) async {
      if (request.method == 'GET') {
        return http.Response(
            '{"text_model_installed":true,"vision_model_installed":true}', 200);
      }
      throw http.ClientException('Socket closed');
    })),
        throwsA(isA<ReportProcessorException>().having(
            (e) => e.message,
            'message',
            contains('Connection to the report processor was lost'))));
  });
}
