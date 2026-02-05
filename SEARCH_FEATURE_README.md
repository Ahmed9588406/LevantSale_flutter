# Search Feature Implementation - Complete Guide

## Overview
A complete search feature has been added to the Flutter app that allows users to search for products using the endpoint:
```
{baseurl}/api/v1/listings/search?q=w&page=0&size=10&sortBy=date_asc
```

## Files Created/Modified

### 1. **Search Service** (`lib/api/home/search_service.dart`) - NEW
The service layer that handles API communication with the search endpoint.

**Key Features:**
- `searchListings()` - Main method to search listings
- Handles authentication headers and token management
- Returns a list of `Listing` objects
- Supports pagination (page, size)
- Supports sorting (sortBy parameter)

**Usage:**
```dart
final results = await SearchService.searchListings(
  query: 'phones',
  page: 0,
  size: 10,
  sortBy: 'date_asc',
);
```

### 2. **Search Results Screen** (`lib/home/screens/search_results_screen.dart`) - NEW
A complete UI screen for displaying search results.

**Features:**
- Beautiful search bar with clear button and search icon
- Back button for navigation
- Display search results in a card format showing:
  - Product image
  - Product title and category
  - Price with currency symbol
  - Location with icon
- Tap on any result to navigate to product details
- Pagination support with "Load More" button
- Loading states and error handling
- Empty state message when no results found

**Navigation Flow:**
- Search Query → SearchResultsScreen → ProductDetailsScreen

### 3. **Search Bar Widget** (`lib/home/widgets/search_bar_widget.dart`) - UPDATED
Made the search bar functional and connected to the search results screen.

**Changes:**
- Converted from StatelessWidget to StatefulWidget
- Added TextEditingController to handle user input
- Implemented onSubmitted callback to trigger search
- Added onTap handler to search icon
- Clears search field after navigation

## API Endpoint Used

```
GET {baseurl}/api/v1/listings/search?q={query}&page={page}&size={size}&sortBy={sortBy}
```

**Parameters:**
- `q` - Search query string
- `page` - Page number (0-indexed)
- `size` - Number of results per page (default: 10)
- `sortBy` - Sort order (date_asc, date_desc, etc.)

**Response Format:**
```json
{
  "content": [
    {
      "id": "123",
      "title": "Product Title",
      "description": "Product Description",
      "price": 99.99,
      "currency": { "code": "USD", "symbol": "$", "name": "US Dollar" },
      "location": "City Name",
      "imageUrls": ["url1", "url2"],
      "createdAt": "2024-01-01T00:00:00Z",
      "categoryName": "Category",
      "categoryId": "cat123",
      "userName": "User Name",
      "favorite": false
    }
  ]
}
```

## User Flow

1. **User enters search term** in the search bar at the top navbar
2. **User presses search icon or hits Enter**
3. **SearchResultsScreen is displayed** with:
   - The same search bar for refining search
   - List of matching products in card format
4. **User can:**
   - See product images, titles, prices, and locations
   - Tap any product to view full details
   - Scroll down to load more results
   - Perform a new search with a different query
   - Go back using the back button

## Data Models Used

### Listing Model (from `home_service.dart`)
```dart
class Listing {
  final String id;
  final String title;
  final String description;
  final double price;
  final ListingCurrency currency;
  final String location;
  final List<String> imageUrls;
  final String createdAt;
  final String categoryName;
  final String categoryId;
  final String userName;
  final String? userPhone;
  final String? condition;
  final bool? isFeatured;
  final bool favorite;
  final List<ListingAttribute>? attributes;
}
```

## UI Components

### SearchResultsScreen Components:
1. **Search Bar**
   - Back button
   - Search input field with clear button
   - Search button (green button)
   - Right-to-left (RTL) text direction

2. **Result Cards**
   - Product image (120x120 size)
   - Title and category
   - Price with currency
   - Location with pin icon
   - Tap to navigate to details

3. **Loading State**
   - Circular progress indicator

4. **Empty State**
   - Icon + message "لم يتم العثور على نتائج" (No results found)

5. **Error State**
   - Icon + error message display

6. **Pagination**
   - "Load More" button at bottom
   - Auto-loads next page when clicked

## Styling

- **Theme Colors:**
  - Primary Green: `#1DAF52`
  - Dark Text: `#2B2B2A`
  - Light Gray: `#B0B0B0`
  - Background: `#F5F5F5`

- **Border Radius:** 12px (rounded corners)
- **Text Direction:** RTL (Arabic support)
- **Shadows:** Subtle box shadows on cards

## Error Handling

The implementation includes comprehensive error handling:
- Network errors
- Empty search queries
- 404 Not Found responses
- Invalid responses
- Token/authentication issues

All errors are displayed to the user in a friendly format.

## Performance Considerations

1. **Pagination:** Results are loaded in pages of 10 to reduce data transfer
2. **Image Caching:** Flutter handles image caching automatically
3. **State Management:** Uses StatefulWidget for efficient rebuilds
4. **Memory:** Results are appended for pagination, not replaced

## Integration Notes

### To integrate this into your app:

1. The search bar is already in your home screen
2. Search results screen is ready to use
3. Navigation to product details works automatically
4. Authentication headers are handled automatically

### Making it work:

1. Ensure the API endpoint is available at your backend
2. Verify the response format matches the expected JSON structure
3. Test with your actual backend URL (should be in `AuthConfig.baseUrl`)

## Customization Options

You can customize:
- Page size (default: 10) - Change `_pageSize` in SearchResultsScreen
- Sort order - Default is `date_asc`, can be changed to `date_desc`
- Card styling - Modify colors, fonts, and layouts in `_buildSearchResultCard()`
- Loading animations - Change the CircularProgressIndicator
- Error messages - Modify text strings (Arabic translations included)

## Testing the Feature

To test:
1. Run the app
2. Navigate to the home screen
3. Click in the search bar at the top
4. Type a search term (e.g., "phone", "car", "house")
5. Press search or hit Enter
6. Verify results display correctly
7. Click on a product to view details
8. Scroll down and click "Load More" to test pagination

## Next Steps (Optional Enhancements)

1. Add filters (price range, category, condition)
2. Add sorting options
3. Save search history
4. Add search suggestions/autocomplete
5. Add filters by category in search
6. Add favorites quick action on search cards
