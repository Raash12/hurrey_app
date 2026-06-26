import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DailyTaskPage extends StatefulWidget {
  const DailyTaskPage({super.key});

  @override
  State<DailyTaskPage> createState() => _DailyTaskPageState();
}

class _DailyTaskPageState extends State<DailyTaskPage> {
  // ==================== CONSTANTS ====================
  static const primary = Color(0xFF6C63FF);
  static const secondary = Color(0xFF4CAF50);
  static const bgLight = Color(0xFFF8F9FE);
  static const gradient1 = Color(0xFF6C63FF);
  static const gradient2 = Color(0xFF4CAF50);

  // ==================== CONTROLLERS ====================
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _remarkCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  String? _editingDocId;

  // ==================== STATE ====================
  final _searchQuery = ValueNotifier<String>('');
  final _filterStart = ValueNotifier<DateTime?>(null);
  final _filterEnd = ValueNotifier<DateTime?>(null);

  String _sortBy = 'date';
  bool _sortAscending = false;

  // Pagination
  final _allTasks = <QueryDocumentSnapshot>[];
  DocumentSnapshot? _lastDoc;
  bool _loading = false;
  bool _hasMore = true;
  final _scrollCtrl = ScrollController();

  // ==================== INIT & DISPOSE ====================
  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    _loadData();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _remarkCtrl.dispose();
    _amountCtrl.dispose();
    _searchCtrl.dispose();
    _searchQuery.dispose();
    _filterStart.dispose();
    _filterEnd.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // ==================== PAGINATION ====================
  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadData() async {
    _allTasks.clear();
    _lastDoc = null;
    _hasMore = true;
    _loading = false;
    await _loadMore();
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;
    _loading = true;
    setState(() {});

    try {
      var query = FirebaseFirestore.instance
          .collection('dailyTasks')
          .orderBy('taskDateTime', descending: true)
          .limit(20);
      if (_lastDoc != null) query = query.startAfterDocument(_lastDoc!);

      final snap = await query.get();
      if (snap.docs.isEmpty) {
        _hasMore = false;
      } else {
        _allTasks.addAll(snap.docs);
        _lastDoc = snap.docs.last;
        _hasMore = snap.docs.length == 20;
      }
    } catch (e) {
      _showSnackBar('❌ Cillad: $e', true);
    }
    _loading = false;
    setState(() {});
  }

  // ==================== CRUD ====================
  Future<void> _addTask() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0;
      final dt = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      await FirebaseFirestore.instance.collection('dailyTasks').add({
        'name': _nameCtrl.text.trim(),
        'remark': _remarkCtrl.text.trim(),
        'amount': amount,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': DateTime.now().toIso8601String(),
        'taskDateTime': dt.toIso8601String(),
        'taskDate': DateFormat('yyyy-MM-dd').format(dt),
        'taskTime': DateFormat('hh:mm a').format(dt),
        'isCompleted': false,
      });

