import 'package:html/parser.dart' as htmlparser;
import 'package:http/http.dart' as http;

Future<String> getBarcodeInformation(String barcode) async {
  var url = Uri.parse('https://www.beepscan.com/barcode/$barcode');
  var response = await http.get(url);
  var doc = htmlparser.parse(response.body);
  var name = doc.getElementsByClassName('container');
  return name[0].getElementsByTagName('b')[0].innerHtml;
}
