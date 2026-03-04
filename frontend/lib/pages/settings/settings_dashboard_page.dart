import 'package:flutter/material.dart';
import 'category_list_page.dart';
import 'user_list_page.dart';
import 'role_list_page.dart';
import 'function_list_page.dart';
import 'department_list_page.dart';

class SettingsDashboardPage extends StatelessWidget {
  const SettingsDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('系統設定')),
      body: ListView(
        children: [
          _buildSettingsItem(
            context,
            icon: Icons.list_alt,
            title: '資料字典維護 (Metadata)',
            subtitle: '管理資產大類、小類、倉儲位置等',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CategoryListPage(),
                ),
              );
            },
          ),
          const Divider(),
          _buildSettingsItem(
            context,
            icon: Icons.people,
            title: '使用者管理 (Users)',
            subtitle: '管理系統使用者帳號與所屬部門',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UserListPage()),
              );
            },
          ),
          const Divider(),
          _buildSettingsItem(
            context,
            icon: Icons.domain,
            title: '部門管理 (Departments)',
            subtitle: '管理公司組織與部門層級架構',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DepartmentListPage(),
                ),
              );
            },
          ),
          const Divider(),
          _buildSettingsItem(
            context,
            icon: Icons.security,
            title: '群組權限管理 (Roles)',
            subtitle: '設定群組角色及各項操作權限開關',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RoleListPage()),
              );
            },
          ),
          const Divider(),
          _buildSettingsItem(
            context,
            icon: Icons.widgets,
            title: '功能項目管理 (Functions)',
            subtitle: '管理系統各功能模組與綁定路徑',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FunctionListPage(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, size: 36, color: Theme.of(context).primaryColor),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
