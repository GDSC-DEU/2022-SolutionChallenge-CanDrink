import 'package:html/parser.dart' as htmlparser;
import 'package:http/http.dart' as http;

Future<String?> getProductNameFromBarcode(String barcode) async {
  final url = Uri.parse('https://www.beepscan.com/barcode/$barcode');
  final response = await http.get(url);
  final doc = htmlparser.parse(response.body);

  final name = doc.getElementsByClassName('container').elementAt(0).getElementsByTagName('b').elementAt(0).innerHtml;
  return name;
}
