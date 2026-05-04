import 'dart:convert';

import '../../../core/ai/llm_provider.dart';
import '../models/practice_types.dart';

class PracticeAiService {
  PracticeAiService({required this.llm});

  final LlmProvider llm;

  Future<SentenceTask> generateSentenceTask({
    required Difficulty difficulty,
    required SentenceLength length,
    GrammarPoint? grammarPoint,
  }) async {
    final prompt = _buildSentencePrompt(difficulty, length, grammarPoint);
    final jsonText = await llm.generate(
      prompt: prompt,
      systemPrompt: _sentenceSystemPrompt,
    );
    final data = _parseJson(jsonText);
    return SentenceTask(
      chineseSentence: data['chineseSentence'] as String? ?? '',
      grammarPoint: grammarPoint,
    );
  }

  Future<MultipleChoiceTask> generateMultipleChoiceTask({
    required Difficulty difficulty,
    required SentenceLength length,
    GrammarPoint? grammarPoint,
  }) async {
    final prompt = _buildMcPrompt(difficulty, length, grammarPoint);
    final jsonText = await llm.generate(
      prompt: prompt,
      systemPrompt: _mcSystemPrompt,
    );
    final data = _parseJson(jsonText);
    final options =
        (data['options'] as List?)
            ?.map((e) => e.toString())
            .toList(growable: false) ??
        [];
    final correctIndex = data['correctOptionIndex'] as num?;
    if (correctIndex == null) {
      throw FormatException('Missing correctOptionIndex in MCQ response');
    }
    return MultipleChoiceTask(
      chineseSentence: data['chineseSentence'] as String? ?? '',
      options: options,
      correctOptionIndex: correctIndex.toInt(),
      explanation: data['explanation'] as String? ?? '',
      grammarPoint: grammarPoint,
    );
  }

  Future<PracticeFeedback> evaluateTranslation({
    required String chineseSentence,
    required String userTranslation,
    GrammarPoint? grammarPoint,
    required void Function(String chunk) onExplanationChunk,
  }) async {
    final grammarFocus = grammarPoint != null
        ? '''
The specific grammar point for this exercise is:
- Grammar: ${grammarPoint.grammarPoint}
- Meaning: ${grammarPoint.meaningCn}
- Usage: ${grammarPoint.usage}
Your explanation should pay special attention to whether the student used this grammar point correctly and naturally.
'''
        : '';

    final prompt =
        '''You are a helpful and patient Japanese language teacher. Your core task is to evaluate a student's translation based on the provided "Japanese Expression Specification Outline". Your feedback must be precise, constructive, and educational.

The original Chinese sentence is: "$chineseSentence"
The student's Japanese translation is: "${userTranslation.isEmpty ? '(No answer provided)' : userTranslation}".
$grammarFocus

$_fullOutline

**Response Format:**
Your response MUST follow this structure exactly. Do not add any other text or formatting.
1.  Start with a line containing `score:` followed by a number from 0 to 100.
2.  The next line MUST be `evaluation:` followed by a short, one-to-three-word evaluation in Chinese.
3.  The next line MUST be `correctedSentence:` followed by the corrected or most natural Japanese sentence.
4.  The fourth line MUST be `--- `.
5.  Everything after the `--- ` is the detailed explanation in Chinese Markdown.

Example:
score: 85
evaluation: 很好！
correctedSentence: 私の猫はとても可愛いです。
---
- 语法: 你的句子在语法上是正确的...
''';

    return _streamEvaluate(prompt, onExplanationChunk);
  }

