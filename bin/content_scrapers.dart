import 'dart:io';

import 'package:dio/dio.dart';
import 'package:gradle_properties/gradle_properties.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart';

List<String> getPages(Document document) {
  List<String> result = [];
  List<Element> liItems =
      document.getElementsByClassName("pagination").first.children;
  for (Element li in liItems) {
    if (li.localName == "a") {
      String link = li.attributes["href"]!;
      result.add(link);
    }
  }
  return result;
}

void run(String configFile, Dio dio) async {
  GradleProperties? properties =
      await GradleProperties.fromFile(File(configFile));
  if (properties == null) {
    print("Missing config.properties");
  } else {
    try {
      String baseUrl = properties["baseUrl"]!;
      String firstPage = properties["firstPage"]!;
      String channelId = properties["channelId"]!;

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
        print("found " + pages.length.toString() + " additional pages");
        for (String pageUrl in pages) {
          print("loading " + baseUrl + pageUrl);
          Response pageResponse = await dio.get(baseUrl + pageUrl);
          if (pageResponse.statusCode == 200) {
            documents.add(parse(pageResponse.data));
          }
        }
      }

      print("found ${documents.length} pages to scrape");

      List<Map<String, dynamic>> contentItems = [];

      for (Document document in documents) {
        for (Element element
            in document.getElementsByClassName("hw_record__content")) {
          String title = element.getElementsByTagName("h3").isEmpty
              ? "Ohne Überschrift"
              : element.getElementsByTagName("h3").first.text;
          String description =
              element.getElementsByClassName("hw_record__teasertext").isEmpty
                  ? "keine Beschreibung"
                  : element
                      .getElementsByClassName("hw_record__teasertext")
                      .first
                      .text;
          Element link =
              element.getElementsByClassName("hw_record__more__show").first;
          //Element img = element.getElementsByClassName("teaserimage").first;
          Element pubDate =
              element.getElementsByClassName("hw_record__value__text").first;

          DateTime pubDateTime = DateTime.now();
          RegExpMatch? regExpMatch = regExp.firstMatch(pubDate.text);
          if (regExpMatch != null && regExpMatch.groupCount >= 3) {
            pubDateTime = DateTime(
                int.parse(regExpMatch.group(3)!),
                int.parse(regExpMatch.group(2)!),
                int.parse(regExpMatch.group(1)!));
          }

          Map<String, dynamic> data = {
            "title": title.trim(),
            "link": "https://www.gundelsheim.de/${link.attributes["href"]}",
            "pubDate": pubDateTime.toIso8601String(),
            "author": "Gundelsheim",
            "content": description.trim(),
            "channelId": channelId
          };
          //print(data);
          contentItems.add(data);
        }
      }

      int sucessfull = 0;
      // TODO log errors while uploading data
      for (Map<String, dynamic> data in contentItems) {
        try {
          Response response =
              await dio.put(properties["storageUrl"]!, data: data);
          if (response.statusCode == 200) {
            sucessfull++;
          } else {
            print("Error: " + response.toString());
          }
        } on DioError catch (e) {
          print("Error: " + e.toString());
          break;
        }
      }
      if (DateTime.now().weekday == DateTime.saturday) {
        Map<String, dynamic> confirmNotification = {
          "subject": "$sucessfull von ${contentItems.length} Seiten gescraped.",
          "message":
              "Aktuelle Nachrichten:\n\n${contentItems.map((e) => e["title"]).join("\n")}"
        };

        await dio.post(properties["notificationUrl"]!,
            data: confirmNotification);
      }
    } catch (e, s) {
      print(e);
      print(s);
      Map<String, dynamic> confirmNotification = {
        "subject": "Fehler beim Scraper.",
        "message": "Fehler: " + e.toString() + "\n" + s.toString()
      };

      await dio.post(properties["notificationUrl"]!, data: confirmNotification);
    }
  }
}

void main(List<String> arguments) {
  run(arguments.first, Dio());
}
