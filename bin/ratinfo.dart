// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:io';

import 'package:html/dom.dart';
import 'package:html/parser.dart';

class TopDocument {
  String label;
  String url;
  TopDocument({
    required this.label,
    required this.url,
  });
}

class Top {
  String label;
  String title;
  String? id;
  List<TopDocument> documents = [];
  Top({
    required this.label,
    required this.title,
  });
}

parseSitzung() {
  String content = File("data/ratsinfo.html").readAsStringSync();
  Document document = parse(content);

  for (Element topTr in document.getElementsByClassName("smc-t-r-l")) {
    for (Element topNum in topTr.getElementsByClassName("tofnum")) {
      print(topNum.text);
      if (topTr.getElementsByClassName("tobetr").isNotEmpty) {
        Element titleElement = topTr.getElementsByClassName("tobetr").first;
        print(titleElement.text);
      } 
      if (topTr.getElementsByClassName("tovo").isNotEmpty) {
        Element vorlageElement = topTr.getElementsByClassName("tovo").first;
        print(vorlageElement.text);
      } 
      if (topTr.getElementsByClassName("sidocs").isNotEmpty) {
        Element vorlageElement = topTr.getElementsByClassName("sidocs").first;
        print(vorlageElement.text);
      } 


    }
  }
}

void main(List<String> arguments) {
  parseSitzung();
}
