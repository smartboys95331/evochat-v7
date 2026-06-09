import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../services/mesh_service.dart';
import '../services/database_service.dart';
import '../theme.dart';
import 'chat_screen.dart';
import 'setup_screen.dart';

class HomeScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const HomeScreen({super.key, required this.userId, required this.userName});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final MeshService _mesh = MeshService();
  final DatabaseService _db = DatabaseService();
  List<Peer> _peers = [];
  bool _scanning = false;
  bool _initialized = false;
  String _statusText = 'Ready to scan';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  Future<void> _init() async {
    await _mesh.startBroadcasting(widget.userName);
    await _mesh.startListening(widget.userId, (senderId, text) {
      // Refresh chat if open (handled in chat screen via callback)
      setState(() {});
    });
    setState(() => _initialized = true);
  }

  Future<void> _scanPeers() async {
    setState(() {
      _scanning = true;
      _statusText = 'Scanning for nearby people...';
      _peers = [];
    });
    final found = await _mesh.discoverPeers();
    setState(() {
      _peers = found;
      _scanning = false;
      _statusText = found.isEmpty
          ? 'No peers found. Make sure others are on the same WiFi.'
          : '${found.length} peer(s) found nearby';
    });
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        title: const Text('Log Out', style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text('This will clear your identity. Continue?',
            style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Log Out', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      await _db.clearAll();
      await _mesh.dispose();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const SetupScreen()),
          (_) => false,
        );
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _mesh.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            const Text('EvoChat'),
            Text(
              widget.userName,
              style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.accent,
                  fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showMenu(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Status bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: AppTheme.bgCard2,
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _initialized ? AppTheme.online : AppTheme.offline,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _initialized ? 'Broadcasting as ${widget.userName}' : 'Initializing...',
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),

          // Scan button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _scanning ? null : _scanPeers,
                icon: _scanning
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.radar),
                label: Text(_scanning ? 'Scanning...' : 'Scan for Nearby People'),
              ),
            ),
          ),

          // Status text
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              _statusText,
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 8),

          // Peers list
          Expanded(
            child: _peers.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _peers.length,
                    itemBuilder: (_, i) => _buildPeerTile(_peers[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline,
              size: 72, color: AppTheme.textSecondary.withOpacity(0.3)),
          const SizedBox(height: 16),
          const Text(
            'No peers yet',
            style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 18,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap scan to find people\non the same WiFi network',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildPeerTile(Peer peer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: AppTheme.primary.withOpacity(0.2),
          child: Text(
            peer.name.isNotEmpty ? peer.name[0].toUpperCase() : '?',
            style: const TextStyle(
                color: AppTheme.primary, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(peer.name,
            style: const TextStyle(
                color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
        subtitle: Text(
          peer.host,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.online.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text(
            'Online',
            style: TextStyle(color: AppTheme.online, fontSize: 11),
          ),
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              myId: widget.userId,
              myName: widget.userName,
              peer: peer,
              db: _db,
              mesh: _mesh,
            ),
          ),
        ),
      ),
    );
  }

  void _showMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.textSecondary.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline, color: AppTheme.accent),
            title: const Text('About EvoChat',
                style: TextStyle(color: AppTheme.textPrimary)),
            onTap: () {
              Navigator.pop(context);
              _showAbout();
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text('Log Out',
                style: TextStyle(color: Colors.redAccent)),
            onTap: () {
              Navigator.pop(context);
              _logout();
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showAbout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        title: const Text('EvoChat', style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text(
          'EvoChat is a secure, offline P2P messenger.\n\n'
          '• No internet required\n'
          '• End-to-end encrypted (AES-256)\n'
          '• Works on local WiFi\n'
          '• No servers, no accounts\n'
          '• Your data stays on your device',
          style: TextStyle(color: AppTheme.textSecondary, height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
