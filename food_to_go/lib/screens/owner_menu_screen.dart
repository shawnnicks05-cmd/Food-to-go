import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/food_item.dart';
import '../services/app_data.dart';
import '../widgets/food_image.dart';

class OwnerMenuScreen extends StatelessWidget {
  const OwnerMenuScreen({
    super.key,
    required this.stallId,
    required this.appData,
  });

  final String stallId;
  final AppData appData;

  Future<void> _showFoodForm(BuildContext context, {FoodItem? existing}) async {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final descriptionController = TextEditingController(
      text: existing?.description ?? '',
    );
    final imageController = TextEditingController(
      text: existing?.imageUrl ?? '',
    );
    final soloController = TextEditingController(
      text: existing?.soloPrice.toString() ?? '',
    );
    final mealController = TextEditingController(
      text: existing?.mealPrice.toString() ?? '',
    );

    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        var uploadingImage = false;
        var saving = false;
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            Future<void> uploadImage() async {
              setDialogState(() => uploadingImage = true);
              try {
                final result = await FilePicker.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: const [
                    'jpg',
                    'jpeg',
                    'png',
                    'webp',
                    'gif',
                  ],
                );
                if (result.isEmpty || !dialogContext.mounted) return;

                final file = result.single;
                final fileSize = await file.length();
                if (fileSize == null || fileSize > 5 * 1024 * 1024) {
                  throw const FormatException(
                    'Image files must be no larger than 5 MB.',
                  );
                }
                final bytes = await file.readAsBytes();

                final imageUrl = await appData.uploadFoodImage(
                  stallId: stallId,
                  fileName: file.name,
                  bytes: bytes,
                );
                if (!dialogContext.mounted) return;
                setDialogState(() => imageController.text = imageUrl);
              } catch (error) {
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(content: Text('Unable to upload image: $error')),
                  );
                }
              } finally {
                if (dialogContext.mounted) {
                  setDialogState(() => uploadingImage = false);
                }
              }
            }

            return AlertDialog(
              title: Text(
                existing == null ? 'Add Menu Item' : 'Edit Menu Item',
              ),
              content: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'Food name',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Enter a food name.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: descriptionController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Enter a description.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: imageController,
                          onChanged: (_) => setDialogState(() {}),
                          decoration: const InputDecoration(
                            labelText: 'Image URL',
                            hintText: 'https://example.com/food.jpg',
                          ),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: uploadingImage || saving
                              ? null
                              : uploadImage,
                          icon: uploadingImage
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.upload_file),
                          label: Text(
                            uploadingImage
                                ? 'Uploading image...'
                                : 'Choose and upload image',
                          ),
                        ),
                        if (imageController.text.trim().isNotEmpty) ...[
                          TextButton(
                            onPressed: uploadingImage || saving
                                ? null
                                : () => setDialogState(imageController.clear),
                            child: const Text('Remove image'),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 150,
                            width: double.infinity,
                            child: FoodImage(
                              imageUrl: imageController.text,
                              height: 150,
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: soloController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Solo price',
                            prefixText: '₱ ',
                          ),
                          validator: _validatePrice,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: mealController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Meal price',
                            prefixText: '₱ ',
                          ),
                          validator: _validatePrice,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: uploadingImage || saving
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: uploadingImage || saving
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;

                          final food = FoodItem(
                            id: existing?.id ?? '',
                            name: nameController.text.trim(),
                            description: descriptionController.text.trim(),
                            imageUrl: imageController.text.trim(),
                            soloPrice: double.parse(soloController.text.trim()),
                            mealPrice: double.parse(mealController.text.trim()),
                            isAvailable: existing?.isAvailable ?? true,
                            orderCount: existing?.orderCount ?? 0,
                          );

                          setDialogState(() => saving = true);
                          try {
                            if (existing == null) {
                              await appData.addFood(stallId, food);
                            } else {
                              await appData.updateFood(stallId, food);
                            }
                          } catch (error) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Unable to save menu item: $error',
                                  ),
                                ),
                              );
                            }
                            if (dialogContext.mounted) {
                              setDialogState(() => saving = false);
                            }
                            return;
                          }

                          if (!dialogContext.mounted || !context.mounted) {
                            return;
                          }
                          Navigator.pop(dialogContext);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                existing == null
                                    ? 'Menu item added.'
                                    : 'Menu item updated.',
                              ),
                            ),
                          );
                        },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    descriptionController.dispose();
    imageController.dispose();
    soloController.dispose();
    mealController.dispose();
  }

  String? _validatePrice(String? value) {
    final price = double.tryParse(value?.trim() ?? '');

    if (price == null || price <= 0) {
      return 'Enter a valid price greater than zero.';
    }

    return null;
  }

  Future<void> _deleteFood(BuildContext context, FoodItem food) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Menu Item?'),
        content: Text('Are you sure you want to delete ${food.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await appData.deleteFood(stallId, food.id);
      } catch (error) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Unable to delete menu item: $error')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final stall = appData.getStall(stallId);

    if (stall == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Manage Menu')),
        body: const Center(child: Text('Assigned storefront not found.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Menu')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showFoodForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Item'),
      ),
      body: AnimatedBuilder(
        animation: appData,
        builder: (context, _) {
          if (stall.menu.isEmpty) {
            return const Center(
              child: Text('No menu items yet. Add your first item.'),
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
            children: [
              Text(
                stall.name,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                'Edit your food details, prices, image, and availability.',
              ),
              const SizedBox(height: 16),
              ...stall.menu.map(
                (food) => Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            FoodImage(
                              imageUrl: food.imageUrl,
                              height: 82,
                              width: 82,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    food.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Solo: ₱${food.soloPrice.toStringAsFixed(2)}',
                                  ),
                                  Text(
                                    'Meal: ₱${food.mealPrice.toStringAsFixed(2)}',
                                  ),
                                  Text(
                                    food.isAvailable
                                        ? 'Available'
                                        : 'Unavailable',
                                    style: TextStyle(
                                      color: food.isAvailable
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Available for ordering'),
                          value: food.isAvailable,
                          onChanged: (_) async {
                            try {
                              await appData.toggleAvailability(
                                stallId,
                                food.id,
                              );
                            } catch (error) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Unable to update availability: $error',
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () =>
                                    _showFoodForm(context, existing: food),
                                icon: const Icon(Icons.edit_outlined),
                                label: const Text('Edit'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              tooltip: 'Delete item',
                              onPressed: () => _deleteFood(context, food),
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
