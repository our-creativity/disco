import 'package:flutter/material.dart';
import 'package:solidart_example/controllers/todos.dart';
import 'package:solidart_example/domain/todo.dart';

/// Renders a ListTile with a checkbox where you can change
/// the "completion" status of a [Todo]
class TodoItem extends StatelessWidget {
  const TodoItem({
    super.key,
    required this.todo,
    this.onStatusChanged,
  });

  final Todo todo;
  final ValueChanged<bool?>? onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(todo.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        // remove the todo
        todosControllerProvider.of(context).remove(todo.id);
      },
      background: Container(
        decoration: const BoxDecoration(color: Colors.red),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 8),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      child: CheckboxListTile(
        title: Text(todo.task),
        value: todo.completed,
        onChanged: onStatusChanged,
      ),
    );
  }
}