  Future<PracticeFeedback> evaluateJapaneseSentence({
    required String userSentence,
    required void Function(String chunk) onExplanationChunk,
  }) async {
    final prompt =
        '''You are a helpful and patient Japanese language teacher. Your core task is to evaluate a student's Japanese sentence based on the provided "Japanese Expression Specification Outline". Your feedback must be precise, constructive, and educational.

The student's Japanese sentence is: "${userSentence.isEmpty ? '(No answer provided)' : userSentence}".

$_fullOutline

**Response Format:**
Your response MUST follow this structure exactly. Do not add any other text or formatting.
1.  Start with a line containing `score:` followed by a number from 0 to 100.
2.  The next line MUST be `evaluation:` followed by a short, one-to-three-word evaluation in Chinese.
3.  The next line MUST be `correctedSentence:` followed by the corrected or most natural Japanese sentence.
4.  The fourth line MUST be `--- `.
5.  Everything after the `--- ` is the detailed explanation in Chinese Markdown.

Example:
score: 85
evaluation: 很好！
correctedSentence: 私の猫はとても可愛いです。
---
- 语法: 你的句子在语法上是正确的...
''';

    return _streamEvaluate(prompt, onExplanationChunk);
  }

  Future<PracticeFeedback> _streamEvaluate(
    String prompt,
    void Function(String chunk) onExplanationChunk,
  ) async {
    final stream = llm.generateStream(prompt: prompt);
    final buffer = StringBuffer();
    bool headerParsed = false;
    int score = 0;
    String evaluation = '';
    String correctedSentence = '';
    final explanationBuffer = StringBuffer();

    try {
      await for (final chunk in stream) {
        if (headerParsed) {
          onExplanationChunk(chunk);
          explanationBuffer.write(chunk);
          continue;
        }

        buffer.write(chunk);
        final separator = '\n--- \n';
        final text = buffer.toString();
        final separatorIndex = text.indexOf(separator);

        if (separatorIndex != -1) {
          headerParsed = true;
          final header = text.substring(0, separatorIndex);

          final scoreMatch = RegExp(
            r'^score:\s*(\d+)',
            multiLine: true,
          ).firstMatch(header);
          final evaluationMatch = RegExp(
            r'^evaluation:\s*(.*)',
            multiLine: true,
          ).firstMatch(header);
          final correctedMatch = RegExp(
            r'^correctedSentence:\s*(.*)',
            multiLine: true,
          ).firstMatch(header);

          score = scoreMatch != null
              ? int.tryParse(scoreMatch.group(1)!) ?? 0
              : 0;
          evaluation = evaluationMatch?.group(1)?.trim() ?? '';
          correctedSentence = correctedMatch?.group(1)?.trim() ?? '';

          final firstChunk = text.substring(separatorIndex + separator.length);
          if (firstChunk.isNotEmpty) {
            onExplanationChunk(firstChunk);
            explanationBuffer.write(firstChunk);
          }
        }
      }

      // Fallback: if separator was never found in stream
      if (!headerParsed && buffer.isNotEmpty) {
        final text = buffer.toString();
        final sepIdx = text.indexOf('\n--- \n');
        final headers = sepIdx != -1 ? text.substring(0, sepIdx) : text;

        final scoreMatch = RegExp(
          r'^score:\s*(\d+)',
          multiLine: true,
        ).firstMatch(headers);
        final evaluationMatch = RegExp(
          r'^evaluation:\s*(.*)',
          multiLine: true,
        ).firstMatch(headers);
        final correctedMatch = RegExp(
          r'^correctedSentence:\s*(.*)',
          multiLine: true,
        ).firstMatch(headers);

        score = scoreMatch != null
            ? int.tryParse(scoreMatch.group(1)!) ?? 0
            : 0;
        evaluation = evaluationMatch?.group(1)?.trim() ?? '';
        correctedSentence = correctedMatch?.group(1)?.trim() ?? '';

        String explanation = '';
        if (sepIdx != -1) {
          explanation = text.substring(sepIdx + 8);
        } else {
          final lines = headers.split('\n');
          final correctedLineIndex = lines.indexWhere(
            (l) => l.startsWith('correctedSentence:'),
          );
          if (correctedLineIndex != -1 &&
              correctedLineIndex + 1 < lines.length) {
            explanation = lines
                .sublist(correctedLineIndex + 1)
                .join('\n')
                .trim();
          }
        }
        if (explanation.isNotEmpty) {
          onExplanationChunk(explanation);
          explanationBuffer.write(explanation);
        }
      }
    } catch (error) {
      onExplanationChunk(
        '\n\n**Error:** Failed to get feedback from the AI. Please try again.',
      );
    }

    return PracticeFeedback(
      score: score.clamp(0, 100),
      evaluation: evaluation.isNotEmpty ? evaluation : '评价未提供',
      correctedSentence: correctedSentence.isNotEmpty
          ? correctedSentence
          : '(AI did not provide a correction.)',
      explanation: explanationBuffer.toString(),
    );
  }

