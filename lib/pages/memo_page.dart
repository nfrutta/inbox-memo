import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:inbox_memo/providers/app_setting_provider.dart';
import 'package:share/share.dart';

import '../providers/memo_provider.dart';
import '../providers/theme_provider.dart';
import 'setting_page.dart';

// ignore: must_be_immutable
class MemoPage extends ConsumerWidget {
  MemoPage({Key? key, required this.initText}) : super(key: key) {
    controller = TextEditingController(text: initText);
  }

  String initText;
  late TextEditingController controller;
  final FocusNode _focusNode = FocusNode();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    controller.selection = TextSelection.fromPosition(
      TextPosition(offset: controller.text.length),
    );
    int textMaxLines = MediaQuery.of(context).size.height ~/ 100 * 2;
    textMaxLines = Platform.isAndroid ? textMaxLines - 1 : textMaxLines + 1;
    final isDark = ref.watch(themeProvider.notifier).isDark;
    final memoObserver = ref.read(memoProvider.notifier);
    return Scaffold(
      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16.0),
          child: TextFormField(
            decoration: InputDecoration(
              fillColor: isDark ? Colors.grey[800] : Colors.blueGrey[50],
              filled: true,
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: isDark ? Colors.grey[800]! : Colors.blueGrey[50]!,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: isDark ? Colors.grey[800]! : Colors.blueGrey[50]!,
                ),
              ),
            ),
            cursorColor: isDark ? Colors.indigo[400] : Colors.blueGrey,
            controller: controller,
            maxLines: textMaxLines,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontSize: 16.0,
            ),
            autofocus: true,
            focusNode: _focusNode,
            onChanged: (text) {
              memoObserver.save(text);
            },
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 0.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 32), // 左にめり込むのでその対策
            FloatingActionButton(
              child: const Icon(FontAwesomeIcons.cog),
              onPressed: () async {
                _focusNode.unfocus();
                await showModalBottomSheet<void>(
                  context: context,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                  ),
                  builder: (BuildContext context) {
                    return const SettingPage();
                  },
                );
                FocusScope.of(context).requestFocus(_focusNode);
              },
            ),
            const SizedBox(width: 16),
            FloatingActionButton(
              child: const Icon(FontAwesomeIcons.shareAlt),
              onPressed: () async {
                if (controller.text == '') {
                  debugPrint('text empty.');
                  return;
                }
                _focusNode.unfocus();
                await Share.share(controller.text);
              },
            ),
            const Expanded(child: SizedBox()),
            FloatingActionButton(
              child: const Icon(FontAwesomeIcons.trash),
              backgroundColor: Colors.red[300],
              onPressed: () async {
                if (controller.text == '') {
                  debugPrint('text empty.');
                  return;
                }
                _focusNode.unfocus();

                if (ref.read(appSettingProvider).getDeleteConfirm()) {
                  var result = await _showDeleteConfirm(
                      context, '確認', '入力した文字を全削除します。よろしいですか？');
                  if (!result) {
                    debugPrint('delete cancel');
                    FocusScope.of(context).requestFocus(_focusNode);
                    return;
                  }
                }

                memoObserver.clear();
                controller.clear();

                FocusScope.of(context).requestFocus(_focusNode);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _showDeleteConfirm(
    BuildContext context,
    String title,
    String content,
  ) async {
    final result = await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return _buildDeleteConfirmDialog(context, title, content);
      },
    );
    return result;
  }

  Widget _buildDeleteConfirmDialog(
    BuildContext context,
    String title,
    String content,
  ) {
    if (Platform.isIOS) {
      return CupertinoAlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          CupertinoDialogAction(
            child: const Text('キャンセル'),
            onPressed: () => Navigator.pop(context, false),
          ),
          CupertinoDialogAction(
            child: const Text(
              '削除',
              style: TextStyle(color: Colors.red),
            ),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      );
    } else {
      return AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            child: const Text('キャンセル'),
            onPressed: () => Navigator.pop(context, false),
          ),
          TextButton(
            child: const Text(
              '削除',
              style: TextStyle(color: Colors.red),
            ),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      );
    }
  }
}