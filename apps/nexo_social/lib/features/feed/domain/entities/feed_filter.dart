/// The tabs above the feed.
///
/// A real value rather than a chip index: the selected chip, the query the
/// cubit runs and the analytics label all have to agree, and an int agrees
/// with nothing.
enum FeedFilter {
  forYou('Para ti'),
  following('Siguiendo'),
  live('En vivo'),
  communities('Comunidades');

  const FeedFilter(this.label);

  /// User-facing. Spanish is the only locale this app ships today; when a
  /// second one arrives this becomes a lookup against the generated
  /// localisations and the enum keeps only its name.
  final String label;

  /// The large heading the screen shows for this filter.
  String get title => this == FeedFilter.forYou ? 'Para ti' : label;
}