  static Map<String, dynamic> _parseJson(String text) {
    final cleaned = text
        .replaceFirst(RegExp(r'^```json\s*', multiLine: true), '')
        .replaceFirst(RegExp(r'```\s*$', multiLine: true), '')
        .trim();
    return json.decode(cleaned) as Map<String, dynamic>;
  }

  static String _buildSentencePrompt(
    Difficulty difficulty,
    SentenceLength length,
    GrammarPoint? grammarPoint,
  ) {
    final levelGuidance = switch (difficulty) {
      Difficulty.n5 =>
        'Focus on basic daily life topics like greetings, family, food, and shopping. The required Japanese translation should use simple です/ます forms and basic particles (は, が, を, に, で).',
      Difficulty.n4 =>
        'Introduce topics like hobbies, making plans, or asking for permission. The Japanese translation might involve potential form (～られる), conditional forms (～たら), or giving/receiving verbs (あげる, もらう).',
      Difficulty.n3 =>
        'Use sentences about work, school life, or expressing opinions. The Japanese translation could naturally use passive (～される), causative (～させる) forms, or expressions like ～はずだ or ～べきだ.',
      Difficulty.n2 =>
        'Create sentences related to social issues, news, or more formal situations. The Japanese translation would likely require using honorifics (敬語), or nuanced expressions like ～うちに or ～かわりに.',
      Difficulty.n1 =>
        'Generate complex sentences on abstract, technical, or literary topics. The Japanese translation should challenge the user with complex sentence structures, advanced vocabulary, and subtle grammatical nuances.',
    };

    final lengthDesc = switch (length) {
      SentenceLength.short =>
        'The sentence should be short and simple, typically under 15 Chinese characters. Focus on a single, clear idea.',
      SentenceLength.medium =>
        'The sentence should be of medium length, around 15-30 Chinese characters. It can contain one or two related ideas.',
      SentenceLength.long =>
        'The sentence should be long and more complex, over 30 Chinese characters. It should challenge the user with multiple clauses, conjunctions, or more nuanced ideas.',
    };

    final grammarInstruction = grammarPoint != null
        ? '''5.  **Grammar Focus:** The Japanese translation of the sentence MUST naturally incorporate the following grammar point:
    - **Grammar:** ${grammarPoint.grammarPoint}
    - **Meaning:** ${grammarPoint.meaningCn}
    - **Usage:** ${grammarPoint.usage}'''
        : '5.  **Grammar Focus:** Choose a common and useful grammar point appropriate for the JLPT ${difficulty.name.toUpperCase()} level and incorporate it naturally.';

    return '''You are an AI assistant that creates language learning materials. Your task is to generate a single, natural-sounding Chinese sentence for a student to translate into Japanese.

**Instructions:**
1.  **Target Level & Topic:** The sentence must be appropriate for a **JLPT ${difficulty.name.toUpperCase()}** learner. $levelGuidance
2.  **Natural Phrasing:** The sentence must sound like something from a real-life conversation, social media post, or modern blog. Avoid overly academic, stiff, or textbook-like sentences.
3.  **Sentence Length:** Adhere to the **${length.name}** length requirement.
    - **Guideline:** $lengthDesc
4.  **Goal:** Provide a practical sentence for real-world communication practice.
$grammarInstruction

**Response Format:**
Your response must be a single JSON object with the key 'chineseSentence'. Do not add any other text.
''';
  }

