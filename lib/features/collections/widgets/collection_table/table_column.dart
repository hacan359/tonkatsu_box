/// Sortable / filterable columns of the collection table view.
enum TableColumn {
  name,
  type,
  platform,
  status,
  tag,
  rating,
  externalRating,
  year,
  added,
}

/// Width of the optional drag-handle column. Shared between header and rows
/// so they stay aligned when reorder mode is enabled.
const double kDragHandleWidth = 28.0;

/// Width of the optional select-all checkbox column.
const double kCheckboxColumnWidth = 40.0;

/// Thumbnail dimensions and corner radius used by both the row layout and
/// the header spacer that keeps columns aligned.
const double kThumbWidth = 48.0;
const double kThumbHeight = 64.0;
const double kThumbRadius = 6.0;

