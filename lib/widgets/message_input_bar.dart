import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MessageInputBar extends StatefulWidget {
  const MessageInputBar({
    super.key,
    required this.onSend,
    required this.onSendImage,
    required this.onSendEmoticon,
    this.enabled = true,
    required this.showEmojiPicker,
    required this.onEmojiPickerToggle,
  });

  final Future<void> Function(String text) onSend;
  final Future<void> Function(File imageFile) onSendImage;
  final Future<void> Function(String emoticonUrl) onSendEmoticon;
  final bool enabled;
  final bool showEmojiPicker;
  final Function(bool visible) onEmojiPickerToggle;

  @override
  State<MessageInputBar> createState() => _MessageInputBarState();
}

class _MessageInputBarState extends State<MessageInputBar>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  bool _sending = false;
  late TabController _tabController;
  bool _showEmoticons = false;

  File? _pickedImage;
  String? _pickedEmoticon;

  final Map<String, String> emoticonS3Urls = {
    'angry':
    'https://connectbeat-bucket.s3.ap-northeast-2.amazonaws.com/emoticons/emo_angry.png',
    'cry':
    'https://connectbeat-bucket.s3.ap-northeast-2.amazonaws.com/emoticons/emo_cry.png',
    'love':
    'https://connectbeat-bucket.s3.ap-northeast-2.amazonaws.com/emoticons/emo_love.png',
    'sleepy':
    'https://connectbeat-bucket.s3.ap-northeast-2.amazonaws.com/emoticons/emo_sleepy.png',
    'sparkle':
    'https://connectbeat-bucket.s3.ap-northeast-2.amazonaws.com/emoticons/emo_sparkle.png',
    'sulky':
    'https://connectbeat-bucket.s3.ap-northeast-2.amazonaws.com/emoticons/emo_sulky.png',
    'wink':
    'https://connectbeat-bucket.s3.ap-northeast-2.amazonaws.com/emoticons/emo_wink.png',
    'laughing':
    'https://connectbeat-bucket.s3.ap-northeast-2.amazonaws.com/emoticons/emo_laughing.png',
    'eat':
    'https://connectbeat-bucket.s3.ap-northeast-2.amazonaws.com/emoticons/emo_eat.png',
    'jump_rope':
    'https://connectbeat-bucket.s3.ap-northeast-2.amazonaws.com/emoticons/emo_jump_rope.png',
    'sunglasses':
    'https://connectbeat-bucket.s3.ap-northeast-2.amazonaws.com/emoticons/emo_sunglasses.png',
    'computer':
    'https://connectbeat-bucket.s3.ap-northeast-2.amazonaws.com/emoticons/emo_computer.png',
    'work':
    'https://connectbeat-bucket.s3.ap-northeast-2.amazonaws.com/emoticons/emo_work.png',
  };

  List<String> recentEmoticons = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadRecentEmoticons();
  }

  Future<void> _loadRecentEmoticons() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      recentEmoticons = prefs.getStringList('recent_emoticons') ?? [];
    });
  }

  Future<void> _saveRecentEmoticon(String url) async {
    final prefs = await SharedPreferences.getInstance();
    recentEmoticons.remove(url);
    recentEmoticons.insert(0, url);
    if (recentEmoticons.length > 10) recentEmoticons.removeLast();
    await prefs.setStringList('recent_emoticons', recentEmoticons);
    setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleSend() async {
    if (_sending || !widget.enabled) return;
    setState(() => _sending = true);

    try {
      if (_pickedImage != null) {
        await widget.onSendImage(_pickedImage!);
        _pickedImage = null;
      }

      if (_pickedEmoticon != null) {
        await widget.onSendEmoticon(_pickedEmoticon!);
        await _saveRecentEmoticon(_pickedEmoticon!);
        _pickedEmoticon = null;
      }

      final text = _controller.text.trim();
      if (text.isNotEmpty) {
        await widget.onSend(text);
        _controller.clear();
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _handleImagePick() async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _pickedImage = File(picked.path);
      });
    }
  }

  Widget _buildEmoticonGrid(List<String> urls) {
    if (urls.isEmpty) {
      return const Center(child: Text('최근 사용한 이모티콘이 없습니다.'));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: urls.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemBuilder: (context, index) {
        final url = urls[index];
        return GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
            setState(() {
              _pickedEmoticon = url;
            });
          },
          onDoubleTap: () async {
            if (_sending || !widget.enabled) return;
            setState(() => _sending = true);
            try {
              await widget.onSendEmoticon(url);
              await _saveRecentEmoticon(url);
              _pickedEmoticon = null;
            } finally {
              if (mounted) setState(() => _sending = false);
            }
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(url, fit: BoxFit.contain),
          ),
        );
      },
    );
  }

  Widget _buildPreview() {
    if (_pickedImage != null) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        height: 150, // 기존 100 → 150으로 증가
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                _pickedImage!,
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _pickedImage = null;
                  });
                },
                child: const CircleAvatar(
                  radius: 12,
                  backgroundColor: Colors.black54,
                  child: Icon(Icons.close, size: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      );
    } else if (_pickedEmoticon != null) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        height: 120, // 기존 80 → 120으로 증가
        color: Colors.transparent,
        child: Stack(
          children: [
            Center(child: Image.network(_pickedEmoticon!, height: 100)), // 높이 조정
            Positioned(
              top: 0,
              right: 0,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _pickedEmoticon = null;
                  });
                },
                child: const CircleAvatar(
                  radius: 12,
                  backgroundColor: Colors.black54,
                  child: Icon(Icons.close, size: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }


  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPreview(),

          // 입력창
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFEFEFEF))),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.emoji_emotions_outlined,
                      color: Color(0xFFFDAAFF)),
                  onPressed: widget.enabled
                      ? () {
                    FocusScope.of(context).unfocus();
                    widget.onEmojiPickerToggle(!widget.showEmojiPicker);
                  }
                      : null,
                ),
                IconButton(
                  icon:
                  const Icon(Icons.photo, color: Color(0xFFFDAAFF)),
                  onPressed: widget.enabled ? _handleImagePick : null,
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    enabled: widget.enabled && !_sending,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.newline,
                    onTap: () {
                      if (widget.showEmojiPicker) {
                        widget.onEmojiPickerToggle(false);
                      }
                    },
                    style: const TextStyle(
                        fontSize: 16, color: Colors.black87),
                    decoration: InputDecoration(
                      hintText: '메시지를 입력하세요',
                      border: const OutlineInputBorder(
                          borderSide: BorderSide.none),
                      isDense: true,
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: '보내기',
                  onPressed:
                  (_sending || !widget.enabled) ? null : _handleSend,
                  icon: const Icon(Icons.send, color: Color(0xFFFDAAFF)),
                ),
              ],
            ),
          ),

          // ✅ 이모티콘창
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            firstChild: const SizedBox.shrink(),
            secondChild: Stack(
              children: [
                // 외부 터치 영역
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () => widget.onEmojiPickerToggle(false),
                    behavior: HitTestBehavior.translucent,
                  ),
                ),
                // 이모티콘 본체
                SizedBox(
                  height: 250,
                  child: Column(
                    children: [
                      TabBar(
                        controller: _tabController,
                        labelColor: Colors.pinkAccent,
                        unselectedLabelColor: Colors.grey,
                        tabs: const [
                          Tab(text: '최근'),
                          Tab(text: '전체'),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildEmoticonGrid(recentEmoticons),
                            _buildEmoticonGrid(emoticonS3Urls.values.toList()),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            crossFadeState: widget.showEmojiPicker
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
          ),
        ],
      ),
    );
  }
}
