import 'package:flutter/material.dart';

class AppPermissionItem extends StatelessWidget {
  final String icon;
  final String name;
  final String description;
  final Color color;
  final bool isSelected;
  final VoidCallback onToggle;

  const AppPermissionItem({
    required this.icon,
    required this.name,
    required this.description,
    required this.color,
    required this.isSelected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Image.network(icon, width: 40, height: 40),
        title: Text(name),
        subtitle: Text(description),
        trailing: Checkbox(
          value: isSelected,
          onChanged: (value) => onToggle(),
        ),
      ),
    );
  }
}