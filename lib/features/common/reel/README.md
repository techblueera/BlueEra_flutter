# Reel Product Details Feature

This feature implements a product details screen for reels with a GridView.builder that displays product cards in a 2x2 grid layout, exactly matching the provided image design.

## Features

- **GridView.builder**: Displays products in a responsive 2-column grid
- **Custom Product Cards**: Each card shows product image, title, description, price, and link
- **GetX State Management**: Uses GetX for reactive state management
- **Pull-to-Refresh**: Swipe down to refresh the product list
- **Loading States**: Shows loading indicator while fetching data
- **Static Data**: Uses static product list for immediate display
- **Modular Architecture**: Separated into Model, View, Controller, and Widget layers

## File Structure

```
lib/features/common/reel/
├── controller/
│   └── reel_product_details_controller.dart    # GetX controller with static data
├── models/
│   └── reel_product_model.dart                 # Product data model
├── view/
│   └── reel_product_details_screen.dart        # Main screen with GridView
├── widget/
│   └── product_card_widget.dart                # Reusable product card widget
└── README.md                                   # This documentation
```

## Usage

### 1. Navigate to the Screen

```dart
Get.to(() => const ReelProductDetailsScreen());
```

### 2. Controller Usage

```dart
// Get controller instance
final controller = Get.find<ReelProductDetailsController>();

// Load products (static data)
controller.loadProducts();

// Refresh data
controller.refreshProducts();

// Handle product tap
controller.onProductTap(index);

// Handle menu tap
controller.onMenuTap(index);
```

### 3. Product Model

```dart
ReelProductModel product = ReelProductModel(
  id: '1',
  title: 'Trying MC\'s Burger.',
  description: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nunc vulputa.',
  price: '₹61,499',
  link: 'http://www.annoyingpopups.com/',
  imageUrl: '', // Empty for placeholder
  hasMenuOptions: true,
);
```

## Design Features

### Grid Layout
- **2x2 Grid**: Responsive grid with proper spacing
- **Card Proportions**: Optimized aspect ratio for product cards
- **Spacing**: Consistent padding and margins

### Product Card Design
- **Red Background**: Matches the image design with red background
- **Fast Food Icons**: Placeholder icons for food items
- **Three Dots Menu**: Menu options in top-right corner
- **Text Layout**: Title, description, price, and link
- **Shadow Effects**: Subtle shadows for depth

### Colors and Styling
- **Red Background**: For product images (Colors.red)
- **White Cards**: Clean white background for cards
- **Blue Links**: Clickable link styling
- **Grey Text**: Description text color
- **Black Titles**: Bold product titles

## Implementation Details

### Controller
- **Static Data**: Pre-defined product list
- **Reactive State**: GetX observable variables
- **Event Handlers**: Tap and menu interactions
- **Loading States**: Smooth loading experience

### Widget
- **Reusable Component**: Modular product card widget
- **Error Handling**: Graceful fallback for missing images
- **Responsive Design**: Adapts to different screen sizes
- **Touch Feedback**: Interactive tap areas

## Customization

### Grid Layout
Modify the `SliverGridDelegateWithFixedCrossAxisCount`:

```dart
gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
  crossAxisCount: 2,           // Number of columns
  crossAxisSpacing: 12,        // Horizontal spacing
  mainAxisSpacing: 12,         // Vertical spacing
  childAspectRatio: 0.75,      // Card aspect ratio
),
```

### Product Data
Update the static list in `loadProducts()` method:

```dart
products.value = [
  ReelProductModel(
    id: '1',
    title: 'Your Product Title',
    description: 'Your product description',
    price: '₹Your Price',
    link: 'http://your-link.com',
    imageUrl: 'assets/your-image.jpg',
    hasMenuOptions: true,
  ),
  // Add more products...
];
```

## Dependencies

- `get` - State management
- `flutter` - UI framework
- Custom widgets from the app's widget library

## Notes

- Uses static data for immediate display
- No API dependencies for simplicity
- Controller uses unique tags to prevent conflicts
- Product cards handle text overflow gracefully
- Matches the exact design from the provided image 