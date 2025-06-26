import 'dart:io';

import 'package:html/dom.dart';
import 'package:html/parser.dart';

parseSitzung() {
  String content = File("data/ratinfo.html").readAsStringSync();
  Document document = parse(content);

  for (Element topTr in document.getElementsByClassName("smc-t-r-l")) {
    for (Element topNum in topTr.getElementsByClassName("tofnum")) {
      print(topNum.text);
    }
  }
}

void main(List<String> arguments) {
  parseSitzung();
}