  static String _buildMcPrompt(
    Difficulty difficulty,
    SentenceLength length,
    GrammarPoint? grammarPoint,
  ) {
    final lengthDesc = switch (length) {
      SentenceLength.short => '少于15个中文字符，简洁',
      SentenceLength.medium => '15-30个中文字符',
      SentenceLength.long => '超过30个中文字符',
    };

    final grammarInstruction = grammarPoint != null
        ? '''
1. 核心考点: 测试以下语法点：
   - 语法: ${grammarPoint.grammarPoint}
   - 含义: ${grammarPoint.meaningCn}
   - 用法: ${grammarPoint.usage}'''
        : '1. 核心考点: 根据 JLPT ${difficulty.name.toUpperCase()} 级别，选择一个日语表达规范来测试。';

    return '''你是一位专家日语教师，正在设计选择题。

任务：
$grammarInstruction
2. 创建场景: 写一句中文，需要应用此语法点。长度要求: $lengthDesc
3. 生成选项 (共3-4个):
   - 正确答案: 一个自然且语法正确的日语翻译
   - "中式日语"干扰项: 直接逐字翻译中文的选项
   - 其他干扰项: 1-2个测试相关但错误语法的选项
4. 详细解释: 用中文写出教育性分析，解释每个选项。

$_fullOutline

你必须只返回一个JSON对象，不要包含markdown代码块、注释或其他文本。
格式：{"chineseSentence": "...", "options": ["...", "..."], "correctOptionIndex": 0, "explanation": "..."}''';
  }

  static const _sentenceSystemPrompt =
      'You are an AI assistant creating prompts for Japanese language learning materials.';

  static const _mcSystemPrompt =
      'You are an expert Japanese teacher designing multiple-choice questions.';
}

