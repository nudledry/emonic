import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class BeritaScreen extends StatefulWidget {
  final String? userName;

  const BeritaScreen({super.key, this.userName});

  @override
  _BeritaScreenState createState() => _BeritaScreenState();
}

class _BeritaScreenState extends State<BeritaScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String _selectedCategory = 'Semua Kategori';
  String _searchQuery = '';
  List<NewsArticle> _newsArticles = [];
  List<NewsArticle> _allNewsArticles = []; // Store all articles
  List<NewsArticle> _breakingNews = [];
  List<String> _favoriteArticleIds = [];
  bool _isLoading = true;
  late String _userId;

  final List<String> _activeTags = [];

  final List<String> _availableTags = [
    'Energi Terbarukan',
    'Tips Hemat Energi',
    'Kebijakan Energi Terbarukan',
    'Dasar Energi',
  ];

  @override
  void initState() {
    super.initState();
    _initializeUser();
  }

  Future<void> _initializeUser() async {
    User? user = _auth.currentUser;
    if (user != null) {
      _userId = user.uid;
    } else {
      _userId = 'guest_user';
    }
    _fetchFavorites();
    _listenToBreakingNews();
  }

  Future<void> _fetchFavorites() async {
    try {
      final favoritesDoc = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('favorites')
          .get();
      setState(() => _favoriteArticleIds =
          favoritesDoc.docs.map((doc) => doc.id).toList());
      _fetchNewsArticles();
    } catch (e) {
      print('Error fetching favorites: $e');
      _fetchNewsArticles();
    }
  }

  void _listenToBreakingNews() {
    _firestore
        .collection('news')
        .where('isBreaking', isEqualTo: true)
        .where('createdAt',
            isGreaterThan: Timestamp.fromDate(
                DateTime.now().subtract(Duration(hours: 24))))
        .orderBy('createdAt', descending: true)
        .limit(3)
        .snapshots()
        .listen((snapshot) {
      List<NewsArticle> breakingArticles = snapshot.docs
          .map((doc) =>
              NewsArticle.fromFirestore(doc, favoriteIds: _favoriteArticleIds))
          .toList();

      if (breakingArticles.isNotEmpty &&
          breakingArticles.length > _breakingNews.length) {
        _showBreakingNewsNotification(breakingArticles.first);
      }

      setState(() {
        _breakingNews = breakingArticles;
      });
    });
  }

  void _showBreakingNewsNotification(NewsArticle article) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          contentPadding: EdgeInsets.zero,
          content: Container(
            width: double.maxFinite,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              gradient: LinearGradient(
                colors: [Colors.red, Colors.redAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.campaign, color: Colors.white, size: 24),
                      SizedBox(width: 8),
                      Text(
                        'BREAKING NEWS',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Spacer(),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(15),
                      bottomRight: Radius.circular(15),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Add image to breaking news dialog
                      if (article.imageUrl.isNotEmpty) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            article.imageUrl,
                            height: 120,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 120,
                                color: Colors.grey[300],
                                child: Icon(Icons.image_not_supported,
                                    size: 40, color: Colors.grey[600]),
                              );
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                height: 120,
                                color: Colors.grey[200],
                                child:
                                    Center(child: CircularProgressIndicator()),
                              );
                            },
                          ),
                        ),
                        SizedBox(height: 12),
                      ],
                      Text(
                        article.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        article.content,
                        style: TextStyle(fontSize: 14, color: Colors.black87),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text('Tutup'),
                          ),
                          SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              _showFullArticle(article);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            child: Text('Baca'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showFullArticle(NewsArticle article) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ArticleDetailScreen(
          article: article,
          userId: _userId,
          onFavoriteToggle: () => _toggleFavorite(article),
          onLikeToggle: () => _toggleLike(article),
          onRating: (rating) => _rateArticle(article, rating),
        ),
      ),
    );
  }

  // FIXED: Separated fetch all articles and apply filters
  Future<void> _fetchNewsArticles() async {
    setState(() => _isLoading = true);
    try {
      // Always fetch all articles first
      QuerySnapshot querySnapshot = await _firestore
          .collection('news')
          .orderBy('createdAt', descending: true)
          .get();

      List<NewsArticle> allArticles = querySnapshot.docs
          .map((doc) =>
              NewsArticle.fromFirestore(doc, favoriteIds: _favoriteArticleIds))
          .toList();

      setState(() {
        _allNewsArticles = allArticles;
        _isLoading = false;
      });

      // Apply filters after fetching
      _applyFilters();
    } catch (e) {
      print('Error fetching news articles: $e');
      setState(() => _isLoading = false);
    }
  }

  // FIXED: New method to apply filters
  void _applyFilters() {
    List<NewsArticle> filteredArticles = List.from(_allNewsArticles);

    // Apply category filter
    if (_selectedCategory != 'Semua Kategori') {
      filteredArticles = filteredArticles
          .where((article) => article.category == _selectedCategory)
          .toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filteredArticles = filteredArticles
          .where((article) =>
              article.title
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ||
              article.content
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ||
              article.category
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()))
          .toList();
    }

    setState(() {
      _newsArticles = filteredArticles;
    });
  }

  // FIXED: Update favorite status in all article lists
  Future<void> _toggleFavorite(NewsArticle article) async {
    final favoriteRef = _firestore
        .collection('users')
        .doc(_userId)
        .collection('favorites')
        .doc(article.id);

    // Update the favorite status locally first
    setState(() {
      article.isFavorite = !article.isFavorite;
      if (article.isFavorite) {
        _favoriteArticleIds.add(article.id);
      } else {
        _favoriteArticleIds.remove(article.id);
      }

      // FIXED: Update the favorite status in all lists
      _updateArticleFavoriteStatus(article.id, article.isFavorite);
    });

    try {
      if (article.isFavorite) {
        await favoriteRef.set(article.toMap());
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Artikel ditambahkan ke favorit')));
      } else {
        await favoriteRef.delete();
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Artikel dihapus dari favorit')));
      }
    } catch (e) {
      print('Error toggling favorite: $e');
      // Revert the local changes if the operation fails
      setState(() {
        article.isFavorite = !article.isFavorite;
        if (article.isFavorite) {
          _favoriteArticleIds.add(article.id);
        } else {
          _favoriteArticleIds.remove(article.id);
        }

        _updateArticleFavoriteStatus(article.id, article.isFavorite);
      });
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengubah status favorit')));
    }
  }

  // FIXED: New method to update favorite status across all lists
  void _updateArticleFavoriteStatus(String articleId, bool isFavorite) {
    // Update in _allNewsArticles
    for (int i = 0; i < _allNewsArticles.length; i++) {
      if (_allNewsArticles[i].id == articleId) {
        _allNewsArticles[i].isFavorite = isFavorite;
        break;
      }
    }

    // Update in _newsArticles
    for (int i = 0; i < _newsArticles.length; i++) {
      if (_newsArticles[i].id == articleId) {
        _newsArticles[i].isFavorite = isFavorite;
        break;
      }
    }

    // Update in _breakingNews
    for (int i = 0; i < _breakingNews.length; i++) {
      if (_breakingNews[i].id == articleId) {
        _breakingNews[i].isFavorite = isFavorite;
        break;
      }
    }
  }

  // FIXED: Update like status in all article lists
  Future<void> _toggleLike(NewsArticle article) async {
    final articleRef = _firestore.collection('news').doc(article.id);
    final userLikeRef = _firestore
        .collection('news')
        .doc(article.id)
        .collection('likes')
        .doc(_userId);

    try {
      await _firestore.runTransaction((transaction) async {
        final articleDoc = await transaction.get(articleRef);
        final userLikeDoc = await transaction.get(userLikeRef);

        if (!articleDoc.exists) return;

        int currentLikes = articleDoc.data()?['likes'] ?? 0;
        bool userHasLiked = userLikeDoc.exists;

        if (userHasLiked) {
          // Unlike
          transaction.update(articleRef, {'likes': currentLikes - 1});
          transaction.delete(userLikeRef);
          setState(() {
            _updateArticleLikeStatus(article.id, currentLikes - 1, false);
          });
        } else {
          // Like
          transaction.update(articleRef, {'likes': currentLikes + 1});
          transaction.set(userLikeRef, {
            'userId': _userId,
            'timestamp': FieldValue.serverTimestamp(),
          });
          setState(() {
            _updateArticleLikeStatus(article.id, currentLikes + 1, true);
          });
        }
      });
    } catch (e) {
      print('Error toggling like: $e');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Gagal memberikan like')));
    }
  }

  // FIXED: New method to update like status across all lists
  void _updateArticleLikeStatus(String articleId, int likes, bool isLiked) {
    // Update in _allNewsArticles
    for (int i = 0; i < _allNewsArticles.length; i++) {
      if (_allNewsArticles[i].id == articleId) {
        _allNewsArticles[i].likes = likes;
        _allNewsArticles[i].isLiked = isLiked;
        break;
      }
    }

    // Update in _newsArticles
    for (int i = 0; i < _newsArticles.length; i++) {
      if (_newsArticles[i].id == articleId) {
        _newsArticles[i].likes = likes;
        _newsArticles[i].isLiked = isLiked;
        break;
      }
    }

    // Update in _breakingNews
    for (int i = 0; i < _breakingNews.length; i++) {
      if (_breakingNews[i].id == articleId) {
        _breakingNews[i].likes = likes;
        _breakingNews[i].isLiked = isLiked;
        break;
      }
    }
  }

  Future<void> _rateArticle(NewsArticle article, int rating) async {
    final ratingRef = _firestore
        .collection('news')
        .doc(article.id)
        .collection('ratings')
        .doc(_userId);
    final articleRef = _firestore.collection('news').doc(article.id);

    try {
      await _firestore.runTransaction((transaction) async {
        final ratingDoc = await transaction.get(ratingRef);
        final articleDoc = await transaction.get(articleRef);

        if (!articleDoc.exists) return;

        Map<String, dynamic> articleData =
            articleDoc.data() as Map<String, dynamic>;
        int totalRatings = articleData['totalRatings'] ?? 0;
        double averageRating = articleData['averageRating']?.toDouble() ?? 0.0;

        if (ratingDoc.exists) {
          // Update existing rating
          int oldRating = ratingDoc.data()?['rating'] ?? 0;
          double newAverage =
              ((averageRating * totalRatings) - oldRating + rating) /
                  totalRatings;

          transaction.update(articleRef, {'averageRating': newAverage});
          transaction.update(ratingRef, {
            'rating': rating,
            'timestamp': FieldValue.serverTimestamp(),
          });
        } else {
          // New rating
          double newAverage =
              ((averageRating * totalRatings) + rating) / (totalRatings + 1);

          transaction.update(articleRef, {
            'averageRating': newAverage,
            'totalRatings': totalRatings + 1,
          });
          transaction.set(ratingRef, {
            'userId': _userId,
            'rating': rating,
            'timestamp': FieldValue.serverTimestamp(),
          });
        }
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Rating berhasil diberikan')));
    } catch (e) {
      print('Error rating article: $e');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Gagal memberikan rating')));
    }
  }

  void _showRatingDialog(NewsArticle article) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Beri Rating'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Berikan rating untuk artikel ini:'),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      Icons.star,
                      color: Colors.amber,
                      size: 32,
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      _rateArticle(article, index + 1);
                    },
                  );
                }),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Batal'),
            ),
          ],
        );
      },
    );
  }

  // FIXED: Updated tag methods to use _applyFilters instead of _fetchNewsArticles
  void _addTag(String tag) {
    if (!_activeTags.contains(tag)) {
      setState(() {
        _activeTags.add(tag);
        _selectedCategory = tag;
      });
      _applyFilters(); // Use _applyFilters instead of _fetchNewsArticles
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _activeTags.remove(tag);
      if (_activeTags.isEmpty) {
        _selectedCategory = 'Semua Kategori';
      } else {
        _selectedCategory = _activeTags.last;
      }
    });
    _applyFilters(); // Use _applyFilters instead of _fetchNewsArticles
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('EEEE d, y').format(DateTime.now());
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 16),
              _buildHeader(formattedDate),
              SizedBox(height: 24),
              if (_breakingNews.isNotEmpty) ...[
                _buildBreakingNewsSection(),
                SizedBox(height: 16),
              ],
              _buildNewsTitle(),
              SizedBox(height: 16),
              _buildSearchBar(),
              SizedBox(height: 12),
              _buildCategoryDropdown(),
              SizedBox(height: 16),
              _buildRecommendationTags(),
              SizedBox(height: 16),
              // FIXED: Show current filter status
              _buildFilterStatus(),
              SizedBox(height: 8),
              Expanded(
                child: _isLoading
                    ? Center(child: CircularProgressIndicator())
                    : _newsArticles.isEmpty
                        ? _buildEmptyState()
                        : _buildNewsList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // FIXED: New method to show current filter status
  Widget _buildFilterStatus() {
    if (_selectedCategory == 'Semua Kategori' && _searchQuery.isEmpty) {
      return SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.filter_list, size: 16, color: Colors.blue.shade700),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              _buildFilterText(),
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = 'Semua Kategori';
                _searchQuery = '';
                _activeTags.clear();
              });
              _applyFilters();
            },
            child: Icon(Icons.close, size: 16, color: Colors.blue.shade700),
          ),
        ],
      ),
    );
  }

  String _buildFilterText() {
    List<String> filters = [];

    if (_selectedCategory != 'Semua Kategori') {
      filters.add('Kategori: $_selectedCategory');
    }

    if (_searchQuery.isNotEmpty) {
      filters.add('Pencarian: "$_searchQuery"');
    }

    return filters.join(' • ');
  }

  // FIXED: Better empty state
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: 16),
          Text(
            'Tidak ada berita ditemukan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            _selectedCategory != 'Semua Kategori' || _searchQuery.isNotEmpty
                ? 'Coba ubah filter atau kata kunci pencarian'
                : 'Belum ada berita yang tersedia',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBreakingNewsSection() {
    return Container(
      height: 160, // Increased height to accommodate images
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.campaign, color: Colors.red, size: 20),
              SizedBox(width: 8),
              Text(
                'BREAKING NEWS',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _breakingNews.length,
              itemBuilder: (context, index) {
                final article = _breakingNews[index];
                return Container(
                  width: 320, // Increased width to accommodate images
                  margin: EdgeInsets.only(right: 12),
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: GestureDetector(
                    onTap: () => _showFullArticle(article),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image section
                        if (article.imageUrl.isNotEmpty) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              article.imageUrl,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 80,
                                  height: 80,
                                  color: Colors.grey[300],
                                  child: Icon(Icons.image_not_supported,
                                      size: 30, color: Colors.grey[600]),
                                );
                              },
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  width: 80,
                                  height: 80,
                                  color: Colors.grey[200],
                                  child: Center(
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2)),
                                );
                              },
                            ),
                          ),
                          SizedBox(width: 12),
                        ],
                        // Text content
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                article.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 4),
                              Expanded(
                                child: Text(
                                  article.content,
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.black87),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(String formattedDate) {
    final String displayName = widget.userName ?? 'Pengguna';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Hi $displayName',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        Text(formattedDate,
            style: TextStyle(color: Colors.grey[600], fontSize: 14)),
      ],
    );
  }

  Widget _buildNewsTitle() => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(8)),
                child: Icon(Icons.menu_book, color: Colors.white),
              ),
              SizedBox(width: 8),
              Text('NEWS',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          IconButton(
            icon: Icon(Icons.bookmark, color: Colors.black),
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => FavoritesScreen(userId: _userId))),
          ),
        ],
      );

  Widget _buildSearchBar() => Container(
        height: 40,
        decoration: BoxDecoration(
            color: Color(0xFFE6F0FF), borderRadius: BorderRadius.circular(20)),
        child: TextField(
          decoration: InputDecoration(
            hintText: 'Cari',
            prefixIcon: Icon(Icons.search, color: Colors.grey),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          ),
          onChanged: (value) {
            setState(() => _searchQuery = value);
            _applyFilters(); // FIXED: Use _applyFilters instead of _fetchNewsArticles
          },
        ),
      );

  Widget _buildCategoryDropdown() {
    const categories = [
      'Semua Kategori',
      'Dasar Energi',
      'Energi Terbarukan',
      'Tips Hemat Energi',
      'Kebijakan Energi Terbarukan',
    ];
    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        builder: (context) => ListView.builder(
          shrinkWrap: true,
          itemCount: categories.length,
          itemBuilder: (context, index) => ListTile(
            title: Text(categories[index]),
            trailing: _selectedCategory == categories[index]
                ? Icon(Icons.check, color: Colors.blue)
                : null,
            onTap: () {
              setState(() {
                _selectedCategory = categories[index];
                _activeTags.clear();
                if (categories[index] != 'Semua Kategori') {
                  _activeTags.add(categories[index]);
                }
              });
              _applyFilters(); // FIXED: Use _applyFilters instead of _fetchNewsArticles
              Navigator.pop(context);
            },
          ),
        ),
      ),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _selectedCategory,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            Icon(Icons.keyboard_arrow_down, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationTags() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rekomendasi Tag',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _availableTags.map((tag) {
            final isActive = _activeTags.contains(tag);
            return GestureDetector(
              onTap: () => isActive ? _removeTag(tag) : _addTag(tag),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isActive ? Colors.blue : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  tag,
                  style: TextStyle(
                    color: isActive ? Colors.white : Colors.black87,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildNewsList() {
    return RefreshIndicator(
      onRefresh: _fetchNewsArticles,
      child: ListView.builder(
        physics: AlwaysScrollableScrollPhysics(),
        itemCount: _newsArticles.length,
        itemBuilder: (context, index) {
          final article = _newsArticles[index];
          return _buildNewsCard(article);
        },
      ),
    );
  }

  Widget _buildNewsCard(NewsArticle article) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showFullArticle(article),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with category and date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(article.category),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      article.category,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    _formatDate(article.createdAt),
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),

              // Content
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Text content
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          article.title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 8),
                        Text(
                          article.content,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 12,
                            height: 1.4,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Image
                  if (article.imageUrl.isNotEmpty) ...[
                    SizedBox(width: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        article.imageUrl,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 80,
                            height: 80,
                            color: Colors.grey[300],
                            child: Icon(
                              Icons.image_not_supported,
                              size: 30,
                              color: Colors.grey[600],
                            ),
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            width: 80,
                            height: 80,
                            color: Colors.grey[200],
                            child: Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),

              SizedBox(height: 12),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      // Like button
                      GestureDetector(
                        onTap: () => _toggleLike(article),
                        child: Row(
                          children: [
                            Icon(
                              article.isLiked
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: article.isLiked ? Colors.red : Colors.grey,
                              size: 18,
                            ),
                            SizedBox(width: 4),
                            Text(
                              '${article.likes}',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(width: 16),

                      // Rating
                      GestureDetector(
                        onTap: () => _showRatingDialog(article),
                        child: Row(
                          children: [
                            Icon(Icons.star, color: Colors.amber, size: 18),
                            SizedBox(width: 4),
                            Text(
                              article.averageRating > 0
                                  ? article.averageRating.toStringAsFixed(1)
                                  : '0.0',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Favorite button
                  GestureDetector(
                    onTap: () => _toggleFavorite(article),
                    child: Icon(
                      article.isFavorite
                          ? Icons.bookmark
                          : Icons.bookmark_border,
                      color: article.isFavorite ? Colors.blue : Colors.grey,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Dasar Energi':
        return Colors.green;
      case 'Energi Terbarukan':
        return Colors.blue;
      case 'Tips Hemat Energi':
        return Colors.orange;
      case 'Kebijakan Energi Terbarukan':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(Timestamp timestamp) {
    final DateTime dateTime = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}h yang lalu';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}j yang lalu';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m yang lalu';
    } else {
      return 'Baru saja';
    }
  }
}

// NewsArticle model class
class NewsArticle {
  final String id;
  final String title;
  final String content;
  final String category;
  final String imageUrl;
  final Timestamp createdAt;
  final String author;
  final bool isBreaking;
  int likes;
  bool isFavorite;
  bool isLiked;
  double averageRating;
  int totalRatings;

  NewsArticle({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.imageUrl,
    required this.createdAt,
    required this.author,
    this.isBreaking = false,
    this.likes = 0,
    this.isFavorite = false,
    this.isLiked = false,
    this.averageRating = 0.0,
    this.totalRatings = 0,
  });

  factory NewsArticle.fromFirestore(DocumentSnapshot doc,
      {List<String> favoriteIds = const []}) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return NewsArticle(
      id: doc.id,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      category: data['category'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      author: data['author'] ?? '',
      isBreaking: data['isBreaking'] ?? false,
      likes: data['likes'] ?? 0,
      isFavorite: favoriteIds.contains(doc.id),
      isLiked: false, // This should be fetched separately
      averageRating: (data['averageRating'] ?? 0.0).toDouble(),
      totalRatings: data['totalRatings'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'category': category,
      'imageUrl': imageUrl,
      'createdAt': createdAt,
      'author': author,
      'isBreaking': isBreaking,
      'likes': likes,
      'averageRating': averageRating,
      'totalRatings': totalRatings,
    };
  }
}

// Placeholder screens that need to be implemented
class ArticleDetailScreen extends StatelessWidget {
  final NewsArticle article;
  final String userId;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onLikeToggle;
  final Function(int) onRating;

  const ArticleDetailScreen({
    Key? key,
    required this.article,
    required this.userId,
    required this.onFavoriteToggle,
    required this.onLikeToggle,
    required this.onRating,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detail Artikel'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (article.imageUrl.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  article.imageUrl,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
              SizedBox(height: 16),
            ],
            Text(
              article.title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Oleh ${article.author} • ${DateFormat('dd MMM yyyy').format(article.createdAt.toDate())}',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
            SizedBox(height: 16),
            Text(
              article.content,
              style: TextStyle(
                fontSize: 16,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FavoritesScreen extends StatefulWidget {
  final String userId;

  const FavoritesScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _FavoritesScreenState createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<NewsArticle> _favoriteArticles = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedCategory = 'Semua Kategori';

  @override
  void initState() {
    super.initState();
    _fetchFavoriteArticles();
  }

  Future<void> _fetchFavoriteArticles() async {
    setState(() => _isLoading = true);

    try {
      // Get favorite article IDs
      final favoritesSnapshot = await _firestore
          .collection('users')
          .doc(widget.userId)
          .collection('favorites')
          .get();

      if (favoritesSnapshot.docs.isEmpty) {
        setState(() {
          _favoriteArticles = [];
          _isLoading = false;
        });
        return;
      }

      // Get the actual articles from favorites collection
      List<NewsArticle> articles = [];
      for (var doc in favoritesSnapshot.docs) {
        try {
          final articleData = doc.data();
          final article = NewsArticle(
            id: doc.id,
            title: articleData['title'] ?? '',
            content: articleData['content'] ?? '',
            category: articleData['category'] ?? '',
            imageUrl: articleData['imageUrl'] ?? '',
            createdAt: articleData['createdAt'] ?? Timestamp.now(),
            author: articleData['author'] ?? '',
            isBreaking: articleData['isBreaking'] ?? false,
            likes: articleData['likes'] ?? 0,
            isFavorite: true, // Always true in favorites
            averageRating: (articleData['averageRating'] ?? 0.0).toDouble(),
            totalRatings: articleData['totalRatings'] ?? 0,
          );
          articles.add(article);
        } catch (e) {
          print('Error parsing favorite article: $e');
        }
      }

      // Sort by creation date (newest first)
      articles.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      setState(() {
        _favoriteArticles = articles;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching favorite articles: $e');
      setState(() => _isLoading = false);
      _showErrorSnackBar('Gagal memuat artikel favorit');
    }
  }

  List<NewsArticle> get _filteredArticles {
    List<NewsArticle> filtered = _favoriteArticles;

    // Apply category filter
    if (_selectedCategory != 'Semua Kategori') {
      filtered = filtered
          .where((article) => article.category == _selectedCategory)
          .toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((article) =>
              article.title
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ||
              article.content
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ||
              article.category
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()))
          .toList();
    }

    return filtered;
  }

  Future<void> _removeFavorite(NewsArticle article) async {
    // Show confirmation dialog
    final confirmed = await _showConfirmationDialog(
      'Hapus dari Favorit',
      'Apakah Anda yakin ingin menghapus "${article.title}" dari favorit?',
    );

    if (!confirmed) return;

    try {
      await _firestore
          .collection('users')
          .doc(widget.userId)
          .collection('favorites')
          .doc(article.id)
          .delete();

      setState(() {
        _favoriteArticles.removeWhere((a) => a.id == article.id);
      });

      _showSuccessSnackBar('Artikel dihapus dari favorit');
    } catch (e) {
      print('Error removing favorite: $e');
      _showErrorSnackBar('Gagal menghapus artikel dari favorit');
    }
  }

  Future<void> _clearAllFavorites() async {
    if (_favoriteArticles.isEmpty) return;

    final confirmed = await _showConfirmationDialog(
      'Hapus Semua Favorit',
      'Apakah Anda yakin ingin menghapus semua artikel favorit?',
    );

    if (!confirmed) return;

    try {
      final batch = _firestore.batch();
      final favoritesRef = _firestore
          .collection('users')
          .doc(widget.userId)
          .collection('favorites');

      for (var article in _favoriteArticles) {
        batch.delete(favoritesRef.doc(article.id));
      }

      await batch.commit();

      setState(() {
        _favoriteArticles.clear();
      });

      _showSuccessSnackBar('Semua artikel favorit telah dihapus');
    } catch (e) {
      print('Error clearing favorites: $e');
      _showErrorSnackBar('Gagal menghapus semua favorit');
    }
  }

  Future<bool> _showConfirmationDialog(String title, String content) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(title),
              content: Text(content),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Hapus'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showFullArticle(NewsArticle article) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ArticleDetailScreen(
          article: article,
          userId: widget.userId,
          onFavoriteToggle: () => _removeFavorite(article),
          onLikeToggle: () {}, // Like functionality can be added if needed
          onRating: (rating) {}, // Rating functionality can be added if needed
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredArticles = _filteredArticles;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Artikel Favorit'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          if (_favoriteArticles.isNotEmpty)
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'clear_all':
                    _clearAllFavorites();
                    break;
                  case 'refresh':
                    _fetchFavoriteArticles();
                    break;
                }
              },
              itemBuilder: (BuildContext context) => [
                PopupMenuItem<String>(
                  value: 'refresh',
                  child: Row(
                    children: [
                      Icon(Icons.refresh, size: 20),
                      SizedBox(width: 8),
                      Text('Refresh'),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'clear_all',
                  child: Row(
                    children: [
                      Icon(Icons.delete_sweep, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Hapus Semua', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _favoriteArticles.isEmpty
              ? _buildEmptyState()
              : Column(
                  children: [
                    _buildSearchAndFilter(),
                    if (filteredArticles.isEmpty &&
                        (_searchQuery.isNotEmpty ||
                            _selectedCategory != 'Semua Kategori'))
                      Expanded(child: _buildNoResultsState())
                    else
                      Expanded(child: _buildFavoritesList(filteredArticles)),
                  ],
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bookmark_border,
              size: 80,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: 16),
            Text(
              'Belum Ada Artikel Favorit',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Artikel yang Anda tandai sebagai favorit akan muncul di sini',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Jelajahi Artikel'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 60,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: 16),
            Text(
              'Tidak Ada Hasil',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Coba ubah kata kunci pencarian atau filter kategori',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          // Search bar
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: Color(0xFFE6F0FF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Cari artikel favorit...',
                prefixIcon: Icon(Icons.search, color: Colors.grey),
                border: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),
          SizedBox(height: 12),

          // Category filter
          Row(
            children: [
              Text(
                'Kategori: ',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: _showCategoryBottomSheet,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _selectedCategory,
                          style: TextStyle(fontSize: 14),
                        ),
                        Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Stats
          if (_favoriteArticles.isNotEmpty) ...[
            SizedBox(height: 8),
            Text(
              'Total: ${_favoriteArticles.length} artikel • Ditampilkan: ${_filteredArticles.length}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showCategoryBottomSheet() {
    final categories = [
      'Semua Kategori',
      'Dasar Energi',
      'Energi Terbarukan',
      'Tips Hemat Energi',
      'Kebijakan Energi Terbarukan',
    ];

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(16),
              child: Text(
                'Pilih Kategori',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ...categories
                .map((category) => ListTile(
                      title: Text(category),
                      trailing: _selectedCategory == category
                          ? Icon(Icons.check, color: Colors.blue)
                          : null,
                      onTap: () {
                        setState(() => _selectedCategory = category);
                        Navigator.pop(context);
                      },
                    ))
                .toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoritesList(List<NewsArticle> articles) {
    return RefreshIndicator(
      onRefresh: _fetchFavoriteArticles,
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 16),
        itemCount: articles.length,
        itemBuilder: (context, index) {
          final article = articles[index];
          return _buildFavoriteCard(article);
        },
      ),
    );
  }

  Widget _buildFavoriteCard(NewsArticle article) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showFullArticle(article),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              if (article.imageUrl.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    article.imageUrl,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[300],
                        child: Icon(Icons.image_not_supported,
                            color: Colors.grey[600]),
                      );
                    },
                  ),
                ),
                SizedBox(width: 12),
              ],

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category and remove button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getCategoryColor(article.category),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            article.category,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _removeFavorite(article),
                          child: Icon(
                            Icons.bookmark,
                            color: Colors.red,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),

                    // Title
                    Text(
                      article.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),

                    // Content preview
                    Text(
                      article.content,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 8),

                    // Date and stats
                    Row(
                      children: [
                        Text(
                          _formatDate(article.createdAt),
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 10,
                          ),
                        ),
                        Spacer(),
                        if (article.likes > 0) ...[
                          Icon(Icons.favorite, color: Colors.red, size: 14),
                          SizedBox(width: 2),
                          Text(
                            '${article.likes}',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 10,
                            ),
                          ),
                          SizedBox(width: 8),
                        ],
                        if (article.averageRating > 0) ...[
                          Icon(Icons.star, color: Colors.amber, size: 14),
                          SizedBox(width: 2),
                          Text(
                            article.averageRating.toStringAsFixed(1),
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Dasar Energi':
        return Colors.green;
      case 'Energi Terbarukan':
        return Colors.blue;
      case 'Tips Hemat Energi':
        return Colors.orange;
      case 'Kebijakan Energi Terbarukan':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(Timestamp timestamp) {
    final DateTime dateTime = timestamp.toDate();
    return DateFormat('dd MMM yyyy').format(dateTime);
  }
}