      _nameCtrl.clear();
      _remarkCtrl.clear();
      _amountCtrl.clear();
      _showSnackBar('✅ Task waa la kaydiyay!');
      await _loadData();
    } catch (e) {
      _showSnackBar('❌ Cillad: $e', true);
    }
  }

  Future<void> _updateTask() async {
    if (!_formKey.currentState!.validate() || _editingDocId == null) return;
    try {
      final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0;
      final dt = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      await FirebaseFirestore.instance
          .collection('dailyTasks')
          .doc(_editingDocId)
          .update({
            'name': _nameCtrl.text.trim(),
            'remark': _remarkCtrl.text.trim(),
            'amount': amount,
            'taskDateTime': dt.toIso8601String(),
            'taskDate': DateFormat('yyyy-MM-dd').format(dt),
            'taskTime': DateFormat('hh:mm a').format(dt),
            'updatedAt': DateTime.now().toIso8601String(),
          });

      _nameCtrl.clear();
      _remarkCtrl.clear();
      _amountCtrl.clear();
      _editingDocId = null;
      Navigator.pop(context);
      _showSnackBar('✅ Task waa la cusboonaysiiyay!');
      await _loadData();
    } catch (e) {
      _showSnackBar('❌ Cillad: $e', true);
    }
  }

  Future<void> _deleteTask(String id) async {
    try {
      await FirebaseFirestore.instance
          .collection('dailyTasks')
          .doc(id)
          .delete();
      _allTasks.removeWhere((d) => d.id == id);
      setState(() {});
      _showSnackBar('🗑️ Task waa la tirtiray!');
    } catch (e) {
      _showSnackBar('❌ Cillad: $e', true);
    }
  }

  Future<void> _toggleComplete(String id, bool current) async {
    try {
      await FirebaseFirestore.instance.collection('dailyTasks').doc(id).update({
        'isCompleted': !current,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      await _loadData();
    } catch (e) {
      _showSnackBar('❌ Cillad: $e', true);
    }
  }

  // ==================== EDIT ====================
  void _editTask(String id, Map<String, dynamic> data) {
    _editingDocId = id;
    _nameCtrl.text = data['name'] ?? '';
    _remarkCtrl.text = data['remark'] ?? '';
    _amountCtrl.text = (data['amount'] ?? 0).toString();

    try {
      final dt = DateTime.parse(data['taskDateTime']);
      _selectedDate = dt;
      _selectedTime = TimeOfDay.fromDateTime(dt);
    } catch (_) {
      _selectedDate = DateTime.now();
      _selectedTime = TimeOfDay.now();
    }

    _showFormDialog('Edit Task', Icons.edit_note_rounded, _updateTask);
  }

  // ==================== DIALOGS ====================
  void _showAddDialog() {
    _nameCtrl.clear();
    _remarkCtrl.clear();
    _amountCtrl.clear();
    _selectedDate = DateTime.now();
    _selectedTime = TimeOfDay.now();
    _editingDocId = null;
    _showFormDialog('Ku Dari Task', Icons.task_alt_rounded, _addTask);
  }

  void _showFormDialog(String title, IconData icon, VoidCallback onSave) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (c) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(c).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDialogHeader(title, icon, c),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: _inputDec('Task Name', Icons.task_alt_rounded),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Gali magaca' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _remarkCtrl,
                    decoration: _inputDec('Remark', Icons.comment_rounded),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _amountCtrl,
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: _inputDec('Amount', Icons.attach_money_rounded),
                  ),
                  const SizedBox(height: 14),
                  _buildDateTimePickers(c),
                  const SizedBox(height: 16),
                  _buildSaveBtn(onSave),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDialogHeader(String title, IconData icon, BuildContext c) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [gradient1, gradient2]),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: primary,
              ),
            ),
          ],
        ),
        IconButton(
          onPressed: () => Navigator.pop(c),
          icon: const Icon(Icons.close, color: Colors.grey, size: 22),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  Widget _buildSaveBtn(VoidCallback onSave) {
    return Container(
      width: double.infinity,
      height: 44,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [gradient1, gradient2]),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ElevatedButton(
        onPressed: onSave,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
        ),
        child: Text(
          _editingDocId == null ? 'Kaydi' : 'Cusboonaysii',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  // ==================== DATE/TIME PICKERS ====================
  Widget _buildDateTimePickers(BuildContext c) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: c,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );
              if (picked != null) setState(() => _selectedDate = picked);
            },
            child: _buildPickerRow(
              Icons.calendar_today_rounded,
              DateFormat('dd/MM/yyyy').format(_selectedDate),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: InkWell(
            onTap: () async {
              final picked = await showTimePicker(
                context: c,
                initialTime: _selectedTime,
              );
              if (picked != null) setState(() => _selectedTime = picked);
            },
            child: _buildPickerRow(
              Icons.access_time_rounded,
              _selectedTime.format(c),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPickerRow(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bgLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: primary, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  // ==================== FILTERS ====================
  List<QueryDocumentSnapshot> _filterTasks(
    List<QueryDocumentSnapshot> tasks,
    String query,
    DateTime? start,
    DateTime? end,
  ) {
    return tasks.where((doc) {
      final data = doc.data() as Map<String, dynamic>;

      if (query.isNotEmpty) {
        final name = (data['name'] ?? '').toString().toLowerCase();
        final remark = (data['remark'] ?? '').toString().toLowerCase();
        if (!name.contains(query) && !remark.contains(query)) return false;
      }

      if (start != null || end != null) {
        final dateStr = data['taskDate'] ?? '';
        if (dateStr.isEmpty) return false;
        try {
          final d = DateFormat('yyyy-MM-dd').parse(dateStr);
          final td = DateTime(d.year, d.month, d.day);
          if (start != null &&
              td.isBefore(DateTime(start.year, start.month, start.day)))
            return false;
          if (end != null && td.isAfter(DateTime(end.year, end.month, end.day)))
            return false;
        } catch (_) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  List<QueryDocumentSnapshot> _sortTasks(List<QueryDocumentSnapshot> tasks) {
    final sorted = List<QueryDocumentSnapshot>.from(tasks);
    sorted.sort((a, b) {
      final da = a.data() as Map<String, dynamic>;
      final db = b.data() as Map<String, dynamic>;
      int r = 0;
      switch (_sortBy) {
        case 'name':
          r = (da['name'] ?? '').toString().compareTo(
            (db['name'] ?? '').toString(),
          );
          break;
        case 'amount':
          r = ((da['amount'] ?? 0) as num).compareTo(
            (db['amount'] ?? 0) as num,
          );
          break;
        default:
          final ad = da['updatedAt'] ?? da['taskDateTime'] ?? '';
          final bd = db['updatedAt'] ?? db['taskDateTime'] ?? '';
          r = ad.toString().compareTo(bd.toString());
      }
      return _sortAscending ? r : -r;
    });
    return sorted;
  }

  // ==================== SNACKBAR ====================
  void _showSnackBar(String msg, [bool error = false]) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontSize: 13)),
        backgroundColor: error ? Colors.red : primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  // ==================== UI HELPERS ====================
  InputDecoration _inputDec(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13),
      prefixIcon: Icon(icon, color: primary, size: 18),
      filled: true,
      fillColor: bgLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      constraints: const BoxConstraints(minHeight: 44),
    );
  }

  // ==================== SUMMARY CARD ====================
  Widget _buildSummaryCard(
    double todayTotal,
    int total,
    int done,
    double allTotal,
    int filteredDone,
    int filteredTotal,
  ) {
    final rate = total > 0 ? (done / total) * 100 : 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [gradient1, gradient2]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.dashboard_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Summary',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  DateFormat('dd/MM/yy').format(DateTime.now()),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildStatBox('💰', '\$${todayTotal.toStringAsFixed(2)}'),
              const SizedBox(width: 6),
              _buildStatBox('📋', '$done/$total'),
              const SizedBox(width: 6),
              _buildStatBox('✅', '${rate.toStringAsFixed(0)}%'),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: rate / 100,
            backgroundColor: Colors.white.withOpacity(0.2),
            valueColor: const AlwaysStoppedAnimation(Colors.white),
            borderRadius: BorderRadius.circular(8),
            minHeight: 4,
          ),
          const SizedBox(height: 10),
          Container(height: 1, color: Colors.white.withOpacity(0.15)),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildStatSmall(
                'Done',
                '$filteredDone',
                Icons.check_circle_rounded,
              ),
              _buildStatSmall(
                'Pending',
                '${filteredTotal - filteredDone}',
                Icons.pending_rounded,
              ),
              _buildStatSmall(
                'Total',
                '\$${allTotal.toStringAsFixed(2)}',
                Icons.attach_money_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(String icon, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatSmall(String label, String value, IconData icon) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.8), size: 12),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 8,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== SEARCH BAR ====================
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primary.withOpacity(0.2)),
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => _searchQuery.value = v.toLowerCase().trim(),
                decoration: InputDecoration(
                  hintText: '🔍 Raadi task...',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 13,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: primary.withOpacity(0.6),
                    size: 18,
                  ),
                  suffixIcon: ValueListenableBuilder<String>(
                    valueListenable: _searchQuery,
                    builder: (_, value, __) => value.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.clear_rounded,
                              color: Colors.grey,
                              size: 18,
                            ),
                            onPressed: () {
                              _searchCtrl.clear();
                              _searchQuery.value = '';
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          )
                        : const SizedBox.shrink(),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 4,
                  ),
                  constraints: const BoxConstraints(minHeight: 40),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          _buildActionBtn(Icons.add, 'New', _showAddDialog),
          const SizedBox(width: 6),
          _buildSortBtn(),
        ],
      ),
    );
  }

  Widget _buildActionBtn(IconData icon, String label, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [gradient1, gradient2]),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 16),
                const SizedBox(width: 3),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSortBtn() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primary.withOpacity(0.2)),
      ),
      child: IconButton(
        icon: Icon(
          Icons.sort_rounded,
          color: primary.withOpacity(0.6),
          size: 20,
        ),
        onPressed: _showSortMenu,
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      ),
    );
  }

  // ==================== SORT MENU ====================
  void _showSortMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (c) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Sort Tasks',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: primary,
              ),
            ),
            const SizedBox(height: 12),
            _sortOption('📅 Latest', 'date'),
            _sortOption('📝 Name', 'name'),
            _sortOption('💰 Amount', 'amount'),
            const Divider(height: 1),
            ListTile(
              dense: true,
              leading: Icon(
                _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                color: primary,
                size: 18,
              ),
              title: Text(
                _sortAscending ? 'Ascending' : 'Descending',
                style: const TextStyle(fontSize: 14),
              ),
              onTap: () {
                setState(() => _sortAscending = !_sortAscending);
                Navigator.pop(c);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _sortOption(String label, String value) {
    return ListTile(
      dense: true,
      leading: Radio<String>(
        value: value,
        groupValue: _sortBy,
        activeColor: primary,
        onChanged: (v) {
          setState(() => _sortBy = v!);
          Navigator.pop(context);
        },
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          color: _sortBy == value ? primary : Colors.black87,
        ),
      ),
      onTap: () {
        setState(() => _sortBy = value);
        Navigator.pop(context);
      },
    );
  }

  // ==================== FILTER DIALOG ====================
  void _showFilterDialog() {
    DateTime? start = _filterStart.value;
    DateTime? end = _filterEnd.value;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (c) => StatefulBuilder(
        builder: (ctx, setState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildFilterHeader(ctx),
              const SizedBox(height: 16),
              _buildDateFilter(
                ctx,
                'Start',
                start,
                (d) => setState(() => start = d),
                () => setState(() => start = null),
              ),
              const SizedBox(height: 12),
              _buildDateFilter(
                ctx,
                'End',
                end,
                (d) => setState(() => end = d),
                () => setState(() => end = null),
              ),
              const SizedBox(height: 16),
              _buildFilterActions(ctx, start, end),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterHeader(BuildContext c) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [gradient1, gradient2]),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.filter_alt_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Filter',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: primary,
              ),
            ),
          ],
        ),
        IconButton(
          onPressed: () => Navigator.pop(c),
          icon: const Icon(Icons.close, color: Colors.grey, size: 22),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  Widget _buildDateFilter(
    BuildContext c,
    String label,
    DateTime? date,
    Function(DateTime) onPick,
    VoidCallback onClear,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: c,
              initialDate: date ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime(2100),
            );
            if (picked != null) onPick(picked);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: bgLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: primary.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_rounded, color: primary, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    date != null
                        ? DateFormat('dd/MM/yyyy').format(date)
                        : 'Select $label',
                    style: TextStyle(
                      fontSize: 13,
                      color: date != null ? Colors.black : Colors.grey.shade400,
                    ),
                  ),
                ),
                if (date != null)
                  IconButton(
                    onPressed: onClear,
                    icon: Icon(
                      Icons.clear_rounded,
                      color: Colors.grey,
                      size: 16,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterActions(BuildContext c, DateTime? start, DateTime? end) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              _filterStart.value = null;
              _filterEnd.value = null;
              _searchQuery.value = '';
              _searchCtrl.clear();
              Navigator.pop(c);
              _showSnackBar('🧹 Cleared');
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              minimumSize: const Size(0, 40),
            ),
            child: const Text('Clear', style: TextStyle(fontSize: 13)),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [gradient1, gradient2]),
              borderRadius: BorderRadius.circular(10),
            ),
            child: ElevatedButton(
              onPressed: () {
                _filterStart.value = start;
                _filterEnd.value = end;
                Navigator.pop(c);
                _showSnackBar('✅ Applied');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 10),
                minimumSize: const Size(0, 40),
              ),
              child: const Text(
                'Apply',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ==================== LOADING ====================
  Widget _buildLoadingMore() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: _loading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : _hasMore
            ? const SizedBox.shrink()
            : Text(
                '🏁 All tasks loaded',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
      ),
    );
  }

  // ==================== DELETE DIALOG ====================
  void _showDeleteDialog(String id) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('🗑️ Delete Task?', style: TextStyle(fontSize: 16)),
        content: const Text('Are you sure?', style: TextStyle(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(c);
              _deleteTask(id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              minimumSize: const Size(0, 36),
            ),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== MAIN BUILD ====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        toolbarHeight: 52,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [gradient1, gradient2]),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.task_alt_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Daily Tasks',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: primary,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: primary, size: 20),
            onPressed: _loadData,
            padding: const EdgeInsets.all(6),
          ),
          AnimatedBuilder(
            animation: Listenable.merge([_filterStart, _filterEnd]),
            builder: (_, __) {
              final active =
                  _filterStart.value != null || _filterEnd.value != null;
              return Container(
                margin: const EdgeInsets.only(right: 2),
                decoration: BoxDecoration(
                  gradient: active
                      ? const LinearGradient(colors: [gradient1, gradient2])
                      : null,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.filter_alt_rounded,
                    color: active ? Colors.white : primary,
                    size: 20,
                  ),
                  onPressed: _showFilterDialog,
                  padding: const EdgeInsets.all(6),
                ),
              );
            },
          ),
          Container(
            margin: const EdgeInsets.only(right: 6),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [gradient1, gradient2]),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.date_range_rounded,
                  color: Colors.white,
                  size: 12,
                ),
                const SizedBox(width: 3),
                Text(
                  DateFormat('dd/MM/yy').format(DateTime.now()),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadData,
              color: primary,
              child: _allTasks.isEmpty && !_loading
                  ? _buildEmptyState()
                  : ValueListenableBuilder(
                      valueListenable: _searchQuery,
                      builder: (_, __, ___) {
                        final start = _filterStart.value;
                        final end = _filterEnd.value;
                        final query = _searchQuery.value;

                        var filtered = _filterTasks(
                          _allTasks,
                          query,
                          start,
                          end,
                        );
                        filtered = _sortTasks(filtered);

                        if (filtered.isEmpty && _allTasks.isNotEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.filter_alt_off_rounded,
                                  size: 50,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No tasks match filter',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextButton(
                                  onPressed: () {
                                    _filterStart.value = null;
                                    _filterEnd.value = null;
                                    _searchQuery.value = '';
                                    _searchCtrl.clear();
                                  },
                                  child: const Text(
                                    'Clear Filters',
                                    style: TextStyle(fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        final today = DateFormat(
                          'yyyy-MM-dd',
                        ).format(DateTime.now());
                        final todayTasks = _allTasks.where((d) {
                          final data = d.data() as Map<String, dynamic>;
                          return data['taskDate'] == today;
                        }).toList();

                        final todayTotal = todayTasks.fold(
                          0.0,
                          (s, d) => s + ((d.data() as Map)['amount'] ?? 0),
                        );
                        final totalTasks = todayTasks.length;
                        final completedTasks = todayTasks
                            .where(
                              (d) => (d.data() as Map)['isCompleted'] ?? false,
                            )
                            .length;

                        final allTotal = filtered.fold(
                          0.0,
                          (s, d) => s + ((d.data() as Map)['amount'] ?? 0),
                        );
                        final done = filtered
                            .where(
                              (d) => (d.data() as Map)['isCompleted'] ?? false,
                            )
                            .length;

                        return Column(
                          children: [
                            _buildSummaryCard(
                              todayTotal,
                              totalTasks,
                              completedTasks,
                              allTotal,
                              done,
                              filtered.length,
                            ),
                            Expanded(
                              child: ListView.builder(
                                controller: _scrollCtrl,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                itemCount: filtered.length + (_hasMore ? 1 : 0),
                                itemBuilder: (_, i) {
                                  if (i == filtered.length)
                                    return _buildLoadingMore();
                                  return _buildTaskItem(filtered[i]);
                                },
                              ),
                            ),
                          ],
                        );
                      },
                    ),
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
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primary.withOpacity(0.1), secondary.withOpacity(0.1)],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.assignment_turned_in_outlined,
              size: 60,
              color: primary.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '📋 No tasks yet',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
          const SizedBox(height: 6),
          Text(
            'Add a new task to get started',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskItem(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final done = data['isCompleted'] ?? false;
    final amt = (data['amount'] ?? 0).toDouble();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: done ? secondary.withOpacity(0.3) : primary.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        dense: true,
        leading: Container(
          decoration: BoxDecoration(
            gradient: done
                ? const LinearGradient(colors: [secondary, Color(0xFF66BB6A)])
                : const LinearGradient(colors: [gradient1, gradient2]),
            shape: BoxShape.circle,
          ),
          child: Checkbox(
            value: done,
            activeColor: Colors.white,
            checkColor: primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            onChanged: (v) => _toggleComplete(doc.id, done),
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        title: Text(
          data['name'] ?? '',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            decoration: done ? TextDecoration.lineThrough : null,
            color: done ? Colors.grey : Colors.black87,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if ((data['remark'] ?? '').toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Text(
                  data['remark'],
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 10,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    data['taskDate'] ?? '',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.access_time_rounded,
                    size: 10,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    data['taskTime'] ?? '',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (amt > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: done
                        ? [
                            secondary.withOpacity(0.1),
                            secondary.withOpacity(0.05),
                          ]
                        : [primary.withOpacity(0.1), primary.withOpacity(0.05)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: done
                        ? secondary.withOpacity(0.3)
                        : primary.withOpacity(0.2),
                  ),
                ),
                child: Text(
                  '\$${amt.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: done ? secondary : primary,
                    fontSize: 11,
                  ),
                ),
              ),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [gradient1, gradient2]),
                borderRadius: BorderRadius.circular(6),
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.edit_rounded,
                  color: Colors.white,
                  size: 15,
                ),
                onPressed: () => _editTask(doc.id, data),
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                splashRadius: 14,
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.delete_outline_rounded,
                color: Colors.grey.shade400,
                size: 18,
              ),
              onPressed: () => _showDeleteDialog(doc.id),
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              splashRadius: 14,
            ),
          ],
        ),
      ),
    );
  }
}