const _fullOutline = r'''
---
**《日语表达规范总纲》 (Japanese Expression Specification Outline)**
You MUST adhere to these rules when generating your evaluation. This outline is your primary guide.

一、句子结构基础

1.1 构成要素
主语（主部）：动作或状态的主体。常由名词+「が／は」构成。例：風が吹く、森さんは作家だ。
述语（谓语）：表示动作、性质、存在等的核心部分，句末收束。分为动作性（どうする）、状态性（どんなだ）、判断性（何だ）、存在性（ある・いる）。
修饰语：对主语或述语进行限定说明。时间・地点・对象・方式・性质・程度等必须位于被修饰语之前。
接续语：连接句与句的关系（顺接、转折、补充等）。如：「そして」「しかし」「それから」。
独立语：脱离句法结构、用于提示、感叹、呼唤。如：「さあ」「おい」「えっと」。

1.2 基本句式结构
结构：（修饰语）主语 + （修饰语）述语
原则：修饰语前置。述语句尾。主从句关系清晰，不能混乱嵌套。

1.3 句型分类
单句：一组主述语。例：「李さんが図書館で勉強している。」
复句（主从句）：从句位于主句前，用动词连体形修饰。原则：从句主语多用「が」，主句述语句尾收束。
并列句：多个主述语并列，通过「て」「し」「が」连接。例：「枝が伸び、葉がしげる。」

1.4 四大基本句式
判断句：～のは～です、～のは～だからです
描写句：～のは～です（危险・难易等）
能力句：～のが好き／上手／下手／苦手
存在句：～には～がある、～は～にある

二、修饰语原则与形式体言

2.1 修饰语基本原则
修饰语必须位于被修饰语之前。
顺序公式：「谁が」「何を」「いつ」「どこで」「谁と」「何で」「どうした」
排序原则：长前短后；有主谓结构的修饰语放前，无主谓结构的放后。例：「あそこに立っている髪が長い人」

2.2 修饰语接续方式
形容词修饰动词：形容词て形/く形 + 动词 (早く起きる)
副词修饰动词：副词 + 动词 (ゆっくり走る)
副词修饰形容词：副词 + 形容词 (とても美しい)
副词修饰副词：副词 + 副词 + 动词 (かなりしっかりと勉強する)

2.3 动词、形容词、名词的连体形式
动词：書く／書かない／書いた／書かなかった (書いた手紙)
イ形容词：美味しい／美味しくない／美味しかった (美味しいケーキ)
ナ形容词：元気な／元気でない／元気だった (元気な子供)
名词：休みの／休みだった (休みの日、先生である森さん)

2.4 修饰句动词的时态
有时间提示词 → 明确时态 (明日使う資料／昨日使った資料)
无时间提示词 → 依照主句动作前后判断 (食べ残ったカレーを温めて食べましょう)

2.5 修饰句主语的「が／の」转换
单一主谓结构：可以互换 (「母が作った料理」＝「母の作った料理」)
非单一结构：动作主体特定时不可换 (「母が豆腐で作った料理」✕)，状态/属性类可换 (「かかとのすり減った靴」○)

2.6 形式体言用法
こと：名词化抽象动作 (勉強することを決めた／音楽を聴くことです)
の：名词化具象感知 (鳥が鳴いているのを聞いた／母が料理をするのを見た)

三、表达习惯

3.1 話者中心性原则
事件描述以说话者或主要参与者的视点展开。当说话者受影响时，用被动句更自然 (医者に言われた、彼に待たされた)。

3.2 受身表达（被动句）
强调"我受到影响"。多用于表达受害、被动作、心理共鸣。"他让我等了"→「彼に待たされた」。

3.3 授受表达
接受他人行为：～てもらう (髪を切ってもらった)
表达感谢/期望：～てくれる (教えてくれてありがとう)
表示我为别人做：～てあげる (手伝ってあげた)

3.4 动作方向助动词
～ていく：动作离开说话者 (見ていってくれない？)
～てくる：动作朝向说话者 (呼んでくる／電話をかけてくる)

3.5 情态表达（モダリティ）
对事实的判断、态度、情绪。包含对事（断定・推测）与对人（请求・感叹）。
常见形式：だろう、かもしれない、そうだ、ようだ、ね、よ、てほしい、もらいたい等。

四、俗语与表达转换

4.1 三层表达维度
意思（字面信息）、意境（语境背景）、意图（表达目的）。外语表达要关注语境与意图，而非直译。

4.2 转化策略
理解含义 → 寻找等价日语表达 → 组合成句。例：「搅屎棍」→「引っ掻き回し屋」。

4.3 表达层次控制
中文直译「明天有点...」→ 日语自然表达「明日はちょっと...」（婉拒）
中文直译「我没空」→ 日语自然表达「あいにく予定がありまして...」（礼貌拒绝）

4.4 成语与比喻
一箭双雕 → 一石二鳥
三思而后行 → 石橋を叩いて渡る
马后炮 → 後の祭り
井底之蛙 → 井の中の蛙

五、常用句式

5.1 原因・解释: ～というのは～からです／～のは～ためです, ～だからこそ～のだ, どうりで～わけだ
5.2 条件・假设: もし～たらどうする？, ～ば～のに, ～ば～はずだ
5.3 希望・意图: すこしでも～ように, せめて～てほしい, もしよかったら～ませんか
5.4 程度・比较: ～は～よりずっと～, ～に直結している

六、一词多译语境

6.1 "只要～就～": ～限り（は）, ～さえ～ば
6.2 "除非～否则～": ～ない限り～ない
6.3 "没必要～": ～には及ばない／～ことはない／～必要はない
6.4 "既然～就～": ～からには／～以上は／～上は
6.5 "偏偏～": ～に限って／よりによって

七、常用表达

7.1 基本会话模板: 自我介绍, 年龄, 家庭, 趣味
7.2 日常会话表达: 天气, 感谢, 请求, 询问

✅【综合规范要点总结】
句法结构: 谓语句尾，修饰语前置，主从清晰
助词使用: 根据句义选择を、に、で、へ、から、まで、が、は
修饰关系: 长前短后；主谓句修饰放前
时态一致: 动词与时间提示词匹配
敬体/常体: 语境决定，用「です・ます」体现礼貌度
自然表达: 话者中心；多用被动句与授受表达
语气与情态: 根据情感、态度选用适当助动词
文化语感: 注重委婉表达与语境转换
常用句式: 善用结构化句型表达因果、假设、希望、比较
---
''';
