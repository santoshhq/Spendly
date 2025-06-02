import 'package:expense_tracker/models/model_expense.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ItemsList extends StatelessWidget {
  final Modelexpense itemsData;
  final void Function(Modelexpense) onDelete;
  final void Function(Modelexpense) onEdit;

  const ItemsList({
    super.key,
    required this.itemsData,
    required this.onDelete,
    required this.onEdit,
  });
  String formatAmount(double amount) {
    if (amount >= 10000000) {
      return '₹${(amount / 10000000).toStringAsFixed(2)}C';
    } else if (amount >= 100000) {
      return '₹${(amount / 100000).toStringAsFixed(2)}L';
    } else if (amount >= 1000) {
      return '₹${(amount / 1000).toStringAsFixed(2)}K';
    } else {
      return '₹${amount.toStringAsFixed(2)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(itemsData.id),
      direction: DismissDirection.endToStart,
      background: Container(
        padding: const EdgeInsets.only(right: 20),
        alignment: Alignment.centerRight,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: Colors.white, size: 30),
      ),
      onDismissed: (_) => onDelete(itemsData),
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        child: Container(
          decoration: BoxDecoration(
            gradient: _getcardCategoryGradient(itemsData.category),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title row with edit icon
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    itemsData.title,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.white),
                    onPressed: () => onEdit(itemsData),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Amount and date row
              Row(
                children: [
                  Text(
                    formatAmount(itemsData.amount),
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  Center(
                    child: Text(
                      _getCategoryName(itemsData.category),
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.95),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Icon(
                        categoryicon[itemsData.category],
                        color: Colors.white,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        itemsData.formattedDate,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Category name at bottom center
            ],
          ),
        ),
      ),
    );
  }

  /// Converts Category enum to user-friendly string
  String _getCategoryName(Category category) {
    return category.toString().split('.').last[0].toUpperCase() +
        category.toString().split('.').last.substring(1);
  }

  /// Returns gradient based on category
  LinearGradient _getcardCategoryGradient(Category category) {
    switch (category) {
      case Category.food:
        return const LinearGradient(
          colors: [Color(0xFF8B0000), Color(0xFFB22222)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case Category.entertainment:
        return const LinearGradient(
          colors: [Color(0xFF008B8B), Color(0xFF20B2AA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case Category.travel:
        return const LinearGradient(
          colors: [Color(0xFF004C99), Color(0xFF4682B4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case Category.work:
        return const LinearGradient(
          colors: [Color(0xFF556F44), Color(0xFF556F44)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case Category.education:
        return const LinearGradient(
          colors: [Color(0xFFE67E22), Color(0xFFE67E22)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case Category.housing:
        return const LinearGradient(
          colors: [Color(0xFF660066), Color(0xFF800080)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case Category.bills:
        return const LinearGradient(
          colors: [Color(0xFF2F4F4F), Color.fromARGB(255, 46, 75, 75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case Category.health:
        return const LinearGradient(
          colors: [Color(0xFF32CD32), Color(0xFF32CD32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case Category.fitness:
        return const LinearGradient(
          colors: [Color(0xFF00CED1), Color(0xFF00CED1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case Category.investment:
        return const LinearGradient(
          colors: [Color(0xFF009688), Color(0xFF00B894)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case Category.shopping:
        return const LinearGradient(
          colors: [Color(0xFF9B59B6), Color(0xFFBA55D3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case Category.subscriptions:
        return const LinearGradient(
          colors: [Color(0xFF6D2600), Color(0xFF8B4513)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default:
        return const LinearGradient(
          colors: [
            Color.fromARGB(255, 255, 66, 141),
            Color.fromARGB(255, 255, 66, 141),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }
}
