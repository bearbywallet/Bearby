import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/mixins/adaptive_size.dart';
import 'package:zilpay/state/app_state.dart';
import 'package:zilpay/theme/app_theme.dart';

const double ICON_SIZE_SMALL = 24.0;
const double ICON_SIZE_MEDIUM = 32.0;

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;
  bool _isAnalyzing = false;
  String _currentAnalysisStep = '';

  @override
  void initState() {
    super.initState();
    _messageController.addListener(() => setState(() {}));
    _streamAIMessage(
      "Hello! ✨ I'm your DeFi investment assistant. I can help you find the best liquidity pools for your tokens. How can I help you today?",
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _streamAIMessage(String fullText,
      {List<ChatAction>? actions}) async {
    setState(() {
      _messages.add(ChatMessage(text: '', isUser: false));
      _isTyping = true;
    });
    _scrollToBottom();

    final words = fullText.split(' ');
    var currentText = '';

    for (var i = 0; i < words.length; i++) {
      currentText += (i == 0 ? '' : ' ') + words[i];
      setState(() {
        if (_messages.isNotEmpty && !_messages.last.isUser) {
          _messages.last.text = currentText;
        }
      });
      await Future.delayed(const Duration(milliseconds: 80));
    }

    setState(() {
      if (_messages.isNotEmpty && !_messages.last.isUser) {
        _messages.last.actions = actions;
      }
      _isTyping = false;
    });
    _scrollToBottom();
  }

  Future<void> _performDeFiAnalysis() async {
    setState(() {
      _isAnalyzing = true;
      _messageController.clear();
    });

    setState(() => _currentAnalysisStep = '🔍 Searching DeFi protocols...');
    await Future.delayed(const Duration(seconds: 2));

    setState(() => _currentAnalysisStep =
        '📊 Collecting information from 140+ services...');
    await Future.delayed(const Duration(seconds: 3));

    setState(() => _currentAnalysisStep =
        '🧮 Calculating the best options for your portfolio...');
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isAnalyzing = false;
      _currentAnalysisStep = '';
    });

    const analysisResult = """🎉 Analysis Complete!

I've analyzed 140 DeFi services in the Ethereum ecosystem and found the best options for your portfolio:

💰 Your current holdings:
• 2 WBTC (~\$90,000)
• 14 ETH (~\$42,000) 
• 25,000 USDT
• 500 DAI
• 900 USDC

🏆 Best platform: Curve.fi
Perfect for your stablecoin and wrapped assets!

Choose your investment strategy:""";

    final investmentOptions = [
      ChatAction(
        label: "🛡️ Safety (5-8% APY)",
        type: ChatActionType.safety,
        data: {
          'strategy': 'safety',
          'apy': '5-8%',
          'pools': ['USDT/USDC/DAI', 'ETH/stETH'],
          'risk': 'Low'
        },
      ),
      ChatAction(
        label: "📈 Market (12-18% APY)",
        type: ChatActionType.market,
        data: {
          'strategy': 'market',
          'apy': '12-18%',
          'pools': ['ETH/WBTC', 'USDT/USDC'],
          'risk': 'Medium'
        },
      ),
      ChatAction(
        label: "🚀 High Risk (25-45% APY)",
        type: ChatActionType.highRisk,
        data: {
          'strategy': 'high_risk',
          'apy': '25-45%',
          'pools': ['Leveraged ETH', 'Experimental pools'],
          'risk': 'High'
        },
      ),
    ];

    await _streamAIMessage(analysisResult, actions: investmentOptions);
  }

  Future<void> _showInvestmentDetails(ChatAction action) async {
    final data = action.data as Map<String, dynamic>;
    final strategy = data['strategy'];

    String detailsText;
    final nextActions = [
      ChatAction(
          label: "✅ Approve Tokens",
          type: ChatActionType.approve,
          data: {'strategy': strategy}),
      ChatAction(
          label: "🚀 Create Pool Position",
          type: ChatActionType.createPool,
          data: {'strategy': strategy}),
      ChatAction(
          label: "← Back to Options", type: ChatActionType.back, data: {}),
    ];

    switch (strategy) {
      case 'safety':
        detailsText = """🛡️ Safety Investment Strategy

✅ Recommended pools:
• Curve 3Pool (USDT/USDC/DAI) - 6% APY
• Lido stETH/ETH - 7% APY

💎 Suggested allocation:
• 26,400 USDT+USDC+DAI → 3Pool
• 5 ETH → stETH/ETH pool
• Keep 2 WBTC + 9 ETH as reserves

🔒 Risk Level: Very Low
⏱️ Withdraw: Anytime
💰 Expected yearly: \$3,000-5,000""";
        break;
      case 'market':
        detailsText = """📈 Market Strategy

🎯 Recommended pools:
• Curve ETH/WBTC pool - 15% APY  
• Curve USDT/USDC pool - 12% APY

💎 Suggested allocation:
• 10 ETH + 1.5 WBTC → ETH/WBTC pool
• 20,000 USDT + USDC → Stablecoin pool
• Keep remaining as flexible reserves

📊 Risk Level: Medium
💰 Expected yearly: \$8,000-12,000""";
        break;
      case 'high_risk':
        detailsText = """🚀 High Risk Strategy

⚡ Recommended pools:
• Leveraged ETH yield farming - 35% APY
• New protocol farming - 45% APY

💎 Suggested allocation:
• 8 ETH → Leveraged positions
• 1 WBTC → High-yield experimental pools
• Keep 50% in stables as safety net

⚠️ Risk Level: HIGH
🎯 Potential yearly: \$25,000-40,000
💀 Possible loss: Up to 50%""";
        break;
      default:
        detailsText = '';
    }

    await _streamAIMessage(detailsText, actions: nextActions);
  }

  Future<void> _handleApproval(String strategy) async {
    await _streamAIMessage(
        "🔄 Initiating token approvals for $strategy strategy...");
    await Future.delayed(const Duration(seconds: 2));

    await _streamAIMessage(
      """✅ Token approvals completed successfully!

🎯 Next step: Create your pool positions

This will:
• Deploy your tokens to selected Curve pools
• Start earning rewards immediately  
• Generate LP tokens for your positions
• Begin automatic compound farming

Ready to proceed? 🚀""",
      actions: [
        ChatAction(
            label: "🚀 Create Pool Now",
            type: ChatActionType.createPool,
            data: {'strategy': strategy}),
      ],
    );
  }

  Future<void> _handlePoolCreation(String strategy) async {
    await _streamAIMessage("🚀 Creating your liquidity pool positions...");
    await Future.delayed(const Duration(seconds: 3));

    final apyText = strategy == 'safety'
        ? '5-8%'
        : strategy == 'market'
            ? '12-18%'
            : '25-45%';

    await _streamAIMessage(
      """🎉 Congratulations! Your pools are live!

✨ Pool Creation Summary:
• Position value: \$45,000 - \$85,000  
• Estimated APY: $apyText
• LP tokens received and staked
• Auto-compound: ENABLED
• Rewards accumulating now! 

📈 Your DeFi journey has begun!
Track your earnings in real-time 👇""",
      actions: [
        ChatAction(
            label: "📱 Open Dashboard",
            type: ChatActionType.dashboard,
            data: {}),
        ChatAction(
            label: "💬 Ask Another Question",
            type: ChatActionType.newQuestion,
            data: {}),
      ],
    );
  }

  Future<void> _handleUserMessage(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
    });
    _messageController.clear();
    _scrollToBottom();

    if (text.toLowerCase().contains("help me invest") ||
        text.toLowerCase().contains("invest my tokens") ||
        text.toLowerCase().contains("wisely")) {
      await _performDeFiAnalysis();
      return;
    }

    const aiResponse =
        "I specialize in DeFi investment analysis! ✨\n\nTry asking: 'Help me invest my tokens wisely' to get personalized recommendations based on current market conditions! 🚀";
    await _streamAIMessage(aiResponse);
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = appState.currentTheme;
    final adaptivePadding = AdaptiveSize.getAdaptivePadding(context, 16);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        backgroundColor: theme.background,
        body: SafeArea(
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(adaptivePadding),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.primaryPurple.withValues(alpha: 0.1),
                      theme.background
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            theme.primaryPurple,
                            theme.primaryPurple.withValues(alpha: 0.7)
                          ],
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: SvgPicture.asset(
                          "assets/icons/ai.svg",
                          width: 30,
                          height: 30,
                          colorFilter: const ColorFilter.mode(
                              Colors.white, BlendMode.srcIn),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "DeFi AI Assistant",
                            style: TextStyle(
                              color: theme.textPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "Smart investment recommendations",
                            style: TextStyle(
                                color: theme.textSecondary, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: EdgeInsets.symmetric(
                      horizontal: adaptivePadding, vertical: 8),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[_messages.length - 1 - index];
                    return ChatBubble(
                      message: message,
                      theme: theme,
                      onActionPressed: (action) async {
                        switch (action.type) {
                          case ChatActionType.safety:
                          case ChatActionType.market:
                          case ChatActionType.highRisk:
                            await _showInvestmentDetails(action);
                            break;
                          case ChatActionType.approve:
                            await _handleApproval(action.data!['strategy']);
                            break;
                          case ChatActionType.createPool:
                            await _handlePoolCreation(action.data!['strategy']);
                            break;
                          case ChatActionType.dashboard:
                            await _streamAIMessage(
                              "🚀 Dashboard opening... Track your positions, earnings, and yield opportunities! 📊✨",
                            );
                            break;
                          case ChatActionType.newQuestion:
                            await _streamAIMessage(
                              "What else would you like to know about DeFi investing? I'm here to help! 💎",
                            );
                            break;
                          case ChatActionType.back:
                            await _performDeFiAnalysis();
                            break;
                          default:
                            break;
                        }
                      },
                    );
                  },
                ),
              ),
              if (_isAnalyzing)
                Container(
                  margin: EdgeInsets.symmetric(
                      horizontal: adaptivePadding, vertical: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.primaryPurple.withValues(alpha: 0.1),
                        theme.primaryPurple.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: theme.primaryPurple.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: theme.primaryPurple.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: theme.primaryPurple,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "AI Analysis in Progress",
                              style: TextStyle(
                                color: theme.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _currentAnalysisStep,
                              style: TextStyle(
                                  color: theme.textSecondary, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              if (_isTyping && !_isAnalyzing)
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: adaptivePadding, vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                            color: theme.primaryPurple, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "AI is typing...",
                        style: TextStyle(
                            color: theme.textSecondary,
                            fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
              Container(
                margin: EdgeInsets.all(adaptivePadding),
                decoration: BoxDecoration(
                  color: theme.cardBackground,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: theme.primaryPurple.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        enabled: !_isAnalyzing,
                        style: TextStyle(color: theme.textPrimary),
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                        decoration: InputDecoration(
                          hintText: _isAnalyzing
                              ? "Please wait while I analyze your portfolio..."
                              : "Ask me something ✨",
                          hintStyle: TextStyle(
                              color: theme.textSecondary, fontSize: 15),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.all(4),
                      child: _isAnalyzing || _isTyping
                          ? Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: theme.background.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: theme.textPrimary,
                                  ),
                                ),
                              ),
                            )
                          : GestureDetector(
                              onTap:
                                  _messageController.text.trim().isNotEmpty &&
                                          !_isTyping &&
                                          !_isAnalyzing
                                      ? () => _handleUserMessage(
                                          _messageController.text)
                                      : null,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  gradient: _messageController.text
                                              .trim()
                                              .isNotEmpty &&
                                          !_isTyping &&
                                          !_isAnalyzing
                                      ? LinearGradient(
                                          colors: [
                                            theme.background
                                                .withValues(alpha: 0.2),
                                            theme.background
                                                .withValues(alpha: 0.8)
                                          ],
                                        )
                                      : null,
                                  color: _messageController.text
                                              .trim()
                                              .isEmpty ||
                                          _isTyping ||
                                          _isAnalyzing
                                      ? theme.background.withValues(alpha: 0.3)
                                      : null,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: SvgPicture.asset(
                                    "assets/icons/right_circle_arrow.svg",
                                    width: 35,
                                    height: 35,
                                    colorFilter: const ColorFilter.mode(
                                        Colors.white, BlendMode.srcIn),
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum ChatActionType {
  invest,
  explore,
  query,
  safety,
  market,
  highRisk,
  approve,
  createPool,
  dashboard,
  newQuestion,
  back,
}

class ChatAction {
  final String label;
  final ChatActionType type;
  final Map<String, dynamic>? data;

  ChatAction({required this.label, required this.type, this.data});
}

class ChatMessage {
  String text;
  final bool isUser;
  List<ChatAction>? actions;

  ChatMessage({required this.text, required this.isUser, this.actions});
}

class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final AppTheme theme;
  final Function(ChatAction) onActionPressed;

  const ChatBubble({
    super.key,
    required this.message,
    required this.theme,
    required this.onActionPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser)
            Container(
              width: 36,
              height: 36,
              margin: const EdgeInsets.only(right: 12, top: 4),
              child: SvgPicture.asset(
                "assets/icons/bear.svg",
                width: 30,
                height: 30,
              ),
            ),
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.8),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                gradient: message.isUser
                    ? LinearGradient(
                        colors: [
                          theme.primaryPurple,
                          theme.primaryPurple.withValues(alpha: 0.8)
                        ],
                      )
                    : null,
                color: message.isUser ? null : theme.cardBackground,
                borderRadius: BorderRadius.circular(20).copyWith(
                  bottomLeft: message.isUser
                      ? const Radius.circular(20)
                      : const Radius.circular(6),
                  bottomRight: message.isUser
                      ? const Radius.circular(6)
                      : const Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: (message.isUser ? theme.primaryPurple : Colors.black)
                        .withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      color: message.isUser ? Colors.white : theme.textPrimary,
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                  if (message.actions != null && message.actions!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: message.actions!
                            .map(
                              (action) => GestureDetector(
                                onTap: () => onActionPressed(action),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 10),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        theme.primaryPurple
                                            .withValues(alpha: 0.15),
                                        theme.primaryPurple
                                            .withValues(alpha: 0.05),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: theme.primaryPurple
                                            .withValues(alpha: 0.3),
                                        width: 1),
                                  ),
                                  child: Text(
                                    action.label,
                                    style: TextStyle(
                                      color: theme.primaryPurple,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
