import 'package:flutter/material.dart';

class TugasSearchDelegate extends SearchDelegate {
  final List<Map<String, String>> tugasList;

  TugasSearchDelegate(this.tugasList);

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    List<Map<String, String>> results = tugasList
        .where(
          (task) => task['tugas']!.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(results[index]['tugas']!),
          subtitle: Text(
            "Mahasiswa: ${results[index]['mahasiswa']}\nTanggal: ${results[index]['tanggal']}",
          ),
          onTap: () {
            close(context, results[index]);
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    List<Map<String, String>> suggestions = tugasList
        .where(
          (task) => task['tugas']!.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(suggestions[index]['tugas']!),
          subtitle: Text("Mahasiswa: ${suggestions[index]['mahasiswa']}"),
          onTap: () {
            query = suggestions[index]['tugas']!;
            showResults(context);
          },
        );
      },
    );
  }
}
