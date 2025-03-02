class SearchEngine {
  final String name;
  final String description;
  final String url;

  const SearchEngine({
    required this.name,
    required this.description,
    required this.url,
  });
}

const List<SearchEngine> baseSearchEngines = [
  SearchEngine(
    name: 'DuckDuckGo',
    description: 'A search engine that doesn\'t track your actions.',
    url: 'https://duckduckgo.com/?q=',
  ),
  SearchEngine(
    name: 'Perplexity',
    description: 'An AI-powered search engine.',
    url: 'https://www.perplexity.ai/search?q=',
  ),
  SearchEngine(
    name: 'Google',
    description: 'The most popular search engine in the world.',
    url: 'https://www.google.com/search?q=',
  ),
  SearchEngine(
    name: 'Bing',
    description: 'Search engine by Microsoft.',
    url: 'https://www.bing.com/search?q=',
  ),
  SearchEngine(
    name: 'Yandex',
    description: 'A popular search engine in Russia.',
    url: 'https://ya.ru/search/?text=',
  ),
  SearchEngine(
    name: 'Baidu',
    description: 'The leading search engine in China.',
    url: 'https://www.baidu.com/s?wd=',
  ),
  SearchEngine(
    name: 'Ecosia',
    description: 'A search engine that plants trees with your search queries.',
    url: 'https://www.ecosia.org/search?q=',
  ),
];
