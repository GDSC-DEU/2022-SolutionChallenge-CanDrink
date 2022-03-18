import 'package:html/parser.dart' as htmlparser;
import 'package:http/http.dart' as http;

Future<String?> getProductNameFromBarcode(String barcode) async {
  final url = Uri.parse('https://www.beepscan.com/barcode/$barcode');
  final response = await http.get(url);
  final doc = htmlparser.parse(response.body);

  try {
    var name = doc.getElementsByClassName('container')[0].getElementsByTagName('b')[0].innerHtml;
    return name;
  } catch (e) {
    return '상품 정보가 없습니다.';
  }
}
