import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MyBookApp());
}

class MyBookApp extends StatelessWidget {
  const MyBookApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Book Discovery',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: BookListScreen(),
    );
  }
}

class BookListScreen extends StatefulWidget {
  const BookListScreen({Key? key}) : super(key: key);

  @override
  _BookListScreenState createState() => _BookListScreenState();
}

class _BookListScreenState extends State<BookListScreen> {
  List books = [];
  int page = 1;
  bool isLoading = false;
  bool isError = false;
  String searchQuery = '';
  List favorites = [];

  @override
  void initState() {
    super.initState();
    fetchBooks();
  }

  Future<void> fetchBooks() async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
      isError = false;
    });

    try {
      final response =
      await http.get(Uri.parse('https://gutendex.com/books/?page=$page'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          books.addAll(data['results']);
          page++;
        });
      } else {
        throw Exception('Failed to load books');
      }
    } catch (e) {
      setState(() {
        isError = true;
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void toggleFavorite(Map book) {
    setState(() {
      if (favorites.contains(book)) {
        favorites.remove(book);
      } else {
        favorites.add(book);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Book Discovery'),
        actions: [
          IconButton(
            icon: Icon(Icons.favorite),
            tooltip: 'Liked Books',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LikedBooksScreen(favorites: favorites),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: BookSearchDelegate(books: books),
              );
            },
          ),
        ],
      ),
      body: isError
          ? Center(child: Text('Failed to load books. Please try again later.'))
          : GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.6,
        ),
        itemCount: books.length + 1,
        itemBuilder: (context, index) {
          if (index < books.length) {
            final book = books[index];
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BookDetailScreen(
                      book: book,
                      books: books,
                    ),
                  ),
                );
              },
              child: Card(
                elevation: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (book['formats']['image/jpeg'] != null)
                      Image.network(
                        book['formats']['image/jpeg'],
                        height: 150,
                        fit: BoxFit.cover,
                      )
                    else
                      Icon(Icons.book, size: 150),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        book['title'] ?? 'No Title',
                        style: TextStyle(fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        favorites.contains(book)
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: favorites.contains(book)
                            ? Colors.red
                            : null,
                      ),
                      onPressed: () => toggleFavorite(book),
                    ),
                  ],
                ),
              ),
            );
          } else {
            return isLoading
                ? Center(child: CircularProgressIndicator())
                : TextButton(
              onPressed: fetchBooks,
              child: Text('Load More'),
            );
          }
        },
      ),
    );
  }
}

class LikedBooksScreen extends StatelessWidget {
  final List favorites;

  const LikedBooksScreen({Key? key, required this.favorites}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Liked Books'),
      ),
      body: favorites.isEmpty
          ? Center(
        child: Text(
          'No liked books yet.',
          style: TextStyle(fontSize: 18),
        ),
      )
          : GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.6,
        ),
        itemCount: favorites.length,
        itemBuilder: (context, index) {
          final book = favorites[index];
          return Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (book['formats']['image/jpeg'] != null)
                  Image.network(
                    book['formats']['image/jpeg'],
                    height: 150,
                    fit: BoxFit.cover,
                  )
                else
                  Icon(Icons.book, size: 150),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    book['title'] ?? 'No Title',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class BookDetailScreen extends StatelessWidget {
  final Map book;
  final List books;

  const BookDetailScreen({Key? key, required this.book, required this.books})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authorNames = book['authors'] != null
        ? book['authors']
        .map((a) => a['name']?.replaceAll(',', '').trim())
        .join(' ')
        : 'Unknown';

    return Scaffold(
      appBar: AppBar(
        title: Text(book['title'] ?? 'No Title'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (book['formats']['image/jpeg'] != null)
              Center(
                child: Image.network(
                  book['formats']['image/jpeg'],
                  height: 200,
                ),
              ),
            SizedBox(height: 16),
            Text(
              'Title: ${book['title'] ?? 'No Title'}',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Author: $authorNames',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

class BookSearchDelegate extends SearchDelegate {
  final List books;

  BookSearchDelegate({required this.books});

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final filteredBooks = books.where((book) {
      final title = book['title']?.toLowerCase() ?? '';
      final authors = book['authors'] ?? [];
      final authorNames =
      authors.map((a) => a['name']?.toLowerCase() ?? '').join(' ');

      return title.contains(query.toLowerCase()) ||
          authorNames.contains(query.toLowerCase());
    }).toList();

    return ListView.builder(
      itemCount: filteredBooks.length,
      itemBuilder: (context, index) {
        final book = filteredBooks[index];
        return ListTile(
          title: Text(book['title'] ?? 'No Title'),
          subtitle: Text(
            'Author: ${book['authors']?.map((a) => a['name']).join(' ') ?? 'Unknown'}',
          ),
          onTap: () {
            close(context, null);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    BookDetailScreen(book: book, books: books),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return buildSuggestions(context);
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () => query = '',
      ),
    ];
  }
}