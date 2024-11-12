import 'package:flutter/material.dart';
import '../controller/databse_helper.dart';

class UsersPages extends StatefulWidget {
  const UsersPages({super.key});

  @override
  State<UsersPages> createState() => _UsersPagesState();
}

class _UsersPagesState extends State<UsersPages> {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Method to fetch all users
  Future<List<Map<String, dynamic>>> _fetchUsers() async {
    return await _dbHelper.getAllUsers();
  }

  Future<void> _deleteUser(int id) async {
    await _dbHelper.deleteUser(id);
    setState(() {}); // Refresh the list after deletion
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Users", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No users found."));
          } else {
            final users = snapshot.data!;
            return ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                return ListTile(
                  onTap: () {
                    _deleteUser(user[columnId]);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("${user[columnName]} deleted")),
                    );
                  },
                  title: Text(user[columnName] ?? "Unnamed User"),
                  subtitle: Text("id: ${user[columnFaceData]}"),
                );
              },
            );
          }
        },
      ),
    );
  }
}
