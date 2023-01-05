import 'package:dio/dio.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart';

List<String> getPages(Document document) {
  List<String> result = [];
  List<Element> liItems =
      document.getElementsByClassName("pager").first.children;
  for (Element li in liItems) {
    if (!li.classes.contains("next") &&
        !li.classes.contains("last") &&
        !li.classes.contains("current")) {
      List<Element> aElement = li.getElementsByTagName("a");
      if (aElement.isNotEmpty) {
        String link = aElement.first.attributes["href"]!;
        result.add(link);
      }
    }
  }
  return result;
}

String baseUrl = "https://www.gundelsheim.de";
String firstPage = "/rathaus-service/aktuelle-meldungen";
String channelId = "63b733f34f0c81661d73709a";

void run(Dio dio) async {
  RegExp regExp = RegExp("(\\d\\d)\\.(\\d\\d)\\.(\\d\\d\\d\\d)");

  List<Document> documents = [
    //parse(File("data/aktuelle-meldungen.html").readAsStringSync())
  ];

  print("loading first page");
  Response response = await dio.get(baseUrl + firstPage);
  if (response.statusCode == 200) {
    Document document = parse(response.data);
    documents.add(document);
    List<String> pages = getPages(document);
    for (String pageUrl in pages) {
      print("loading " + baseUrl + pageUrl);
      Response pageResponse = await dio.get(baseUrl + pageUrl);
      if (pageResponse.statusCode == 200) {
        documents.add(parse(pageResponse.data));
      }
    }
  }
  List<Map<String, dynamic>> contentItems = [];

  for (Document document in documents) {
    for (Element element in document.getElementsByClassName("record")) {
      Element title = element.getElementsByTagName("h3").first;
      Element description = element.getElementsByClassName("description").first;
      Element link = element.getElementsByClassName("button_continue").first;
      Element img = element.getElementsByClassName("teaserimage").first;
      Element pubDate = element.getElementsByClassName("creation").first;

      DateTime pubDateTime = DateTime.now();
      RegExpMatch? regExpMatch = regExp.firstMatch(pubDate.text);
      if (regExpMatch != null && regExpMatch.groupCount >= 3) {
        pubDateTime = DateTime(int.parse(regExpMatch.group(3)!),
            int.parse(regExpMatch.group(2)!), int.parse(regExpMatch.group(1)!));
      }

      Map<String, dynamic> data = {
        "title": title.text.trim(),
        "link": "https://www.gundelsheim.de/${link.attributes["href"]}",
        "pubDate": pubDateTime.toIso8601String(),
        "author": "Gundelsheim",
        "content": description.text.trim(),
        "channelId": channelId
      };
      contentItems.add(data);
    }
  }

  for (Map<String, dynamic> data in contentItems) {
    print("sending item...");
    try {
      Response response =
          await dio.put("https://api.grundid.de/rss/item", data: data);
      print("status: ${response.statusCode}");
      print(response.data);
    } on DioError catch (_) {
      break;
    }
  }
}

void main(List<String> arguments) {
  run(Dio());
}
