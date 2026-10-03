// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $WordsTable extends Words with TableInfo<$WordsTable, Word> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _englishTermMeta = const VerificationMeta(
    'englishTerm',
  );
  @override
  late final GeneratedColumn<String> englishTerm = GeneratedColumn<String>(
    'english_term',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _portugueseTranslationMeta =
      const VerificationMeta('portugueseTranslation');
  @override
  late final GeneratedColumn<String> portugueseTranslation =
      GeneratedColumn<String>(
        'portuguese_translation',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _difficultyMeta = const VerificationMeta(
    'difficulty',
  );
  @override
  late final GeneratedColumn<int> difficulty = GeneratedColumn<int>(
    'difficulty',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recommendedLevelMeta = const VerificationMeta(
    'recommendedLevel',
  );
  @override
  late final GeneratedColumn<int> recommendedLevel = GeneratedColumn<int>(
    'recommended_level',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _exampleSentenceEnMeta = const VerificationMeta(
    'exampleSentenceEn',
  );
  @override
  late final GeneratedColumn<String> exampleSentenceEn =
      GeneratedColumn<String>(
        'example_sentence_en',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _exampleSentencePtMeta = const VerificationMeta(
    'exampleSentencePt',
  );
  @override
  late final GeneratedColumn<String> exampleSentencePt =
      GeneratedColumn<String>(
        'example_sentence_pt',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _sensesJsonMeta = const VerificationMeta(
    'sensesJson',
  );
  @override
  late final GeneratedColumn<String> sensesJson = GeneratedColumn<String>(
    'senses_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pronunciationAudioAssetMeta =
      const VerificationMeta('pronunciationAudioAsset');
  @override
  late final GeneratedColumn<String> pronunciationAudioAsset =
      GeneratedColumn<String>(
        'pronunciation_audio_asset',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _imageAssetMeta = const VerificationMeta(
    'imageAsset',
  );
  @override
  late final GeneratedColumn<String> imageAsset = GeneratedColumn<String>(
    'image_asset',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    englishTerm,
    portugueseTranslation,
    category,
    difficulty,
    recommendedLevel,
    exampleSentenceEn,
    exampleSentencePt,
    sensesJson,
    pronunciationAudioAsset,
    imageAsset,
    isActive,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'words';
  @override
  VerificationContext validateIntegrity(
    Insertable<Word> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('english_term')) {
      context.handle(
        _englishTermMeta,
        englishTerm.isAcceptableOrUnknown(
          data['english_term']!,
          _englishTermMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_englishTermMeta);
    }
    if (data.containsKey('portuguese_translation')) {
      context.handle(
        _portugueseTranslationMeta,
        portugueseTranslation.isAcceptableOrUnknown(
          data['portuguese_translation']!,
          _portugueseTranslationMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_portugueseTranslationMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('difficulty')) {
      context.handle(
        _difficultyMeta,
        difficulty.isAcceptableOrUnknown(data['difficulty']!, _difficultyMeta),
      );
    } else if (isInserting) {
      context.missing(_difficultyMeta);
    }
    if (data.containsKey('recommended_level')) {
      context.handle(
        _recommendedLevelMeta,
        recommendedLevel.isAcceptableOrUnknown(
          data['recommended_level']!,
          _recommendedLevelMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_recommendedLevelMeta);
    }
    if (data.containsKey('example_sentence_en')) {
      context.handle(
        _exampleSentenceEnMeta,
        exampleSentenceEn.isAcceptableOrUnknown(
          data['example_sentence_en']!,
          _exampleSentenceEnMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_exampleSentenceEnMeta);
    }
    if (data.containsKey('example_sentence_pt')) {
      context.handle(
        _exampleSentencePtMeta,
        exampleSentencePt.isAcceptableOrUnknown(
          data['example_sentence_pt']!,
          _exampleSentencePtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_exampleSentencePtMeta);
    }
    if (data.containsKey('senses_json')) {
      context.handle(
        _sensesJsonMeta,
        sensesJson.isAcceptableOrUnknown(data['senses_json']!, _sensesJsonMeta),
      );
    }
    if (data.containsKey('pronunciation_audio_asset')) {
      context.handle(
        _pronunciationAudioAssetMeta,
        pronunciationAudioAsset.isAcceptableOrUnknown(
          data['pronunciation_audio_asset']!,
          _pronunciationAudioAssetMeta,
        ),
      );
    }
    if (data.containsKey('image_asset')) {
      context.handle(
        _imageAssetMeta,
        imageAsset.isAcceptableOrUnknown(data['image_asset']!, _imageAssetMeta),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Word map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Word(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      englishTerm: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}english_term'],
      )!,
      portugueseTranslation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}portuguese_translation'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      difficulty: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}difficulty'],
      )!,
      recommendedLevel: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}recommended_level'],
      )!,
      exampleSentenceEn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}example_sentence_en'],
      )!,
      exampleSentencePt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}example_sentence_pt'],
      )!,
      sensesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}senses_json'],
      ),
      pronunciationAudioAsset: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pronunciation_audio_asset'],
      ),
      imageAsset: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_asset'],
      ),
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
    );
  }

  @override
  $WordsTable createAlias(String alias) {
    return $WordsTable(attachedDatabase, alias);
  }
}

class Word extends DataClass implements Insertable<Word> {
  final String id;
  final String englishTerm;
  final String portugueseTranslation;
  final String category;
  final int difficulty;
  final int recommendedLevel;
  final String exampleSentenceEn;
  final String exampleSentencePt;

  /// Optional JSON list of every sense of the word (`light` -> luz /
  /// leve), each `{pt, pos, example_en, example_pt}`. The first entry is
  /// the primary sense and always matches [portugueseTranslation], which
  /// stays the single answer quizzes grade against. Null for words with
  /// only one sense. Added in schema v2.
  final String? sensesJson;
  final String? pronunciationAudioAsset;
  final String? imageAsset;
  final bool isActive;
  const Word({
    required this.id,
    required this.englishTerm,
    required this.portugueseTranslation,
    required this.category,
    required this.difficulty,
    required this.recommendedLevel,
    required this.exampleSentenceEn,
    required this.exampleSentencePt,
    this.sensesJson,
    this.pronunciationAudioAsset,
    this.imageAsset,
    required this.isActive,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['english_term'] = Variable<String>(englishTerm);
    map['portuguese_translation'] = Variable<String>(portugueseTranslation);
    map['category'] = Variable<String>(category);
    map['difficulty'] = Variable<int>(difficulty);
    map['recommended_level'] = Variable<int>(recommendedLevel);
    map['example_sentence_en'] = Variable<String>(exampleSentenceEn);
    map['example_sentence_pt'] = Variable<String>(exampleSentencePt);
    if (!nullToAbsent || sensesJson != null) {
      map['senses_json'] = Variable<String>(sensesJson);
    }
    if (!nullToAbsent || pronunciationAudioAsset != null) {
      map['pronunciation_audio_asset'] = Variable<String>(
        pronunciationAudioAsset,
      );
    }
    if (!nullToAbsent || imageAsset != null) {
      map['image_asset'] = Variable<String>(imageAsset);
    }
    map['is_active'] = Variable<bool>(isActive);
    return map;
  }

  WordsCompanion toCompanion(bool nullToAbsent) {
    return WordsCompanion(
      id: Value(id),
      englishTerm: Value(englishTerm),
      portugueseTranslation: Value(portugueseTranslation),
      category: Value(category),
      difficulty: Value(difficulty),
      recommendedLevel: Value(recommendedLevel),
      exampleSentenceEn: Value(exampleSentenceEn),
      exampleSentencePt: Value(exampleSentencePt),
      sensesJson: sensesJson == null && nullToAbsent
          ? const Value.absent()
          : Value(sensesJson),
      pronunciationAudioAsset: pronunciationAudioAsset == null && nullToAbsent
          ? const Value.absent()
          : Value(pronunciationAudioAsset),
      imageAsset: imageAsset == null && nullToAbsent
          ? const Value.absent()
          : Value(imageAsset),
      isActive: Value(isActive),
    );
  }

  factory Word.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Word(
      id: serializer.fromJson<String>(json['id']),
      englishTerm: serializer.fromJson<String>(json['englishTerm']),
      portugueseTranslation: serializer.fromJson<String>(
        json['portugueseTranslation'],
      ),
      category: serializer.fromJson<String>(json['category']),
      difficulty: serializer.fromJson<int>(json['difficulty']),
      recommendedLevel: serializer.fromJson<int>(json['recommendedLevel']),
      exampleSentenceEn: serializer.fromJson<String>(json['exampleSentenceEn']),
      exampleSentencePt: serializer.fromJson<String>(json['exampleSentencePt']),
      sensesJson: serializer.fromJson<String?>(json['sensesJson']),
      pronunciationAudioAsset: serializer.fromJson<String?>(
        json['pronunciationAudioAsset'],
      ),
      imageAsset: serializer.fromJson<String?>(json['imageAsset']),
      isActive: serializer.fromJson<bool>(json['isActive']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'englishTerm': serializer.toJson<String>(englishTerm),
      'portugueseTranslation': serializer.toJson<String>(portugueseTranslation),
      'category': serializer.toJson<String>(category),
      'difficulty': serializer.toJson<int>(difficulty),
      'recommendedLevel': serializer.toJson<int>(recommendedLevel),
      'exampleSentenceEn': serializer.toJson<String>(exampleSentenceEn),
      'exampleSentencePt': serializer.toJson<String>(exampleSentencePt),
      'sensesJson': serializer.toJson<String?>(sensesJson),
      'pronunciationAudioAsset': serializer.toJson<String?>(
        pronunciationAudioAsset,
      ),
      'imageAsset': serializer.toJson<String?>(imageAsset),
      'isActive': serializer.toJson<bool>(isActive),
    };
  }

  Word copyWith({
    String? id,
    String? englishTerm,
    String? portugueseTranslation,
    String? category,
    int? difficulty,
    int? recommendedLevel,
    String? exampleSentenceEn,
    String? exampleSentencePt,
    Value<String?> sensesJson = const Value.absent(),
    Value<String?> pronunciationAudioAsset = const Value.absent(),
    Value<String?> imageAsset = const Value.absent(),
    bool? isActive,
  }) => Word(
    id: id ?? this.id,
    englishTerm: englishTerm ?? this.englishTerm,
    portugueseTranslation: portugueseTranslation ?? this.portugueseTranslation,
    category: category ?? this.category,
    difficulty: difficulty ?? this.difficulty,
    recommendedLevel: recommendedLevel ?? this.recommendedLevel,
    exampleSentenceEn: exampleSentenceEn ?? this.exampleSentenceEn,
    exampleSentencePt: exampleSentencePt ?? this.exampleSentencePt,
    sensesJson: sensesJson.present ? sensesJson.value : this.sensesJson,
    pronunciationAudioAsset: pronunciationAudioAsset.present
        ? pronunciationAudioAsset.value
        : this.pronunciationAudioAsset,
    imageAsset: imageAsset.present ? imageAsset.value : this.imageAsset,
    isActive: isActive ?? this.isActive,
  );
  Word copyWithCompanion(WordsCompanion data) {
    return Word(
      id: data.id.present ? data.id.value : this.id,
      englishTerm: data.englishTerm.present
          ? data.englishTerm.value
          : this.englishTerm,
      portugueseTranslation: data.portugueseTranslation.present
          ? data.portugueseTranslation.value
          : this.portugueseTranslation,
      category: data.category.present ? data.category.value : this.category,
      difficulty: data.difficulty.present
          ? data.difficulty.value
          : this.difficulty,
      recommendedLevel: data.recommendedLevel.present
          ? data.recommendedLevel.value
          : this.recommendedLevel,
      exampleSentenceEn: data.exampleSentenceEn.present
          ? data.exampleSentenceEn.value
          : this.exampleSentenceEn,
      exampleSentencePt: data.exampleSentencePt.present
          ? data.exampleSentencePt.value
          : this.exampleSentencePt,
      sensesJson: data.sensesJson.present
          ? data.sensesJson.value
          : this.sensesJson,
      pronunciationAudioAsset: data.pronunciationAudioAsset.present
          ? data.pronunciationAudioAsset.value
          : this.pronunciationAudioAsset,
      imageAsset: data.imageAsset.present
          ? data.imageAsset.value
          : this.imageAsset,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Word(')
          ..write('id: $id, ')
          ..write('englishTerm: $englishTerm, ')
          ..write('portugueseTranslation: $portugueseTranslation, ')
          ..write('category: $category, ')
          ..write('difficulty: $difficulty, ')
          ..write('recommendedLevel: $recommendedLevel, ')
          ..write('exampleSentenceEn: $exampleSentenceEn, ')
          ..write('exampleSentencePt: $exampleSentencePt, ')
          ..write('sensesJson: $sensesJson, ')
          ..write('pronunciationAudioAsset: $pronunciationAudioAsset, ')
          ..write('imageAsset: $imageAsset, ')
          ..write('isActive: $isActive')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    englishTerm,
    portugueseTranslation,
    category,
    difficulty,
    recommendedLevel,
    exampleSentenceEn,
    exampleSentencePt,
    sensesJson,
    pronunciationAudioAsset,
    imageAsset,
    isActive,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Word &&
          other.id == this.id &&
          other.englishTerm == this.englishTerm &&
          other.portugueseTranslation == this.portugueseTranslation &&
          other.category == this.category &&
          other.difficulty == this.difficulty &&
          other.recommendedLevel == this.recommendedLevel &&
          other.exampleSentenceEn == this.exampleSentenceEn &&
          other.exampleSentencePt == this.exampleSentencePt &&
          other.sensesJson == this.sensesJson &&
          other.pronunciationAudioAsset == this.pronunciationAudioAsset &&
          other.imageAsset == this.imageAsset &&
          other.isActive == this.isActive);
}

class WordsCompanion extends UpdateCompanion<Word> {
  final Value<String> id;
  final Value<String> englishTerm;
  final Value<String> portugueseTranslation;
  final Value<String> category;
  final Value<int> difficulty;
  final Value<int> recommendedLevel;
  final Value<String> exampleSentenceEn;
  final Value<String> exampleSentencePt;
  final Value<String?> sensesJson;
  final Value<String?> pronunciationAudioAsset;
  final Value<String?> imageAsset;
  final Value<bool> isActive;
  final Value<int> rowid;
  const WordsCompanion({
    this.id = const Value.absent(),
    this.englishTerm = const Value.absent(),
    this.portugueseTranslation = const Value.absent(),
    this.category = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.recommendedLevel = const Value.absent(),
    this.exampleSentenceEn = const Value.absent(),
    this.exampleSentencePt = const Value.absent(),
    this.sensesJson = const Value.absent(),
    this.pronunciationAudioAsset = const Value.absent(),
    this.imageAsset = const Value.absent(),
    this.isActive = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WordsCompanion.insert({
    required String id,
    required String englishTerm,
    required String portugueseTranslation,
    required String category,
    required int difficulty,
    required int recommendedLevel,
    required String exampleSentenceEn,
    required String exampleSentencePt,
    this.sensesJson = const Value.absent(),
    this.pronunciationAudioAsset = const Value.absent(),
    this.imageAsset = const Value.absent(),
    this.isActive = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       englishTerm = Value(englishTerm),
       portugueseTranslation = Value(portugueseTranslation),
       category = Value(category),
       difficulty = Value(difficulty),
       recommendedLevel = Value(recommendedLevel),
       exampleSentenceEn = Value(exampleSentenceEn),
       exampleSentencePt = Value(exampleSentencePt);
  static Insertable<Word> custom({
    Expression<String>? id,
    Expression<String>? englishTerm,
    Expression<String>? portugueseTranslation,
    Expression<String>? category,
    Expression<int>? difficulty,
    Expression<int>? recommendedLevel,
    Expression<String>? exampleSentenceEn,
    Expression<String>? exampleSentencePt,
    Expression<String>? sensesJson,
    Expression<String>? pronunciationAudioAsset,
    Expression<String>? imageAsset,
    Expression<bool>? isActive,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (englishTerm != null) 'english_term': englishTerm,
      if (portugueseTranslation != null)
        'portuguese_translation': portugueseTranslation,
      if (category != null) 'category': category,
      if (difficulty != null) 'difficulty': difficulty,
      if (recommendedLevel != null) 'recommended_level': recommendedLevel,
      if (exampleSentenceEn != null) 'example_sentence_en': exampleSentenceEn,
      if (exampleSentencePt != null) 'example_sentence_pt': exampleSentencePt,
      if (sensesJson != null) 'senses_json': sensesJson,
      if (pronunciationAudioAsset != null)
        'pronunciation_audio_asset': pronunciationAudioAsset,
      if (imageAsset != null) 'image_asset': imageAsset,
      if (isActive != null) 'is_active': isActive,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WordsCompanion copyWith({
    Value<String>? id,
    Value<String>? englishTerm,
    Value<String>? portugueseTranslation,
    Value<String>? category,
    Value<int>? difficulty,
    Value<int>? recommendedLevel,
    Value<String>? exampleSentenceEn,
    Value<String>? exampleSentencePt,
    Value<String?>? sensesJson,
    Value<String?>? pronunciationAudioAsset,
    Value<String?>? imageAsset,
    Value<bool>? isActive,
    Value<int>? rowid,
  }) {
    return WordsCompanion(
      id: id ?? this.id,
      englishTerm: englishTerm ?? this.englishTerm,
      portugueseTranslation:
          portugueseTranslation ?? this.portugueseTranslation,
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
      recommendedLevel: recommendedLevel ?? this.recommendedLevel,
      exampleSentenceEn: exampleSentenceEn ?? this.exampleSentenceEn,
      exampleSentencePt: exampleSentencePt ?? this.exampleSentencePt,
      sensesJson: sensesJson ?? this.sensesJson,
      pronunciationAudioAsset:
          pronunciationAudioAsset ?? this.pronunciationAudioAsset,
      imageAsset: imageAsset ?? this.imageAsset,
      isActive: isActive ?? this.isActive,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (englishTerm.present) {
      map['english_term'] = Variable<String>(englishTerm.value);
    }
    if (portugueseTranslation.present) {
      map['portuguese_translation'] = Variable<String>(
        portugueseTranslation.value,
      );
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (difficulty.present) {
      map['difficulty'] = Variable<int>(difficulty.value);
    }
    if (recommendedLevel.present) {
      map['recommended_level'] = Variable<int>(recommendedLevel.value);
    }
    if (exampleSentenceEn.present) {
      map['example_sentence_en'] = Variable<String>(exampleSentenceEn.value);
    }
    if (exampleSentencePt.present) {
      map['example_sentence_pt'] = Variable<String>(exampleSentencePt.value);
    }
    if (sensesJson.present) {
      map['senses_json'] = Variable<String>(sensesJson.value);
    }
    if (pronunciationAudioAsset.present) {
      map['pronunciation_audio_asset'] = Variable<String>(
        pronunciationAudioAsset.value,
      );
    }
    if (imageAsset.present) {
      map['image_asset'] = Variable<String>(imageAsset.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WordsCompanion(')
          ..write('id: $id, ')
          ..write('englishTerm: $englishTerm, ')
          ..write('portugueseTranslation: $portugueseTranslation, ')
          ..write('category: $category, ')
          ..write('difficulty: $difficulty, ')
          ..write('recommendedLevel: $recommendedLevel, ')
          ..write('exampleSentenceEn: $exampleSentenceEn, ')
          ..write('exampleSentencePt: $exampleSentencePt, ')
          ..write('sensesJson: $sensesJson, ')
          ..write('pronunciationAudioAsset: $pronunciationAudioAsset, ')
          ..write('imageAsset: $imageAsset, ')
          ..write('isActive: $isActive, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WordProgressTable extends WordProgress
    with TableInfo<$WordProgressTable, WordProgressRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WordProgressTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _wordIdMeta = const VerificationMeta('wordId');
  @override
  late final GeneratedColumn<String> wordId = GeneratedColumn<String>(
    'word_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES words (id)',
    ),
  );
  static const VerificationMeta _masteryLevelMeta = const VerificationMeta(
    'masteryLevel',
  );
  @override
  late final GeneratedColumn<int> masteryLevel = GeneratedColumn<int>(
    'mastery_level',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _correctCountMeta = const VerificationMeta(
    'correctCount',
  );
  @override
  late final GeneratedColumn<int> correctCount = GeneratedColumn<int>(
    'correct_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _incorrectCountMeta = const VerificationMeta(
    'incorrectCount',
  );
  @override
  late final GeneratedColumn<int> incorrectCount = GeneratedColumn<int>(
    'incorrect_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _currentStreakMeta = const VerificationMeta(
    'currentStreak',
  );
  @override
  late final GeneratedColumn<int> currentStreak = GeneratedColumn<int>(
    'current_streak',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastSeenAtMeta = const VerificationMeta(
    'lastSeenAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSeenAt = GeneratedColumn<DateTime>(
    'last_seen_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nextReviewAtMeta = const VerificationMeta(
    'nextReviewAt',
  );
  @override
  late final GeneratedColumn<DateTime> nextReviewAt = GeneratedColumn<DateTime>(
    'next_review_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastResultCorrectMeta = const VerificationMeta(
    'lastResultCorrect',
  );
  @override
  late final GeneratedColumn<bool> lastResultCorrect = GeneratedColumn<bool>(
    'last_result_correct',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("last_result_correct" IN (0, 1))',
    ),
  );
  static const VerificationMeta _timesShownTotalMeta = const VerificationMeta(
    'timesShownTotal',
  );
  @override
  late final GeneratedColumn<int> timesShownTotal = GeneratedColumn<int>(
    'times_shown_total',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _introducedAtMeta = const VerificationMeta(
    'introducedAt',
  );
  @override
  late final GeneratedColumn<DateTime> introducedAt = GeneratedColumn<DateTime>(
    'introduced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    wordId,
    masteryLevel,
    correctCount,
    incorrectCount,
    currentStreak,
    lastSeenAt,
    nextReviewAt,
    lastResultCorrect,
    timesShownTotal,
    introducedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'word_progress';
  @override
  VerificationContext validateIntegrity(
    Insertable<WordProgressRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('word_id')) {
      context.handle(
        _wordIdMeta,
        wordId.isAcceptableOrUnknown(data['word_id']!, _wordIdMeta),
      );
    } else if (isInserting) {
      context.missing(_wordIdMeta);
    }
    if (data.containsKey('mastery_level')) {
      context.handle(
        _masteryLevelMeta,
        masteryLevel.isAcceptableOrUnknown(
          data['mastery_level']!,
          _masteryLevelMeta,
        ),
      );
    }
    if (data.containsKey('correct_count')) {
      context.handle(
        _correctCountMeta,
        correctCount.isAcceptableOrUnknown(
          data['correct_count']!,
          _correctCountMeta,
        ),
      );
    }
    if (data.containsKey('incorrect_count')) {
      context.handle(
        _incorrectCountMeta,
        incorrectCount.isAcceptableOrUnknown(
          data['incorrect_count']!,
          _incorrectCountMeta,
        ),
      );
    }
    if (data.containsKey('current_streak')) {
      context.handle(
        _currentStreakMeta,
        currentStreak.isAcceptableOrUnknown(
          data['current_streak']!,
          _currentStreakMeta,
        ),
      );
    }
    if (data.containsKey('last_seen_at')) {
      context.handle(
        _lastSeenAtMeta,
        lastSeenAt.isAcceptableOrUnknown(
          data['last_seen_at']!,
          _lastSeenAtMeta,
        ),
      );
    }
    if (data.containsKey('next_review_at')) {
      context.handle(
        _nextReviewAtMeta,
        nextReviewAt.isAcceptableOrUnknown(
          data['next_review_at']!,
          _nextReviewAtMeta,
        ),
      );
    }
    if (data.containsKey('last_result_correct')) {
      context.handle(
        _lastResultCorrectMeta,
        lastResultCorrect.isAcceptableOrUnknown(
          data['last_result_correct']!,
          _lastResultCorrectMeta,
        ),
      );
    }
    if (data.containsKey('times_shown_total')) {
      context.handle(
        _timesShownTotalMeta,
        timesShownTotal.isAcceptableOrUnknown(
          data['times_shown_total']!,
          _timesShownTotalMeta,
        ),
      );
    }
    if (data.containsKey('introduced_at')) {
      context.handle(
        _introducedAtMeta,
        introducedAt.isAcceptableOrUnknown(
          data['introduced_at']!,
          _introducedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {wordId};
  @override
  WordProgressRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WordProgressRow(
      wordId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}word_id'],
      )!,
      masteryLevel: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}mastery_level'],
      )!,
      correctCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}correct_count'],
      )!,
      incorrectCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}incorrect_count'],
      )!,
      currentStreak: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}current_streak'],
      )!,
      lastSeenAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_seen_at'],
      ),
      nextReviewAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}next_review_at'],
      ),
      lastResultCorrect: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}last_result_correct'],
      ),
      timesShownTotal: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}times_shown_total'],
      )!,
      introducedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}introduced_at'],
      ),
    );
  }

  @override
  $WordProgressTable createAlias(String alias) {
    return $WordProgressTable(attachedDatabase, alias);
  }
}

class WordProgressRow extends DataClass implements Insertable<WordProgressRow> {
  final String wordId;
  final int masteryLevel;
  final int correctCount;
  final int incorrectCount;
  final int currentStreak;
  final DateTime? lastSeenAt;
  final DateTime? nextReviewAt;
  final bool? lastResultCorrect;
  final int timesShownTotal;
  final DateTime? introducedAt;
  const WordProgressRow({
    required this.wordId,
    required this.masteryLevel,
    required this.correctCount,
    required this.incorrectCount,
    required this.currentStreak,
    this.lastSeenAt,
    this.nextReviewAt,
    this.lastResultCorrect,
    required this.timesShownTotal,
    this.introducedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['word_id'] = Variable<String>(wordId);
    map['mastery_level'] = Variable<int>(masteryLevel);
    map['correct_count'] = Variable<int>(correctCount);
    map['incorrect_count'] = Variable<int>(incorrectCount);
    map['current_streak'] = Variable<int>(currentStreak);
    if (!nullToAbsent || lastSeenAt != null) {
      map['last_seen_at'] = Variable<DateTime>(lastSeenAt);
    }
    if (!nullToAbsent || nextReviewAt != null) {
      map['next_review_at'] = Variable<DateTime>(nextReviewAt);
    }
    if (!nullToAbsent || lastResultCorrect != null) {
      map['last_result_correct'] = Variable<bool>(lastResultCorrect);
    }
    map['times_shown_total'] = Variable<int>(timesShownTotal);
    if (!nullToAbsent || introducedAt != null) {
      map['introduced_at'] = Variable<DateTime>(introducedAt);
    }
    return map;
  }

  WordProgressCompanion toCompanion(bool nullToAbsent) {
    return WordProgressCompanion(
      wordId: Value(wordId),
      masteryLevel: Value(masteryLevel),
      correctCount: Value(correctCount),
      incorrectCount: Value(incorrectCount),
      currentStreak: Value(currentStreak),
      lastSeenAt: lastSeenAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSeenAt),
      nextReviewAt: nextReviewAt == null && nullToAbsent
          ? const Value.absent()
          : Value(nextReviewAt),
      lastResultCorrect: lastResultCorrect == null && nullToAbsent
          ? const Value.absent()
          : Value(lastResultCorrect),
      timesShownTotal: Value(timesShownTotal),
      introducedAt: introducedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(introducedAt),
    );
  }

  factory WordProgressRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WordProgressRow(
      wordId: serializer.fromJson<String>(json['wordId']),
      masteryLevel: serializer.fromJson<int>(json['masteryLevel']),
      correctCount: serializer.fromJson<int>(json['correctCount']),
      incorrectCount: serializer.fromJson<int>(json['incorrectCount']),
      currentStreak: serializer.fromJson<int>(json['currentStreak']),
      lastSeenAt: serializer.fromJson<DateTime?>(json['lastSeenAt']),
      nextReviewAt: serializer.fromJson<DateTime?>(json['nextReviewAt']),
      lastResultCorrect: serializer.fromJson<bool?>(json['lastResultCorrect']),
      timesShownTotal: serializer.fromJson<int>(json['timesShownTotal']),
      introducedAt: serializer.fromJson<DateTime?>(json['introducedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'wordId': serializer.toJson<String>(wordId),
      'masteryLevel': serializer.toJson<int>(masteryLevel),
      'correctCount': serializer.toJson<int>(correctCount),
      'incorrectCount': serializer.toJson<int>(incorrectCount),
      'currentStreak': serializer.toJson<int>(currentStreak),
      'lastSeenAt': serializer.toJson<DateTime?>(lastSeenAt),
      'nextReviewAt': serializer.toJson<DateTime?>(nextReviewAt),
      'lastResultCorrect': serializer.toJson<bool?>(lastResultCorrect),
      'timesShownTotal': serializer.toJson<int>(timesShownTotal),
      'introducedAt': serializer.toJson<DateTime?>(introducedAt),
    };
  }

  WordProgressRow copyWith({
    String? wordId,
    int? masteryLevel,
    int? correctCount,
    int? incorrectCount,
    int? currentStreak,
    Value<DateTime?> lastSeenAt = const Value.absent(),
    Value<DateTime?> nextReviewAt = const Value.absent(),
    Value<bool?> lastResultCorrect = const Value.absent(),
    int? timesShownTotal,
    Value<DateTime?> introducedAt = const Value.absent(),
  }) => WordProgressRow(
    wordId: wordId ?? this.wordId,
    masteryLevel: masteryLevel ?? this.masteryLevel,
    correctCount: correctCount ?? this.correctCount,
    incorrectCount: incorrectCount ?? this.incorrectCount,
    currentStreak: currentStreak ?? this.currentStreak,
    lastSeenAt: lastSeenAt.present ? lastSeenAt.value : this.lastSeenAt,
    nextReviewAt: nextReviewAt.present ? nextReviewAt.value : this.nextReviewAt,
    lastResultCorrect: lastResultCorrect.present
        ? lastResultCorrect.value
        : this.lastResultCorrect,
    timesShownTotal: timesShownTotal ?? this.timesShownTotal,
    introducedAt: introducedAt.present ? introducedAt.value : this.introducedAt,
  );
  WordProgressRow copyWithCompanion(WordProgressCompanion data) {
    return WordProgressRow(
      wordId: data.wordId.present ? data.wordId.value : this.wordId,
      masteryLevel: data.masteryLevel.present
          ? data.masteryLevel.value
          : this.masteryLevel,
      correctCount: data.correctCount.present
          ? data.correctCount.value
          : this.correctCount,
      incorrectCount: data.incorrectCount.present
          ? data.incorrectCount.value
          : this.incorrectCount,
      currentStreak: data.currentStreak.present
          ? data.currentStreak.value
          : this.currentStreak,
      lastSeenAt: data.lastSeenAt.present
          ? data.lastSeenAt.value
          : this.lastSeenAt,
      nextReviewAt: data.nextReviewAt.present
          ? data.nextReviewAt.value
          : this.nextReviewAt,
      lastResultCorrect: data.lastResultCorrect.present
          ? data.lastResultCorrect.value
          : this.lastResultCorrect,
      timesShownTotal: data.timesShownTotal.present
          ? data.timesShownTotal.value
          : this.timesShownTotal,
      introducedAt: data.introducedAt.present
          ? data.introducedAt.value
          : this.introducedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WordProgressRow(')
          ..write('wordId: $wordId, ')
          ..write('masteryLevel: $masteryLevel, ')
          ..write('correctCount: $correctCount, ')
          ..write('incorrectCount: $incorrectCount, ')
          ..write('currentStreak: $currentStreak, ')
          ..write('lastSeenAt: $lastSeenAt, ')
          ..write('nextReviewAt: $nextReviewAt, ')
          ..write('lastResultCorrect: $lastResultCorrect, ')
          ..write('timesShownTotal: $timesShownTotal, ')
          ..write('introducedAt: $introducedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    wordId,
    masteryLevel,
    correctCount,
    incorrectCount,
    currentStreak,
    lastSeenAt,
    nextReviewAt,
    lastResultCorrect,
    timesShownTotal,
    introducedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WordProgressRow &&
          other.wordId == this.wordId &&
          other.masteryLevel == this.masteryLevel &&
          other.correctCount == this.correctCount &&
          other.incorrectCount == this.incorrectCount &&
          other.currentStreak == this.currentStreak &&
          other.lastSeenAt == this.lastSeenAt &&
          other.nextReviewAt == this.nextReviewAt &&
          other.lastResultCorrect == this.lastResultCorrect &&
          other.timesShownTotal == this.timesShownTotal &&
          other.introducedAt == this.introducedAt);
}

class WordProgressCompanion extends UpdateCompanion<WordProgressRow> {
  final Value<String> wordId;
  final Value<int> masteryLevel;
  final Value<int> correctCount;
  final Value<int> incorrectCount;
  final Value<int> currentStreak;
  final Value<DateTime?> lastSeenAt;
  final Value<DateTime?> nextReviewAt;
  final Value<bool?> lastResultCorrect;
  final Value<int> timesShownTotal;
  final Value<DateTime?> introducedAt;
  final Value<int> rowid;
  const WordProgressCompanion({
    this.wordId = const Value.absent(),
    this.masteryLevel = const Value.absent(),
    this.correctCount = const Value.absent(),
    this.incorrectCount = const Value.absent(),
    this.currentStreak = const Value.absent(),
    this.lastSeenAt = const Value.absent(),
    this.nextReviewAt = const Value.absent(),
    this.lastResultCorrect = const Value.absent(),
    this.timesShownTotal = const Value.absent(),
    this.introducedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WordProgressCompanion.insert({
    required String wordId,
    this.masteryLevel = const Value.absent(),
    this.correctCount = const Value.absent(),
    this.incorrectCount = const Value.absent(),
    this.currentStreak = const Value.absent(),
    this.lastSeenAt = const Value.absent(),
    this.nextReviewAt = const Value.absent(),
    this.lastResultCorrect = const Value.absent(),
    this.timesShownTotal = const Value.absent(),
    this.introducedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : wordId = Value(wordId);
  static Insertable<WordProgressRow> custom({
    Expression<String>? wordId,
    Expression<int>? masteryLevel,
    Expression<int>? correctCount,
    Expression<int>? incorrectCount,
    Expression<int>? currentStreak,
    Expression<DateTime>? lastSeenAt,
    Expression<DateTime>? nextReviewAt,
    Expression<bool>? lastResultCorrect,
    Expression<int>? timesShownTotal,
    Expression<DateTime>? introducedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (wordId != null) 'word_id': wordId,
      if (masteryLevel != null) 'mastery_level': masteryLevel,
      if (correctCount != null) 'correct_count': correctCount,
      if (incorrectCount != null) 'incorrect_count': incorrectCount,
      if (currentStreak != null) 'current_streak': currentStreak,
      if (lastSeenAt != null) 'last_seen_at': lastSeenAt,
      if (nextReviewAt != null) 'next_review_at': nextReviewAt,
      if (lastResultCorrect != null) 'last_result_correct': lastResultCorrect,
      if (timesShownTotal != null) 'times_shown_total': timesShownTotal,
      if (introducedAt != null) 'introduced_at': introducedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WordProgressCompanion copyWith({
    Value<String>? wordId,
    Value<int>? masteryLevel,
    Value<int>? correctCount,
    Value<int>? incorrectCount,
    Value<int>? currentStreak,
    Value<DateTime?>? lastSeenAt,
    Value<DateTime?>? nextReviewAt,
    Value<bool?>? lastResultCorrect,
    Value<int>? timesShownTotal,
    Value<DateTime?>? introducedAt,
    Value<int>? rowid,
  }) {
    return WordProgressCompanion(
      wordId: wordId ?? this.wordId,
      masteryLevel: masteryLevel ?? this.masteryLevel,
      correctCount: correctCount ?? this.correctCount,
      incorrectCount: incorrectCount ?? this.incorrectCount,
      currentStreak: currentStreak ?? this.currentStreak,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      nextReviewAt: nextReviewAt ?? this.nextReviewAt,
      lastResultCorrect: lastResultCorrect ?? this.lastResultCorrect,
      timesShownTotal: timesShownTotal ?? this.timesShownTotal,
      introducedAt: introducedAt ?? this.introducedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (wordId.present) {
      map['word_id'] = Variable<String>(wordId.value);
    }
    if (masteryLevel.present) {
      map['mastery_level'] = Variable<int>(masteryLevel.value);
    }
    if (correctCount.present) {
      map['correct_count'] = Variable<int>(correctCount.value);
    }
    if (incorrectCount.present) {
      map['incorrect_count'] = Variable<int>(incorrectCount.value);
    }
    if (currentStreak.present) {
      map['current_streak'] = Variable<int>(currentStreak.value);
    }
    if (lastSeenAt.present) {
      map['last_seen_at'] = Variable<DateTime>(lastSeenAt.value);
    }
    if (nextReviewAt.present) {
      map['next_review_at'] = Variable<DateTime>(nextReviewAt.value);
    }
    if (lastResultCorrect.present) {
      map['last_result_correct'] = Variable<bool>(lastResultCorrect.value);
    }
    if (timesShownTotal.present) {
      map['times_shown_total'] = Variable<int>(timesShownTotal.value);
    }
    if (introducedAt.present) {
      map['introduced_at'] = Variable<DateTime>(introducedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WordProgressCompanion(')
          ..write('wordId: $wordId, ')
          ..write('masteryLevel: $masteryLevel, ')
          ..write('correctCount: $correctCount, ')
          ..write('incorrectCount: $incorrectCount, ')
          ..write('currentStreak: $currentStreak, ')
          ..write('lastSeenAt: $lastSeenAt, ')
          ..write('nextReviewAt: $nextReviewAt, ')
          ..write('lastResultCorrect: $lastResultCorrect, ')
          ..write('timesShownTotal: $timesShownTotal, ')
          ..write('introducedAt: $introducedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UserProfileTable extends UserProfile
    with TableInfo<$UserProfileTable, UserProfileRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserProfileTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _totalXpMeta = const VerificationMeta(
    'totalXp',
  );
  @override
  late final GeneratedColumn<int> totalXp = GeneratedColumn<int>(
    'total_xp',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _currentLevelMeta = const VerificationMeta(
    'currentLevel',
  );
  @override
  late final GeneratedColumn<int> currentLevel = GeneratedColumn<int>(
    'current_level',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _currentStreakDaysMeta = const VerificationMeta(
    'currentStreakDays',
  );
  @override
  late final GeneratedColumn<int> currentStreakDays = GeneratedColumn<int>(
    'current_streak_days',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _longestStreakDaysMeta = const VerificationMeta(
    'longestStreakDays',
  );
  @override
  late final GeneratedColumn<int> longestStreakDays = GeneratedColumn<int>(
    'longest_streak_days',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastStudyDateMeta = const VerificationMeta(
    'lastStudyDate',
  );
  @override
  late final GeneratedColumn<String> lastStudyDate = GeneratedColumn<String>(
    'last_study_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    totalXp,
    currentLevel,
    currentStreakDays,
    longestStreakDays,
    lastStudyDate,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_profile';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserProfileRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('total_xp')) {
      context.handle(
        _totalXpMeta,
        totalXp.isAcceptableOrUnknown(data['total_xp']!, _totalXpMeta),
      );
    }
    if (data.containsKey('current_level')) {
      context.handle(
        _currentLevelMeta,
        currentLevel.isAcceptableOrUnknown(
          data['current_level']!,
          _currentLevelMeta,
        ),
      );
    }
    if (data.containsKey('current_streak_days')) {
      context.handle(
        _currentStreakDaysMeta,
        currentStreakDays.isAcceptableOrUnknown(
          data['current_streak_days']!,
          _currentStreakDaysMeta,
        ),
      );
    }
    if (data.containsKey('longest_streak_days')) {
      context.handle(
        _longestStreakDaysMeta,
        longestStreakDays.isAcceptableOrUnknown(
          data['longest_streak_days']!,
          _longestStreakDaysMeta,
        ),
      );
    }
    if (data.containsKey('last_study_date')) {
      context.handle(
        _lastStudyDateMeta,
        lastStudyDate.isAcceptableOrUnknown(
          data['last_study_date']!,
          _lastStudyDateMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserProfileRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserProfileRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      totalXp: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_xp'],
      )!,
      currentLevel: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}current_level'],
      )!,
      currentStreakDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}current_streak_days'],
      )!,
      longestStreakDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}longest_streak_days'],
      )!,
      lastStudyDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_study_date'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $UserProfileTable createAlias(String alias) {
    return $UserProfileTable(attachedDatabase, alias);
  }
}

class UserProfileRow extends DataClass implements Insertable<UserProfileRow> {
  final int id;
  final int totalXp;
  final int currentLevel;
  final int currentStreakDays;
  final int longestStreakDays;

  /// Local calendar date (`YYYY-MM-DD`) of the last study day, stored as
  /// text to avoid timezone-boundary bugs when comparing "same day".
  final String? lastStudyDate;
  final DateTime createdAt;
  const UserProfileRow({
    required this.id,
    required this.totalXp,
    required this.currentLevel,
    required this.currentStreakDays,
    required this.longestStreakDays,
    this.lastStudyDate,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['total_xp'] = Variable<int>(totalXp);
    map['current_level'] = Variable<int>(currentLevel);
    map['current_streak_days'] = Variable<int>(currentStreakDays);
    map['longest_streak_days'] = Variable<int>(longestStreakDays);
    if (!nullToAbsent || lastStudyDate != null) {
      map['last_study_date'] = Variable<String>(lastStudyDate);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  UserProfileCompanion toCompanion(bool nullToAbsent) {
    return UserProfileCompanion(
      id: Value(id),
      totalXp: Value(totalXp),
      currentLevel: Value(currentLevel),
      currentStreakDays: Value(currentStreakDays),
      longestStreakDays: Value(longestStreakDays),
      lastStudyDate: lastStudyDate == null && nullToAbsent
          ? const Value.absent()
          : Value(lastStudyDate),
      createdAt: Value(createdAt),
    );
  }

  factory UserProfileRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserProfileRow(
      id: serializer.fromJson<int>(json['id']),
      totalXp: serializer.fromJson<int>(json['totalXp']),
      currentLevel: serializer.fromJson<int>(json['currentLevel']),
      currentStreakDays: serializer.fromJson<int>(json['currentStreakDays']),
      longestStreakDays: serializer.fromJson<int>(json['longestStreakDays']),
      lastStudyDate: serializer.fromJson<String?>(json['lastStudyDate']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'totalXp': serializer.toJson<int>(totalXp),
      'currentLevel': serializer.toJson<int>(currentLevel),
      'currentStreakDays': serializer.toJson<int>(currentStreakDays),
      'longestStreakDays': serializer.toJson<int>(longestStreakDays),
      'lastStudyDate': serializer.toJson<String?>(lastStudyDate),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  UserProfileRow copyWith({
    int? id,
    int? totalXp,
    int? currentLevel,
    int? currentStreakDays,
    int? longestStreakDays,
    Value<String?> lastStudyDate = const Value.absent(),
    DateTime? createdAt,
  }) => UserProfileRow(
    id: id ?? this.id,
    totalXp: totalXp ?? this.totalXp,
    currentLevel: currentLevel ?? this.currentLevel,
    currentStreakDays: currentStreakDays ?? this.currentStreakDays,
    longestStreakDays: longestStreakDays ?? this.longestStreakDays,
    lastStudyDate: lastStudyDate.present
        ? lastStudyDate.value
        : this.lastStudyDate,
    createdAt: createdAt ?? this.createdAt,
  );
  UserProfileRow copyWithCompanion(UserProfileCompanion data) {
    return UserProfileRow(
      id: data.id.present ? data.id.value : this.id,
      totalXp: data.totalXp.present ? data.totalXp.value : this.totalXp,
      currentLevel: data.currentLevel.present
          ? data.currentLevel.value
          : this.currentLevel,
      currentStreakDays: data.currentStreakDays.present
          ? data.currentStreakDays.value
          : this.currentStreakDays,
      longestStreakDays: data.longestStreakDays.present
          ? data.longestStreakDays.value
          : this.longestStreakDays,
      lastStudyDate: data.lastStudyDate.present
          ? data.lastStudyDate.value
          : this.lastStudyDate,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserProfileRow(')
          ..write('id: $id, ')
          ..write('totalXp: $totalXp, ')
          ..write('currentLevel: $currentLevel, ')
          ..write('currentStreakDays: $currentStreakDays, ')
          ..write('longestStreakDays: $longestStreakDays, ')
          ..write('lastStudyDate: $lastStudyDate, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    totalXp,
    currentLevel,
    currentStreakDays,
    longestStreakDays,
    lastStudyDate,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserProfileRow &&
          other.id == this.id &&
          other.totalXp == this.totalXp &&
          other.currentLevel == this.currentLevel &&
          other.currentStreakDays == this.currentStreakDays &&
          other.longestStreakDays == this.longestStreakDays &&
          other.lastStudyDate == this.lastStudyDate &&
          other.createdAt == this.createdAt);
}

class UserProfileCompanion extends UpdateCompanion<UserProfileRow> {
  final Value<int> id;
  final Value<int> totalXp;
  final Value<int> currentLevel;
  final Value<int> currentStreakDays;
  final Value<int> longestStreakDays;
  final Value<String?> lastStudyDate;
  final Value<DateTime> createdAt;
  const UserProfileCompanion({
    this.id = const Value.absent(),
    this.totalXp = const Value.absent(),
    this.currentLevel = const Value.absent(),
    this.currentStreakDays = const Value.absent(),
    this.longestStreakDays = const Value.absent(),
    this.lastStudyDate = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  UserProfileCompanion.insert({
    this.id = const Value.absent(),
    this.totalXp = const Value.absent(),
    this.currentLevel = const Value.absent(),
    this.currentStreakDays = const Value.absent(),
    this.longestStreakDays = const Value.absent(),
    this.lastStudyDate = const Value.absent(),
    required DateTime createdAt,
  }) : createdAt = Value(createdAt);
  static Insertable<UserProfileRow> custom({
    Expression<int>? id,
    Expression<int>? totalXp,
    Expression<int>? currentLevel,
    Expression<int>? currentStreakDays,
    Expression<int>? longestStreakDays,
    Expression<String>? lastStudyDate,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (totalXp != null) 'total_xp': totalXp,
      if (currentLevel != null) 'current_level': currentLevel,
      if (currentStreakDays != null) 'current_streak_days': currentStreakDays,
      if (longestStreakDays != null) 'longest_streak_days': longestStreakDays,
      if (lastStudyDate != null) 'last_study_date': lastStudyDate,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  UserProfileCompanion copyWith({
    Value<int>? id,
    Value<int>? totalXp,
    Value<int>? currentLevel,
    Value<int>? currentStreakDays,
    Value<int>? longestStreakDays,
    Value<String?>? lastStudyDate,
    Value<DateTime>? createdAt,
  }) {
    return UserProfileCompanion(
      id: id ?? this.id,
      totalXp: totalXp ?? this.totalXp,
      currentLevel: currentLevel ?? this.currentLevel,
      currentStreakDays: currentStreakDays ?? this.currentStreakDays,
      longestStreakDays: longestStreakDays ?? this.longestStreakDays,
      lastStudyDate: lastStudyDate ?? this.lastStudyDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (totalXp.present) {
      map['total_xp'] = Variable<int>(totalXp.value);
    }
    if (currentLevel.present) {
      map['current_level'] = Variable<int>(currentLevel.value);
    }
    if (currentStreakDays.present) {
      map['current_streak_days'] = Variable<int>(currentStreakDays.value);
    }
    if (longestStreakDays.present) {
      map['longest_streak_days'] = Variable<int>(longestStreakDays.value);
    }
    if (lastStudyDate.present) {
      map['last_study_date'] = Variable<String>(lastStudyDate.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserProfileCompanion(')
          ..write('id: $id, ')
          ..write('totalXp: $totalXp, ')
          ..write('currentLevel: $currentLevel, ')
          ..write('currentStreakDays: $currentStreakDays, ')
          ..write('longestStreakDays: $longestStreakDays, ')
          ..write('lastStudyDate: $lastStudyDate, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $DailyActivityLogTable extends DailyActivityLog
    with TableInfo<$DailyActivityLogTable, DailyActivityLogRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DailyActivityLogTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _studyDateMeta = const VerificationMeta(
    'studyDate',
  );
  @override
  late final GeneratedColumn<String> studyDate = GeneratedColumn<String>(
    'study_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _exercisesCompletedMeta =
      const VerificationMeta('exercisesCompleted');
  @override
  late final GeneratedColumn<int> exercisesCompleted = GeneratedColumn<int>(
    'exercises_completed',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _correctCountMeta = const VerificationMeta(
    'correctCount',
  );
  @override
  late final GeneratedColumn<int> correctCount = GeneratedColumn<int>(
    'correct_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _xpEarnedMeta = const VerificationMeta(
    'xpEarned',
  );
  @override
  late final GeneratedColumn<int> xpEarned = GeneratedColumn<int>(
    'xp_earned',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _countsAsActiveDayMeta = const VerificationMeta(
    'countsAsActiveDay',
  );
  @override
  late final GeneratedColumn<bool> countsAsActiveDay = GeneratedColumn<bool>(
    'counts_as_active_day',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("counts_as_active_day" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    studyDate,
    exercisesCompleted,
    correctCount,
    xpEarned,
    countsAsActiveDay,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'daily_activity_log';
  @override
  VerificationContext validateIntegrity(
    Insertable<DailyActivityLogRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('study_date')) {
      context.handle(
        _studyDateMeta,
        studyDate.isAcceptableOrUnknown(data['study_date']!, _studyDateMeta),
      );
    } else if (isInserting) {
      context.missing(_studyDateMeta);
    }
    if (data.containsKey('exercises_completed')) {
      context.handle(
        _exercisesCompletedMeta,
        exercisesCompleted.isAcceptableOrUnknown(
          data['exercises_completed']!,
          _exercisesCompletedMeta,
        ),
      );
    }
    if (data.containsKey('correct_count')) {
      context.handle(
        _correctCountMeta,
        correctCount.isAcceptableOrUnknown(
          data['correct_count']!,
          _correctCountMeta,
        ),
      );
    }
    if (data.containsKey('xp_earned')) {
      context.handle(
        _xpEarnedMeta,
        xpEarned.isAcceptableOrUnknown(data['xp_earned']!, _xpEarnedMeta),
      );
    }
    if (data.containsKey('counts_as_active_day')) {
      context.handle(
        _countsAsActiveDayMeta,
        countsAsActiveDay.isAcceptableOrUnknown(
          data['counts_as_active_day']!,
          _countsAsActiveDayMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {studyDate};
  @override
  DailyActivityLogRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DailyActivityLogRow(
      studyDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}study_date'],
      )!,
      exercisesCompleted: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}exercises_completed'],
      )!,
      correctCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}correct_count'],
      )!,
      xpEarned: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}xp_earned'],
      )!,
      countsAsActiveDay: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}counts_as_active_day'],
      )!,
    );
  }

  @override
  $DailyActivityLogTable createAlias(String alias) {
    return $DailyActivityLogTable(attachedDatabase, alias);
  }
}

class DailyActivityLogRow extends DataClass
    implements Insertable<DailyActivityLogRow> {
  /// Local calendar date, `YYYY-MM-DD`. Text, not a DateTime column, so
  /// "same day" comparisons don't depend on time-of-day/timezone.
  final String studyDate;
  final int exercisesCompleted;
  final int correctCount;
  final int xpEarned;

  /// Flips to true once [exercisesCompleted] crosses the active-day
  /// threshold for that date; recomputed on each write within the day.
  final bool countsAsActiveDay;
  const DailyActivityLogRow({
    required this.studyDate,
    required this.exercisesCompleted,
    required this.correctCount,
    required this.xpEarned,
    required this.countsAsActiveDay,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['study_date'] = Variable<String>(studyDate);
    map['exercises_completed'] = Variable<int>(exercisesCompleted);
    map['correct_count'] = Variable<int>(correctCount);
    map['xp_earned'] = Variable<int>(xpEarned);
    map['counts_as_active_day'] = Variable<bool>(countsAsActiveDay);
    return map;
  }

  DailyActivityLogCompanion toCompanion(bool nullToAbsent) {
    return DailyActivityLogCompanion(
      studyDate: Value(studyDate),
      exercisesCompleted: Value(exercisesCompleted),
      correctCount: Value(correctCount),
      xpEarned: Value(xpEarned),
      countsAsActiveDay: Value(countsAsActiveDay),
    );
  }

  factory DailyActivityLogRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DailyActivityLogRow(
      studyDate: serializer.fromJson<String>(json['studyDate']),
      exercisesCompleted: serializer.fromJson<int>(json['exercisesCompleted']),
      correctCount: serializer.fromJson<int>(json['correctCount']),
      xpEarned: serializer.fromJson<int>(json['xpEarned']),
      countsAsActiveDay: serializer.fromJson<bool>(json['countsAsActiveDay']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'studyDate': serializer.toJson<String>(studyDate),
      'exercisesCompleted': serializer.toJson<int>(exercisesCompleted),
      'correctCount': serializer.toJson<int>(correctCount),
      'xpEarned': serializer.toJson<int>(xpEarned),
      'countsAsActiveDay': serializer.toJson<bool>(countsAsActiveDay),
    };
  }

  DailyActivityLogRow copyWith({
    String? studyDate,
    int? exercisesCompleted,
    int? correctCount,
    int? xpEarned,
    bool? countsAsActiveDay,
  }) => DailyActivityLogRow(
    studyDate: studyDate ?? this.studyDate,
    exercisesCompleted: exercisesCompleted ?? this.exercisesCompleted,
    correctCount: correctCount ?? this.correctCount,
    xpEarned: xpEarned ?? this.xpEarned,
    countsAsActiveDay: countsAsActiveDay ?? this.countsAsActiveDay,
  );
  DailyActivityLogRow copyWithCompanion(DailyActivityLogCompanion data) {
    return DailyActivityLogRow(
      studyDate: data.studyDate.present ? data.studyDate.value : this.studyDate,
      exercisesCompleted: data.exercisesCompleted.present
          ? data.exercisesCompleted.value
          : this.exercisesCompleted,
      correctCount: data.correctCount.present
          ? data.correctCount.value
          : this.correctCount,
      xpEarned: data.xpEarned.present ? data.xpEarned.value : this.xpEarned,
      countsAsActiveDay: data.countsAsActiveDay.present
          ? data.countsAsActiveDay.value
          : this.countsAsActiveDay,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DailyActivityLogRow(')
          ..write('studyDate: $studyDate, ')
          ..write('exercisesCompleted: $exercisesCompleted, ')
          ..write('correctCount: $correctCount, ')
          ..write('xpEarned: $xpEarned, ')
          ..write('countsAsActiveDay: $countsAsActiveDay')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    studyDate,
    exercisesCompleted,
    correctCount,
    xpEarned,
    countsAsActiveDay,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DailyActivityLogRow &&
          other.studyDate == this.studyDate &&
          other.exercisesCompleted == this.exercisesCompleted &&
          other.correctCount == this.correctCount &&
          other.xpEarned == this.xpEarned &&
          other.countsAsActiveDay == this.countsAsActiveDay);
}

class DailyActivityLogCompanion extends UpdateCompanion<DailyActivityLogRow> {
  final Value<String> studyDate;
  final Value<int> exercisesCompleted;
  final Value<int> correctCount;
  final Value<int> xpEarned;
  final Value<bool> countsAsActiveDay;
  final Value<int> rowid;
  const DailyActivityLogCompanion({
    this.studyDate = const Value.absent(),
    this.exercisesCompleted = const Value.absent(),
    this.correctCount = const Value.absent(),
    this.xpEarned = const Value.absent(),
    this.countsAsActiveDay = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DailyActivityLogCompanion.insert({
    required String studyDate,
    this.exercisesCompleted = const Value.absent(),
    this.correctCount = const Value.absent(),
    this.xpEarned = const Value.absent(),
    this.countsAsActiveDay = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : studyDate = Value(studyDate);
  static Insertable<DailyActivityLogRow> custom({
    Expression<String>? studyDate,
    Expression<int>? exercisesCompleted,
    Expression<int>? correctCount,
    Expression<int>? xpEarned,
    Expression<bool>? countsAsActiveDay,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (studyDate != null) 'study_date': studyDate,
      if (exercisesCompleted != null) 'exercises_completed': exercisesCompleted,
      if (correctCount != null) 'correct_count': correctCount,
      if (xpEarned != null) 'xp_earned': xpEarned,
      if (countsAsActiveDay != null) 'counts_as_active_day': countsAsActiveDay,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DailyActivityLogCompanion copyWith({
    Value<String>? studyDate,
    Value<int>? exercisesCompleted,
    Value<int>? correctCount,
    Value<int>? xpEarned,
    Value<bool>? countsAsActiveDay,
    Value<int>? rowid,
  }) {
    return DailyActivityLogCompanion(
      studyDate: studyDate ?? this.studyDate,
      exercisesCompleted: exercisesCompleted ?? this.exercisesCompleted,
      correctCount: correctCount ?? this.correctCount,
      xpEarned: xpEarned ?? this.xpEarned,
      countsAsActiveDay: countsAsActiveDay ?? this.countsAsActiveDay,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (studyDate.present) {
      map['study_date'] = Variable<String>(studyDate.value);
    }
    if (exercisesCompleted.present) {
      map['exercises_completed'] = Variable<int>(exercisesCompleted.value);
    }
    if (correctCount.present) {
      map['correct_count'] = Variable<int>(correctCount.value);
    }
    if (xpEarned.present) {
      map['xp_earned'] = Variable<int>(xpEarned.value);
    }
    if (countsAsActiveDay.present) {
      map['counts_as_active_day'] = Variable<bool>(countsAsActiveDay.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DailyActivityLogCompanion(')
          ..write('studyDate: $studyDate, ')
          ..write('exercisesCompleted: $exercisesCompleted, ')
          ..write('correctCount: $correctCount, ')
          ..write('xpEarned: $xpEarned, ')
          ..write('countsAsActiveDay: $countsAsActiveDay, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ExerciseAttemptsTable extends ExerciseAttempts
    with TableInfo<$ExerciseAttemptsTable, ExerciseAttempt> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExerciseAttemptsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _wordIdMeta = const VerificationMeta('wordId');
  @override
  late final GeneratedColumn<String> wordId = GeneratedColumn<String>(
    'word_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES words (id)',
    ),
  );
  static const VerificationMeta _exerciseTypeMeta = const VerificationMeta(
    'exerciseType',
  );
  @override
  late final GeneratedColumn<String> exerciseType = GeneratedColumn<String>(
    'exercise_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sessionKindMeta = const VerificationMeta(
    'sessionKind',
  );
  @override
  late final GeneratedColumn<String> sessionKind = GeneratedColumn<String>(
    'session_kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _wasCorrectMeta = const VerificationMeta(
    'wasCorrect',
  );
  @override
  late final GeneratedColumn<bool> wasCorrect = GeneratedColumn<bool>(
    'was_correct',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("was_correct" IN (0, 1))',
    ),
  );
  static const VerificationMeta _userAnswerMeta = const VerificationMeta(
    'userAnswer',
  );
  @override
  late final GeneratedColumn<String> userAnswer = GeneratedColumn<String>(
    'user_answer',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _masteryLevelBeforeMeta =
      const VerificationMeta('masteryLevelBefore');
  @override
  late final GeneratedColumn<int> masteryLevelBefore = GeneratedColumn<int>(
    'mastery_level_before',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _masteryLevelAfterMeta = const VerificationMeta(
    'masteryLevelAfter',
  );
  @override
  late final GeneratedColumn<int> masteryLevelAfter = GeneratedColumn<int>(
    'mastery_level_after',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _xpAwardedMeta = const VerificationMeta(
    'xpAwarded',
  );
  @override
  late final GeneratedColumn<int> xpAwarded = GeneratedColumn<int>(
    'xp_awarded',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _responseTimeMsMeta = const VerificationMeta(
    'responseTimeMs',
  );
  @override
  late final GeneratedColumn<int> responseTimeMs = GeneratedColumn<int>(
    'response_time_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _attemptedAtMeta = const VerificationMeta(
    'attemptedAt',
  );
  @override
  late final GeneratedColumn<DateTime> attemptedAt = GeneratedColumn<DateTime>(
    'attempted_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    wordId,
    exerciseType,
    sessionId,
    sessionKind,
    wasCorrect,
    userAnswer,
    masteryLevelBefore,
    masteryLevelAfter,
    xpAwarded,
    responseTimeMs,
    attemptedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'exercise_attempts';
  @override
  VerificationContext validateIntegrity(
    Insertable<ExerciseAttempt> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('word_id')) {
      context.handle(
        _wordIdMeta,
        wordId.isAcceptableOrUnknown(data['word_id']!, _wordIdMeta),
      );
    }
    if (data.containsKey('exercise_type')) {
      context.handle(
        _exerciseTypeMeta,
        exerciseType.isAcceptableOrUnknown(
          data['exercise_type']!,
          _exerciseTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_exerciseTypeMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('session_kind')) {
      context.handle(
        _sessionKindMeta,
        sessionKind.isAcceptableOrUnknown(
          data['session_kind']!,
          _sessionKindMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sessionKindMeta);
    }
    if (data.containsKey('was_correct')) {
      context.handle(
        _wasCorrectMeta,
        wasCorrect.isAcceptableOrUnknown(data['was_correct']!, _wasCorrectMeta),
      );
    } else if (isInserting) {
      context.missing(_wasCorrectMeta);
    }
    if (data.containsKey('user_answer')) {
      context.handle(
        _userAnswerMeta,
        userAnswer.isAcceptableOrUnknown(data['user_answer']!, _userAnswerMeta),
      );
    }
    if (data.containsKey('mastery_level_before')) {
      context.handle(
        _masteryLevelBeforeMeta,
        masteryLevelBefore.isAcceptableOrUnknown(
          data['mastery_level_before']!,
          _masteryLevelBeforeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_masteryLevelBeforeMeta);
    }
    if (data.containsKey('mastery_level_after')) {
      context.handle(
        _masteryLevelAfterMeta,
        masteryLevelAfter.isAcceptableOrUnknown(
          data['mastery_level_after']!,
          _masteryLevelAfterMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_masteryLevelAfterMeta);
    }
    if (data.containsKey('xp_awarded')) {
      context.handle(
        _xpAwardedMeta,
        xpAwarded.isAcceptableOrUnknown(data['xp_awarded']!, _xpAwardedMeta),
      );
    }
    if (data.containsKey('response_time_ms')) {
      context.handle(
        _responseTimeMsMeta,
        responseTimeMs.isAcceptableOrUnknown(
          data['response_time_ms']!,
          _responseTimeMsMeta,
        ),
      );
    }
    if (data.containsKey('attempted_at')) {
      context.handle(
        _attemptedAtMeta,
        attemptedAt.isAcceptableOrUnknown(
          data['attempted_at']!,
          _attemptedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_attemptedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ExerciseAttempt map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExerciseAttempt(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      wordId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}word_id'],
      ),
      exerciseType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exercise_type'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      sessionKind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_kind'],
      )!,
      wasCorrect: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}was_correct'],
      )!,
      userAnswer: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_answer'],
      ),
      masteryLevelBefore: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}mastery_level_before'],
      )!,
      masteryLevelAfter: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}mastery_level_after'],
      )!,
      xpAwarded: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}xp_awarded'],
      )!,
      responseTimeMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}response_time_ms'],
      ),
      attemptedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}attempted_at'],
      )!,
    );
  }

  @override
  $ExerciseAttemptsTable createAlias(String alias) {
    return $ExerciseAttemptsTable(attachedDatabase, alias);
  }
}

class ExerciseAttempt extends DataClass implements Insertable<ExerciseAttempt> {
  final int id;

  /// Nullable on purpose: not every exercise type maps to exactly one
  /// word (e.g. a future matching/grammar-only item).
  final String? wordId;
  final String exerciseType;
  final String sessionId;
  final String sessionKind;
  final bool wasCorrect;
  final String? userAnswer;
  final int masteryLevelBefore;
  final int masteryLevelAfter;
  final int xpAwarded;
  final int? responseTimeMs;
  final DateTime attemptedAt;
  const ExerciseAttempt({
    required this.id,
    this.wordId,
    required this.exerciseType,
    required this.sessionId,
    required this.sessionKind,
    required this.wasCorrect,
    this.userAnswer,
    required this.masteryLevelBefore,
    required this.masteryLevelAfter,
    required this.xpAwarded,
    this.responseTimeMs,
    required this.attemptedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || wordId != null) {
      map['word_id'] = Variable<String>(wordId);
    }
    map['exercise_type'] = Variable<String>(exerciseType);
    map['session_id'] = Variable<String>(sessionId);
    map['session_kind'] = Variable<String>(sessionKind);
    map['was_correct'] = Variable<bool>(wasCorrect);
    if (!nullToAbsent || userAnswer != null) {
      map['user_answer'] = Variable<String>(userAnswer);
    }
    map['mastery_level_before'] = Variable<int>(masteryLevelBefore);
    map['mastery_level_after'] = Variable<int>(masteryLevelAfter);
    map['xp_awarded'] = Variable<int>(xpAwarded);
    if (!nullToAbsent || responseTimeMs != null) {
      map['response_time_ms'] = Variable<int>(responseTimeMs);
    }
    map['attempted_at'] = Variable<DateTime>(attemptedAt);
    return map;
  }

  ExerciseAttemptsCompanion toCompanion(bool nullToAbsent) {
    return ExerciseAttemptsCompanion(
      id: Value(id),
      wordId: wordId == null && nullToAbsent
          ? const Value.absent()
          : Value(wordId),
      exerciseType: Value(exerciseType),
      sessionId: Value(sessionId),
      sessionKind: Value(sessionKind),
      wasCorrect: Value(wasCorrect),
      userAnswer: userAnswer == null && nullToAbsent
          ? const Value.absent()
          : Value(userAnswer),
      masteryLevelBefore: Value(masteryLevelBefore),
      masteryLevelAfter: Value(masteryLevelAfter),
      xpAwarded: Value(xpAwarded),
      responseTimeMs: responseTimeMs == null && nullToAbsent
          ? const Value.absent()
          : Value(responseTimeMs),
      attemptedAt: Value(attemptedAt),
    );
  }

  factory ExerciseAttempt.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExerciseAttempt(
      id: serializer.fromJson<int>(json['id']),
      wordId: serializer.fromJson<String?>(json['wordId']),
      exerciseType: serializer.fromJson<String>(json['exerciseType']),
      sessionId: serializer.fromJson<String>(json['sessionId']),
      sessionKind: serializer.fromJson<String>(json['sessionKind']),
      wasCorrect: serializer.fromJson<bool>(json['wasCorrect']),
      userAnswer: serializer.fromJson<String?>(json['userAnswer']),
      masteryLevelBefore: serializer.fromJson<int>(json['masteryLevelBefore']),
      masteryLevelAfter: serializer.fromJson<int>(json['masteryLevelAfter']),
      xpAwarded: serializer.fromJson<int>(json['xpAwarded']),
      responseTimeMs: serializer.fromJson<int?>(json['responseTimeMs']),
      attemptedAt: serializer.fromJson<DateTime>(json['attemptedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'wordId': serializer.toJson<String?>(wordId),
      'exerciseType': serializer.toJson<String>(exerciseType),
      'sessionId': serializer.toJson<String>(sessionId),
      'sessionKind': serializer.toJson<String>(sessionKind),
      'wasCorrect': serializer.toJson<bool>(wasCorrect),
      'userAnswer': serializer.toJson<String?>(userAnswer),
      'masteryLevelBefore': serializer.toJson<int>(masteryLevelBefore),
      'masteryLevelAfter': serializer.toJson<int>(masteryLevelAfter),
      'xpAwarded': serializer.toJson<int>(xpAwarded),
      'responseTimeMs': serializer.toJson<int?>(responseTimeMs),
      'attemptedAt': serializer.toJson<DateTime>(attemptedAt),
    };
  }

  ExerciseAttempt copyWith({
    int? id,
    Value<String?> wordId = const Value.absent(),
    String? exerciseType,
    String? sessionId,
    String? sessionKind,
    bool? wasCorrect,
    Value<String?> userAnswer = const Value.absent(),
    int? masteryLevelBefore,
    int? masteryLevelAfter,
    int? xpAwarded,
    Value<int?> responseTimeMs = const Value.absent(),
    DateTime? attemptedAt,
  }) => ExerciseAttempt(
    id: id ?? this.id,
    wordId: wordId.present ? wordId.value : this.wordId,
    exerciseType: exerciseType ?? this.exerciseType,
    sessionId: sessionId ?? this.sessionId,
    sessionKind: sessionKind ?? this.sessionKind,
    wasCorrect: wasCorrect ?? this.wasCorrect,
    userAnswer: userAnswer.present ? userAnswer.value : this.userAnswer,
    masteryLevelBefore: masteryLevelBefore ?? this.masteryLevelBefore,
    masteryLevelAfter: masteryLevelAfter ?? this.masteryLevelAfter,
    xpAwarded: xpAwarded ?? this.xpAwarded,
    responseTimeMs: responseTimeMs.present
        ? responseTimeMs.value
        : this.responseTimeMs,
    attemptedAt: attemptedAt ?? this.attemptedAt,
  );
  ExerciseAttempt copyWithCompanion(ExerciseAttemptsCompanion data) {
    return ExerciseAttempt(
      id: data.id.present ? data.id.value : this.id,
      wordId: data.wordId.present ? data.wordId.value : this.wordId,
      exerciseType: data.exerciseType.present
          ? data.exerciseType.value
          : this.exerciseType,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      sessionKind: data.sessionKind.present
          ? data.sessionKind.value
          : this.sessionKind,
      wasCorrect: data.wasCorrect.present
          ? data.wasCorrect.value
          : this.wasCorrect,
      userAnswer: data.userAnswer.present
          ? data.userAnswer.value
          : this.userAnswer,
      masteryLevelBefore: data.masteryLevelBefore.present
          ? data.masteryLevelBefore.value
          : this.masteryLevelBefore,
      masteryLevelAfter: data.masteryLevelAfter.present
          ? data.masteryLevelAfter.value
          : this.masteryLevelAfter,
      xpAwarded: data.xpAwarded.present ? data.xpAwarded.value : this.xpAwarded,
      responseTimeMs: data.responseTimeMs.present
          ? data.responseTimeMs.value
          : this.responseTimeMs,
      attemptedAt: data.attemptedAt.present
          ? data.attemptedAt.value
          : this.attemptedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExerciseAttempt(')
          ..write('id: $id, ')
          ..write('wordId: $wordId, ')
          ..write('exerciseType: $exerciseType, ')
          ..write('sessionId: $sessionId, ')
          ..write('sessionKind: $sessionKind, ')
          ..write('wasCorrect: $wasCorrect, ')
          ..write('userAnswer: $userAnswer, ')
          ..write('masteryLevelBefore: $masteryLevelBefore, ')
          ..write('masteryLevelAfter: $masteryLevelAfter, ')
          ..write('xpAwarded: $xpAwarded, ')
          ..write('responseTimeMs: $responseTimeMs, ')
          ..write('attemptedAt: $attemptedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    wordId,
    exerciseType,
    sessionId,
    sessionKind,
    wasCorrect,
    userAnswer,
    masteryLevelBefore,
    masteryLevelAfter,
    xpAwarded,
    responseTimeMs,
    attemptedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExerciseAttempt &&
          other.id == this.id &&
          other.wordId == this.wordId &&
          other.exerciseType == this.exerciseType &&
          other.sessionId == this.sessionId &&
          other.sessionKind == this.sessionKind &&
          other.wasCorrect == this.wasCorrect &&
          other.userAnswer == this.userAnswer &&
          other.masteryLevelBefore == this.masteryLevelBefore &&
          other.masteryLevelAfter == this.masteryLevelAfter &&
          other.xpAwarded == this.xpAwarded &&
          other.responseTimeMs == this.responseTimeMs &&
          other.attemptedAt == this.attemptedAt);
}

class ExerciseAttemptsCompanion extends UpdateCompanion<ExerciseAttempt> {
  final Value<int> id;
  final Value<String?> wordId;
  final Value<String> exerciseType;
  final Value<String> sessionId;
  final Value<String> sessionKind;
  final Value<bool> wasCorrect;
  final Value<String?> userAnswer;
  final Value<int> masteryLevelBefore;
  final Value<int> masteryLevelAfter;
  final Value<int> xpAwarded;
  final Value<int?> responseTimeMs;
  final Value<DateTime> attemptedAt;
  const ExerciseAttemptsCompanion({
    this.id = const Value.absent(),
    this.wordId = const Value.absent(),
    this.exerciseType = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.sessionKind = const Value.absent(),
    this.wasCorrect = const Value.absent(),
    this.userAnswer = const Value.absent(),
    this.masteryLevelBefore = const Value.absent(),
    this.masteryLevelAfter = const Value.absent(),
    this.xpAwarded = const Value.absent(),
    this.responseTimeMs = const Value.absent(),
    this.attemptedAt = const Value.absent(),
  });
  ExerciseAttemptsCompanion.insert({
    this.id = const Value.absent(),
    this.wordId = const Value.absent(),
    required String exerciseType,
    required String sessionId,
    required String sessionKind,
    required bool wasCorrect,
    this.userAnswer = const Value.absent(),
    required int masteryLevelBefore,
    required int masteryLevelAfter,
    this.xpAwarded = const Value.absent(),
    this.responseTimeMs = const Value.absent(),
    required DateTime attemptedAt,
  }) : exerciseType = Value(exerciseType),
       sessionId = Value(sessionId),
       sessionKind = Value(sessionKind),
       wasCorrect = Value(wasCorrect),
       masteryLevelBefore = Value(masteryLevelBefore),
       masteryLevelAfter = Value(masteryLevelAfter),
       attemptedAt = Value(attemptedAt);
  static Insertable<ExerciseAttempt> custom({
    Expression<int>? id,
    Expression<String>? wordId,
    Expression<String>? exerciseType,
    Expression<String>? sessionId,
    Expression<String>? sessionKind,
    Expression<bool>? wasCorrect,
    Expression<String>? userAnswer,
    Expression<int>? masteryLevelBefore,
    Expression<int>? masteryLevelAfter,
    Expression<int>? xpAwarded,
    Expression<int>? responseTimeMs,
    Expression<DateTime>? attemptedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (wordId != null) 'word_id': wordId,
      if (exerciseType != null) 'exercise_type': exerciseType,
      if (sessionId != null) 'session_id': sessionId,
      if (sessionKind != null) 'session_kind': sessionKind,
      if (wasCorrect != null) 'was_correct': wasCorrect,
      if (userAnswer != null) 'user_answer': userAnswer,
      if (masteryLevelBefore != null)
        'mastery_level_before': masteryLevelBefore,
      if (masteryLevelAfter != null) 'mastery_level_after': masteryLevelAfter,
      if (xpAwarded != null) 'xp_awarded': xpAwarded,
      if (responseTimeMs != null) 'response_time_ms': responseTimeMs,
      if (attemptedAt != null) 'attempted_at': attemptedAt,
    });
  }

  ExerciseAttemptsCompanion copyWith({
    Value<int>? id,
    Value<String?>? wordId,
    Value<String>? exerciseType,
    Value<String>? sessionId,
    Value<String>? sessionKind,
    Value<bool>? wasCorrect,
    Value<String?>? userAnswer,
    Value<int>? masteryLevelBefore,
    Value<int>? masteryLevelAfter,
    Value<int>? xpAwarded,
    Value<int?>? responseTimeMs,
    Value<DateTime>? attemptedAt,
  }) {
    return ExerciseAttemptsCompanion(
      id: id ?? this.id,
      wordId: wordId ?? this.wordId,
      exerciseType: exerciseType ?? this.exerciseType,
      sessionId: sessionId ?? this.sessionId,
      sessionKind: sessionKind ?? this.sessionKind,
      wasCorrect: wasCorrect ?? this.wasCorrect,
      userAnswer: userAnswer ?? this.userAnswer,
      masteryLevelBefore: masteryLevelBefore ?? this.masteryLevelBefore,
      masteryLevelAfter: masteryLevelAfter ?? this.masteryLevelAfter,
      xpAwarded: xpAwarded ?? this.xpAwarded,
      responseTimeMs: responseTimeMs ?? this.responseTimeMs,
      attemptedAt: attemptedAt ?? this.attemptedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (wordId.present) {
      map['word_id'] = Variable<String>(wordId.value);
    }
    if (exerciseType.present) {
      map['exercise_type'] = Variable<String>(exerciseType.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (sessionKind.present) {
      map['session_kind'] = Variable<String>(sessionKind.value);
    }
    if (wasCorrect.present) {
      map['was_correct'] = Variable<bool>(wasCorrect.value);
    }
    if (userAnswer.present) {
      map['user_answer'] = Variable<String>(userAnswer.value);
    }
    if (masteryLevelBefore.present) {
      map['mastery_level_before'] = Variable<int>(masteryLevelBefore.value);
    }
    if (masteryLevelAfter.present) {
      map['mastery_level_after'] = Variable<int>(masteryLevelAfter.value);
    }
    if (xpAwarded.present) {
      map['xp_awarded'] = Variable<int>(xpAwarded.value);
    }
    if (responseTimeMs.present) {
      map['response_time_ms'] = Variable<int>(responseTimeMs.value);
    }
    if (attemptedAt.present) {
      map['attempted_at'] = Variable<DateTime>(attemptedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExerciseAttemptsCompanion(')
          ..write('id: $id, ')
          ..write('wordId: $wordId, ')
          ..write('exerciseType: $exerciseType, ')
          ..write('sessionId: $sessionId, ')
          ..write('sessionKind: $sessionKind, ')
          ..write('wasCorrect: $wasCorrect, ')
          ..write('userAnswer: $userAnswer, ')
          ..write('masteryLevelBefore: $masteryLevelBefore, ')
          ..write('masteryLevelAfter: $masteryLevelAfter, ')
          ..write('xpAwarded: $xpAwarded, ')
          ..write('responseTimeMs: $responseTimeMs, ')
          ..write('attemptedAt: $attemptedAt')
          ..write(')'))
        .toString();
  }
}

class $DinoEvolutionStateTable extends DinoEvolutionState
    with TableInfo<$DinoEvolutionStateTable, DinoEvolutionStateRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DinoEvolutionStateTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stageMeta = const VerificationMeta('stage');
  @override
  late final GeneratedColumn<String> stage = GeneratedColumn<String>(
    'stage',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('eggDormant'),
  );
  static const VerificationMeta _hatchingStartedAtMeta = const VerificationMeta(
    'hatchingStartedAt',
  );
  @override
  late final GeneratedColumn<DateTime> hatchingStartedAt =
      GeneratedColumn<DateTime>(
        'hatching_started_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _hatchedAtMeta = const VerificationMeta(
    'hatchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> hatchedAt = GeneratedColumn<DateTime>(
    'hatched_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    stage,
    hatchingStartedAt,
    hatchedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'dino_evolution_state';
  @override
  VerificationContext validateIntegrity(
    Insertable<DinoEvolutionStateRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('stage')) {
      context.handle(
        _stageMeta,
        stage.isAcceptableOrUnknown(data['stage']!, _stageMeta),
      );
    }
    if (data.containsKey('hatching_started_at')) {
      context.handle(
        _hatchingStartedAtMeta,
        hatchingStartedAt.isAcceptableOrUnknown(
          data['hatching_started_at']!,
          _hatchingStartedAtMeta,
        ),
      );
    }
    if (data.containsKey('hatched_at')) {
      context.handle(
        _hatchedAtMeta,
        hatchedAt.isAcceptableOrUnknown(data['hatched_at']!, _hatchedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DinoEvolutionStateRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DinoEvolutionStateRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      stage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stage'],
      )!,
      hatchingStartedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}hatching_started_at'],
      ),
      hatchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}hatched_at'],
      ),
    );
  }

  @override
  $DinoEvolutionStateTable createAlias(String alias) {
    return $DinoEvolutionStateTable(attachedDatabase, alias);
  }
}

class DinoEvolutionStateRow extends DataClass
    implements Insertable<DinoEvolutionStateRow> {
  final int id;
  final String stage;
  final DateTime? hatchingStartedAt;
  final DateTime? hatchedAt;
  const DinoEvolutionStateRow({
    required this.id,
    required this.stage,
    this.hatchingStartedAt,
    this.hatchedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['stage'] = Variable<String>(stage);
    if (!nullToAbsent || hatchingStartedAt != null) {
      map['hatching_started_at'] = Variable<DateTime>(hatchingStartedAt);
    }
    if (!nullToAbsent || hatchedAt != null) {
      map['hatched_at'] = Variable<DateTime>(hatchedAt);
    }
    return map;
  }

  DinoEvolutionStateCompanion toCompanion(bool nullToAbsent) {
    return DinoEvolutionStateCompanion(
      id: Value(id),
      stage: Value(stage),
      hatchingStartedAt: hatchingStartedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(hatchingStartedAt),
      hatchedAt: hatchedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(hatchedAt),
    );
  }

  factory DinoEvolutionStateRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DinoEvolutionStateRow(
      id: serializer.fromJson<int>(json['id']),
      stage: serializer.fromJson<String>(json['stage']),
      hatchingStartedAt: serializer.fromJson<DateTime?>(
        json['hatchingStartedAt'],
      ),
      hatchedAt: serializer.fromJson<DateTime?>(json['hatchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'stage': serializer.toJson<String>(stage),
      'hatchingStartedAt': serializer.toJson<DateTime?>(hatchingStartedAt),
      'hatchedAt': serializer.toJson<DateTime?>(hatchedAt),
    };
  }

  DinoEvolutionStateRow copyWith({
    int? id,
    String? stage,
    Value<DateTime?> hatchingStartedAt = const Value.absent(),
    Value<DateTime?> hatchedAt = const Value.absent(),
  }) => DinoEvolutionStateRow(
    id: id ?? this.id,
    stage: stage ?? this.stage,
    hatchingStartedAt: hatchingStartedAt.present
        ? hatchingStartedAt.value
        : this.hatchingStartedAt,
    hatchedAt: hatchedAt.present ? hatchedAt.value : this.hatchedAt,
  );
  DinoEvolutionStateRow copyWithCompanion(DinoEvolutionStateCompanion data) {
    return DinoEvolutionStateRow(
      id: data.id.present ? data.id.value : this.id,
      stage: data.stage.present ? data.stage.value : this.stage,
      hatchingStartedAt: data.hatchingStartedAt.present
          ? data.hatchingStartedAt.value
          : this.hatchingStartedAt,
      hatchedAt: data.hatchedAt.present ? data.hatchedAt.value : this.hatchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DinoEvolutionStateRow(')
          ..write('id: $id, ')
          ..write('stage: $stage, ')
          ..write('hatchingStartedAt: $hatchingStartedAt, ')
          ..write('hatchedAt: $hatchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, stage, hatchingStartedAt, hatchedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DinoEvolutionStateRow &&
          other.id == this.id &&
          other.stage == this.stage &&
          other.hatchingStartedAt == this.hatchingStartedAt &&
          other.hatchedAt == this.hatchedAt);
}

class DinoEvolutionStateCompanion
    extends UpdateCompanion<DinoEvolutionStateRow> {
  final Value<int> id;
  final Value<String> stage;
  final Value<DateTime?> hatchingStartedAt;
  final Value<DateTime?> hatchedAt;
  const DinoEvolutionStateCompanion({
    this.id = const Value.absent(),
    this.stage = const Value.absent(),
    this.hatchingStartedAt = const Value.absent(),
    this.hatchedAt = const Value.absent(),
  });
  DinoEvolutionStateCompanion.insert({
    this.id = const Value.absent(),
    this.stage = const Value.absent(),
    this.hatchingStartedAt = const Value.absent(),
    this.hatchedAt = const Value.absent(),
  });
  static Insertable<DinoEvolutionStateRow> custom({
    Expression<int>? id,
    Expression<String>? stage,
    Expression<DateTime>? hatchingStartedAt,
    Expression<DateTime>? hatchedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (stage != null) 'stage': stage,
      if (hatchingStartedAt != null) 'hatching_started_at': hatchingStartedAt,
      if (hatchedAt != null) 'hatched_at': hatchedAt,
    });
  }

  DinoEvolutionStateCompanion copyWith({
    Value<int>? id,
    Value<String>? stage,
    Value<DateTime?>? hatchingStartedAt,
    Value<DateTime?>? hatchedAt,
  }) {
    return DinoEvolutionStateCompanion(
      id: id ?? this.id,
      stage: stage ?? this.stage,
      hatchingStartedAt: hatchingStartedAt ?? this.hatchingStartedAt,
      hatchedAt: hatchedAt ?? this.hatchedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (stage.present) {
      map['stage'] = Variable<String>(stage.value);
    }
    if (hatchingStartedAt.present) {
      map['hatching_started_at'] = Variable<DateTime>(hatchingStartedAt.value);
    }
    if (hatchedAt.present) {
      map['hatched_at'] = Variable<DateTime>(hatchedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DinoEvolutionStateCompanion(')
          ..write('id: $id, ')
          ..write('stage: $stage, ')
          ..write('hatchingStartedAt: $hatchingStartedAt, ')
          ..write('hatchedAt: $hatchedAt')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSettingsRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _soundEnabledMeta = const VerificationMeta(
    'soundEnabled',
  );
  @override
  late final GeneratedColumn<bool> soundEnabled = GeneratedColumn<bool>(
    'sound_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("sound_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _dailyGoalExercisesMeta =
      const VerificationMeta('dailyGoalExercises');
  @override
  late final GeneratedColumn<int> dailyGoalExercises = GeneratedColumn<int>(
    'daily_goal_exercises',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(10),
  );
  static const VerificationMeta _themeModeMeta = const VerificationMeta(
    'themeMode',
  );
  @override
  late final GeneratedColumn<String> themeMode = GeneratedColumn<String>(
    'theme_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('system'),
  );
  static const VerificationMeta _onboardingCompletedMeta =
      const VerificationMeta('onboardingCompleted');
  @override
  late final GeneratedColumn<bool> onboardingCompleted = GeneratedColumn<bool>(
    'onboarding_completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("onboarding_completed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    soundEnabled,
    dailyGoalExercises,
    themeMode,
    onboardingCompleted,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSettingsRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('sound_enabled')) {
      context.handle(
        _soundEnabledMeta,
        soundEnabled.isAcceptableOrUnknown(
          data['sound_enabled']!,
          _soundEnabledMeta,
        ),
      );
    }
    if (data.containsKey('daily_goal_exercises')) {
      context.handle(
        _dailyGoalExercisesMeta,
        dailyGoalExercises.isAcceptableOrUnknown(
          data['daily_goal_exercises']!,
          _dailyGoalExercisesMeta,
        ),
      );
    }
    if (data.containsKey('theme_mode')) {
      context.handle(
        _themeModeMeta,
        themeMode.isAcceptableOrUnknown(data['theme_mode']!, _themeModeMeta),
      );
    }
    if (data.containsKey('onboarding_completed')) {
      context.handle(
        _onboardingCompletedMeta,
        onboardingCompleted.isAcceptableOrUnknown(
          data['onboarding_completed']!,
          _onboardingCompletedMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AppSettingsRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSettingsRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      soundEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}sound_enabled'],
      )!,
      dailyGoalExercises: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}daily_goal_exercises'],
      )!,
      themeMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}theme_mode'],
      )!,
      onboardingCompleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}onboarding_completed'],
      )!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSettingsRow extends DataClass implements Insertable<AppSettingsRow> {
  final int id;
  final bool soundEnabled;
  final int dailyGoalExercises;
  final String themeMode;
  final bool onboardingCompleted;
  const AppSettingsRow({
    required this.id,
    required this.soundEnabled,
    required this.dailyGoalExercises,
    required this.themeMode,
    required this.onboardingCompleted,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['sound_enabled'] = Variable<bool>(soundEnabled);
    map['daily_goal_exercises'] = Variable<int>(dailyGoalExercises);
    map['theme_mode'] = Variable<String>(themeMode);
    map['onboarding_completed'] = Variable<bool>(onboardingCompleted);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(
      id: Value(id),
      soundEnabled: Value(soundEnabled),
      dailyGoalExercises: Value(dailyGoalExercises),
      themeMode: Value(themeMode),
      onboardingCompleted: Value(onboardingCompleted),
    );
  }

  factory AppSettingsRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSettingsRow(
      id: serializer.fromJson<int>(json['id']),
      soundEnabled: serializer.fromJson<bool>(json['soundEnabled']),
      dailyGoalExercises: serializer.fromJson<int>(json['dailyGoalExercises']),
      themeMode: serializer.fromJson<String>(json['themeMode']),
      onboardingCompleted: serializer.fromJson<bool>(
        json['onboardingCompleted'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'soundEnabled': serializer.toJson<bool>(soundEnabled),
      'dailyGoalExercises': serializer.toJson<int>(dailyGoalExercises),
      'themeMode': serializer.toJson<String>(themeMode),
      'onboardingCompleted': serializer.toJson<bool>(onboardingCompleted),
    };
  }

  AppSettingsRow copyWith({
    int? id,
    bool? soundEnabled,
    int? dailyGoalExercises,
    String? themeMode,
    bool? onboardingCompleted,
  }) => AppSettingsRow(
    id: id ?? this.id,
    soundEnabled: soundEnabled ?? this.soundEnabled,
    dailyGoalExercises: dailyGoalExercises ?? this.dailyGoalExercises,
    themeMode: themeMode ?? this.themeMode,
    onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
  );
  AppSettingsRow copyWithCompanion(AppSettingsCompanion data) {
    return AppSettingsRow(
      id: data.id.present ? data.id.value : this.id,
      soundEnabled: data.soundEnabled.present
          ? data.soundEnabled.value
          : this.soundEnabled,
      dailyGoalExercises: data.dailyGoalExercises.present
          ? data.dailyGoalExercises.value
          : this.dailyGoalExercises,
      themeMode: data.themeMode.present ? data.themeMode.value : this.themeMode,
      onboardingCompleted: data.onboardingCompleted.present
          ? data.onboardingCompleted.value
          : this.onboardingCompleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsRow(')
          ..write('id: $id, ')
          ..write('soundEnabled: $soundEnabled, ')
          ..write('dailyGoalExercises: $dailyGoalExercises, ')
          ..write('themeMode: $themeMode, ')
          ..write('onboardingCompleted: $onboardingCompleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    soundEnabled,
    dailyGoalExercises,
    themeMode,
    onboardingCompleted,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSettingsRow &&
          other.id == this.id &&
          other.soundEnabled == this.soundEnabled &&
          other.dailyGoalExercises == this.dailyGoalExercises &&
          other.themeMode == this.themeMode &&
          other.onboardingCompleted == this.onboardingCompleted);
}

class AppSettingsCompanion extends UpdateCompanion<AppSettingsRow> {
  final Value<int> id;
  final Value<bool> soundEnabled;
  final Value<int> dailyGoalExercises;
  final Value<String> themeMode;
  final Value<bool> onboardingCompleted;
  const AppSettingsCompanion({
    this.id = const Value.absent(),
    this.soundEnabled = const Value.absent(),
    this.dailyGoalExercises = const Value.absent(),
    this.themeMode = const Value.absent(),
    this.onboardingCompleted = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    this.id = const Value.absent(),
    this.soundEnabled = const Value.absent(),
    this.dailyGoalExercises = const Value.absent(),
    this.themeMode = const Value.absent(),
    this.onboardingCompleted = const Value.absent(),
  });
  static Insertable<AppSettingsRow> custom({
    Expression<int>? id,
    Expression<bool>? soundEnabled,
    Expression<int>? dailyGoalExercises,
    Expression<String>? themeMode,
    Expression<bool>? onboardingCompleted,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (soundEnabled != null) 'sound_enabled': soundEnabled,
      if (dailyGoalExercises != null)
        'daily_goal_exercises': dailyGoalExercises,
      if (themeMode != null) 'theme_mode': themeMode,
      if (onboardingCompleted != null)
        'onboarding_completed': onboardingCompleted,
    });
  }

  AppSettingsCompanion copyWith({
    Value<int>? id,
    Value<bool>? soundEnabled,
    Value<int>? dailyGoalExercises,
    Value<String>? themeMode,
    Value<bool>? onboardingCompleted,
  }) {
    return AppSettingsCompanion(
      id: id ?? this.id,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      dailyGoalExercises: dailyGoalExercises ?? this.dailyGoalExercises,
      themeMode: themeMode ?? this.themeMode,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (soundEnabled.present) {
      map['sound_enabled'] = Variable<bool>(soundEnabled.value);
    }
    if (dailyGoalExercises.present) {
      map['daily_goal_exercises'] = Variable<int>(dailyGoalExercises.value);
    }
    if (themeMode.present) {
      map['theme_mode'] = Variable<String>(themeMode.value);
    }
    if (onboardingCompleted.present) {
      map['onboarding_completed'] = Variable<bool>(onboardingCompleted.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('id: $id, ')
          ..write('soundEnabled: $soundEnabled, ')
          ..write('dailyGoalExercises: $dailyGoalExercises, ')
          ..write('themeMode: $themeMode, ')
          ..write('onboardingCompleted: $onboardingCompleted')
          ..write(')'))
        .toString();
  }
}

class $SeedMetadataTable extends SeedMetadata
    with TableInfo<$SeedMetadataTable, SeedMetadataRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SeedMetadataTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'seed_metadata';
  @override
  VerificationContext validateIntegrity(
    Insertable<SeedMetadataRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SeedMetadataRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SeedMetadataRow(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $SeedMetadataTable createAlias(String alias) {
    return $SeedMetadataTable(attachedDatabase, alias);
  }
}

class SeedMetadataRow extends DataClass implements Insertable<SeedMetadataRow> {
  final String key;
  final String value;
  const SeedMetadataRow({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SeedMetadataCompanion toCompanion(bool nullToAbsent) {
    return SeedMetadataCompanion(key: Value(key), value: Value(value));
  }

  factory SeedMetadataRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SeedMetadataRow(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  SeedMetadataRow copyWith({String? key, String? value}) =>
      SeedMetadataRow(key: key ?? this.key, value: value ?? this.value);
  SeedMetadataRow copyWithCompanion(SeedMetadataCompanion data) {
    return SeedMetadataRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SeedMetadataRow(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SeedMetadataRow &&
          other.key == this.key &&
          other.value == this.value);
}

class SeedMetadataCompanion extends UpdateCompanion<SeedMetadataRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SeedMetadataCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SeedMetadataCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<SeedMetadataRow> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SeedMetadataCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return SeedMetadataCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SeedMetadataCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DinoMemoriesTable extends DinoMemories
    with TableInfo<$DinoMemoriesTable, DinoMemoryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DinoMemoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _memoryKeyMeta = const VerificationMeta(
    'memoryKey',
  );
  @override
  late final GeneratedColumn<String> memoryKey = GeneratedColumn<String>(
    'memory_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _confidenceMeta = const VerificationMeta(
    'confidence',
  );
  @override
  late final GeneratedColumn<double> confidence = GeneratedColumn<double>(
    'confidence',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(1.0),
  );
  static const VerificationMeta _timesReinforcedMeta = const VerificationMeta(
    'timesReinforced',
  );
  @override
  late final GeneratedColumn<int> timesReinforced = GeneratedColumn<int>(
    'times_reinforced',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    kind,
    memoryKey,
    value,
    confidence,
    timesReinforced,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'dino_memories';
  @override
  VerificationContext validateIntegrity(
    Insertable<DinoMemoryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('memory_key')) {
      context.handle(
        _memoryKeyMeta,
        memoryKey.isAcceptableOrUnknown(data['memory_key']!, _memoryKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_memoryKeyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('confidence')) {
      context.handle(
        _confidenceMeta,
        confidence.isAcceptableOrUnknown(data['confidence']!, _confidenceMeta),
      );
    }
    if (data.containsKey('times_reinforced')) {
      context.handle(
        _timesReinforcedMeta,
        timesReinforced.isAcceptableOrUnknown(
          data['times_reinforced']!,
          _timesReinforcedMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {kind, memoryKey};
  @override
  DinoMemoryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DinoMemoryRow(
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      memoryKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}memory_key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
      confidence: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}confidence'],
      )!,
      timesReinforced: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}times_reinforced'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $DinoMemoriesTable createAlias(String alias) {
    return $DinoMemoriesTable(attachedDatabase, alias);
  }
}

class DinoMemoryRow extends DataClass implements Insertable<DinoMemoryRow> {
  final String kind;

  /// Kind-specific key, e.g. `food` for a `preference`, a word id for a
  /// `learnedWord`.
  final String memoryKey;
  final String value;

  /// 0..1 -- how sure the Dino is (e.g. a learned word's mastery in
  /// conversation, or a word a child taught that isn't in the bank).
  final double confidence;
  final int timesReinforced;
  final DateTime createdAt;
  final DateTime updatedAt;
  const DinoMemoryRow({
    required this.kind,
    required this.memoryKey,
    required this.value,
    required this.confidence,
    required this.timesReinforced,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['kind'] = Variable<String>(kind);
    map['memory_key'] = Variable<String>(memoryKey);
    map['value'] = Variable<String>(value);
    map['confidence'] = Variable<double>(confidence);
    map['times_reinforced'] = Variable<int>(timesReinforced);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  DinoMemoriesCompanion toCompanion(bool nullToAbsent) {
    return DinoMemoriesCompanion(
      kind: Value(kind),
      memoryKey: Value(memoryKey),
      value: Value(value),
      confidence: Value(confidence),
      timesReinforced: Value(timesReinforced),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory DinoMemoryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DinoMemoryRow(
      kind: serializer.fromJson<String>(json['kind']),
      memoryKey: serializer.fromJson<String>(json['memoryKey']),
      value: serializer.fromJson<String>(json['value']),
      confidence: serializer.fromJson<double>(json['confidence']),
      timesReinforced: serializer.fromJson<int>(json['timesReinforced']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'kind': serializer.toJson<String>(kind),
      'memoryKey': serializer.toJson<String>(memoryKey),
      'value': serializer.toJson<String>(value),
      'confidence': serializer.toJson<double>(confidence),
      'timesReinforced': serializer.toJson<int>(timesReinforced),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  DinoMemoryRow copyWith({
    String? kind,
    String? memoryKey,
    String? value,
    double? confidence,
    int? timesReinforced,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => DinoMemoryRow(
    kind: kind ?? this.kind,
    memoryKey: memoryKey ?? this.memoryKey,
    value: value ?? this.value,
    confidence: confidence ?? this.confidence,
    timesReinforced: timesReinforced ?? this.timesReinforced,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  DinoMemoryRow copyWithCompanion(DinoMemoriesCompanion data) {
    return DinoMemoryRow(
      kind: data.kind.present ? data.kind.value : this.kind,
      memoryKey: data.memoryKey.present ? data.memoryKey.value : this.memoryKey,
      value: data.value.present ? data.value.value : this.value,
      confidence: data.confidence.present
          ? data.confidence.value
          : this.confidence,
      timesReinforced: data.timesReinforced.present
          ? data.timesReinforced.value
          : this.timesReinforced,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DinoMemoryRow(')
          ..write('kind: $kind, ')
          ..write('memoryKey: $memoryKey, ')
          ..write('value: $value, ')
          ..write('confidence: $confidence, ')
          ..write('timesReinforced: $timesReinforced, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    kind,
    memoryKey,
    value,
    confidence,
    timesReinforced,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DinoMemoryRow &&
          other.kind == this.kind &&
          other.memoryKey == this.memoryKey &&
          other.value == this.value &&
          other.confidence == this.confidence &&
          other.timesReinforced == this.timesReinforced &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class DinoMemoriesCompanion extends UpdateCompanion<DinoMemoryRow> {
  final Value<String> kind;
  final Value<String> memoryKey;
  final Value<String> value;
  final Value<double> confidence;
  final Value<int> timesReinforced;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const DinoMemoriesCompanion({
    this.kind = const Value.absent(),
    this.memoryKey = const Value.absent(),
    this.value = const Value.absent(),
    this.confidence = const Value.absent(),
    this.timesReinforced = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DinoMemoriesCompanion.insert({
    required String kind,
    required String memoryKey,
    required String value,
    this.confidence = const Value.absent(),
    this.timesReinforced = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : kind = Value(kind),
       memoryKey = Value(memoryKey),
       value = Value(value),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<DinoMemoryRow> custom({
    Expression<String>? kind,
    Expression<String>? memoryKey,
    Expression<String>? value,
    Expression<double>? confidence,
    Expression<int>? timesReinforced,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (kind != null) 'kind': kind,
      if (memoryKey != null) 'memory_key': memoryKey,
      if (value != null) 'value': value,
      if (confidence != null) 'confidence': confidence,
      if (timesReinforced != null) 'times_reinforced': timesReinforced,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DinoMemoriesCompanion copyWith({
    Value<String>? kind,
    Value<String>? memoryKey,
    Value<String>? value,
    Value<double>? confidence,
    Value<int>? timesReinforced,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return DinoMemoriesCompanion(
      kind: kind ?? this.kind,
      memoryKey: memoryKey ?? this.memoryKey,
      value: value ?? this.value,
      confidence: confidence ?? this.confidence,
      timesReinforced: timesReinforced ?? this.timesReinforced,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (memoryKey.present) {
      map['memory_key'] = Variable<String>(memoryKey.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (confidence.present) {
      map['confidence'] = Variable<double>(confidence.value);
    }
    if (timesReinforced.present) {
      map['times_reinforced'] = Variable<int>(timesReinforced.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DinoMemoriesCompanion(')
          ..write('kind: $kind, ')
          ..write('memoryKey: $memoryKey, ')
          ..write('value: $value, ')
          ..write('confidence: $confidence, ')
          ..write('timesReinforced: $timesReinforced, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CompanionStatesTable extends CompanionStates
    with TableInfo<$CompanionStatesTable, CompanionStateRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CompanionStatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hungerMeta = const VerificationMeta('hunger');
  @override
  late final GeneratedColumn<double> hunger = GeneratedColumn<double>(
    'hunger',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _thirstMeta = const VerificationMeta('thirst');
  @override
  late final GeneratedColumn<double> thirst = GeneratedColumn<double>(
    'thirst',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _energyMeta = const VerificationMeta('energy');
  @override
  late final GeneratedColumn<double> energy = GeneratedColumn<double>(
    'energy',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _happinessMeta = const VerificationMeta(
    'happiness',
  );
  @override
  late final GeneratedColumn<double> happiness = GeneratedColumn<double>(
    'happiness',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isSleepingMeta = const VerificationMeta(
    'isSleeping',
  );
  @override
  late final GeneratedColumn<bool> isSleeping = GeneratedColumn<bool>(
    'is_sleeping',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_sleeping" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _careXpTodayMeta = const VerificationMeta(
    'careXpToday',
  );
  @override
  late final GeneratedColumn<int> careXpToday = GeneratedColumn<int>(
    'care_xp_today',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _careXpDateMeta = const VerificationMeta(
    'careXpDate',
  );
  @override
  late final GeneratedColumn<String> careXpDate = GeneratedColumn<String>(
    'care_xp_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    hunger,
    thirst,
    energy,
    happiness,
    isSleeping,
    careXpToday,
    careXpDate,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'companion_state';
  @override
  VerificationContext validateIntegrity(
    Insertable<CompanionStateRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('hunger')) {
      context.handle(
        _hungerMeta,
        hunger.isAcceptableOrUnknown(data['hunger']!, _hungerMeta),
      );
    } else if (isInserting) {
      context.missing(_hungerMeta);
    }
    if (data.containsKey('thirst')) {
      context.handle(
        _thirstMeta,
        thirst.isAcceptableOrUnknown(data['thirst']!, _thirstMeta),
      );
    } else if (isInserting) {
      context.missing(_thirstMeta);
    }
    if (data.containsKey('energy')) {
      context.handle(
        _energyMeta,
        energy.isAcceptableOrUnknown(data['energy']!, _energyMeta),
      );
    } else if (isInserting) {
      context.missing(_energyMeta);
    }
    if (data.containsKey('happiness')) {
      context.handle(
        _happinessMeta,
        happiness.isAcceptableOrUnknown(data['happiness']!, _happinessMeta),
      );
    } else if (isInserting) {
      context.missing(_happinessMeta);
    }
    if (data.containsKey('is_sleeping')) {
      context.handle(
        _isSleepingMeta,
        isSleeping.isAcceptableOrUnknown(data['is_sleeping']!, _isSleepingMeta),
      );
    }
    if (data.containsKey('care_xp_today')) {
      context.handle(
        _careXpTodayMeta,
        careXpToday.isAcceptableOrUnknown(
          data['care_xp_today']!,
          _careXpTodayMeta,
        ),
      );
    }
    if (data.containsKey('care_xp_date')) {
      context.handle(
        _careXpDateMeta,
        careXpDate.isAcceptableOrUnknown(
          data['care_xp_date']!,
          _careXpDateMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CompanionStateRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CompanionStateRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      hunger: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}hunger'],
      )!,
      thirst: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}thirst'],
      )!,
      energy: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}energy'],
      )!,
      happiness: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}happiness'],
      )!,
      isSleeping: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_sleeping'],
      )!,
      careXpToday: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}care_xp_today'],
      )!,
      careXpDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}care_xp_date'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CompanionStatesTable createAlias(String alias) {
    return $CompanionStatesTable(attachedDatabase, alias);
  }
}

class CompanionStateRow extends DataClass
    implements Insertable<CompanionStateRow> {
  final int id;
  final double hunger;
  final double thirst;
  final double energy;
  final double happiness;
  final bool isSleeping;

  /// Care XP granted on [careXpDate] (`YYYY-MM-DD`), for the daily cap.
  final int careXpToday;
  final String? careXpDate;
  final DateTime updatedAt;
  const CompanionStateRow({
    required this.id,
    required this.hunger,
    required this.thirst,
    required this.energy,
    required this.happiness,
    required this.isSleeping,
    required this.careXpToday,
    this.careXpDate,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['hunger'] = Variable<double>(hunger);
    map['thirst'] = Variable<double>(thirst);
    map['energy'] = Variable<double>(energy);
    map['happiness'] = Variable<double>(happiness);
    map['is_sleeping'] = Variable<bool>(isSleeping);
    map['care_xp_today'] = Variable<int>(careXpToday);
    if (!nullToAbsent || careXpDate != null) {
      map['care_xp_date'] = Variable<String>(careXpDate);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CompanionStatesCompanion toCompanion(bool nullToAbsent) {
    return CompanionStatesCompanion(
      id: Value(id),
      hunger: Value(hunger),
      thirst: Value(thirst),
      energy: Value(energy),
      happiness: Value(happiness),
      isSleeping: Value(isSleeping),
      careXpToday: Value(careXpToday),
      careXpDate: careXpDate == null && nullToAbsent
          ? const Value.absent()
          : Value(careXpDate),
      updatedAt: Value(updatedAt),
    );
  }

  factory CompanionStateRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CompanionStateRow(
      id: serializer.fromJson<int>(json['id']),
      hunger: serializer.fromJson<double>(json['hunger']),
      thirst: serializer.fromJson<double>(json['thirst']),
      energy: serializer.fromJson<double>(json['energy']),
      happiness: serializer.fromJson<double>(json['happiness']),
      isSleeping: serializer.fromJson<bool>(json['isSleeping']),
      careXpToday: serializer.fromJson<int>(json['careXpToday']),
      careXpDate: serializer.fromJson<String?>(json['careXpDate']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'hunger': serializer.toJson<double>(hunger),
      'thirst': serializer.toJson<double>(thirst),
      'energy': serializer.toJson<double>(energy),
      'happiness': serializer.toJson<double>(happiness),
      'isSleeping': serializer.toJson<bool>(isSleeping),
      'careXpToday': serializer.toJson<int>(careXpToday),
      'careXpDate': serializer.toJson<String?>(careXpDate),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CompanionStateRow copyWith({
    int? id,
    double? hunger,
    double? thirst,
    double? energy,
    double? happiness,
    bool? isSleeping,
    int? careXpToday,
    Value<String?> careXpDate = const Value.absent(),
    DateTime? updatedAt,
  }) => CompanionStateRow(
    id: id ?? this.id,
    hunger: hunger ?? this.hunger,
    thirst: thirst ?? this.thirst,
    energy: energy ?? this.energy,
    happiness: happiness ?? this.happiness,
    isSleeping: isSleeping ?? this.isSleeping,
    careXpToday: careXpToday ?? this.careXpToday,
    careXpDate: careXpDate.present ? careXpDate.value : this.careXpDate,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  CompanionStateRow copyWithCompanion(CompanionStatesCompanion data) {
    return CompanionStateRow(
      id: data.id.present ? data.id.value : this.id,
      hunger: data.hunger.present ? data.hunger.value : this.hunger,
      thirst: data.thirst.present ? data.thirst.value : this.thirst,
      energy: data.energy.present ? data.energy.value : this.energy,
      happiness: data.happiness.present ? data.happiness.value : this.happiness,
      isSleeping: data.isSleeping.present
          ? data.isSleeping.value
          : this.isSleeping,
      careXpToday: data.careXpToday.present
          ? data.careXpToday.value
          : this.careXpToday,
      careXpDate: data.careXpDate.present
          ? data.careXpDate.value
          : this.careXpDate,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CompanionStateRow(')
          ..write('id: $id, ')
          ..write('hunger: $hunger, ')
          ..write('thirst: $thirst, ')
          ..write('energy: $energy, ')
          ..write('happiness: $happiness, ')
          ..write('isSleeping: $isSleeping, ')
          ..write('careXpToday: $careXpToday, ')
          ..write('careXpDate: $careXpDate, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    hunger,
    thirst,
    energy,
    happiness,
    isSleeping,
    careXpToday,
    careXpDate,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CompanionStateRow &&
          other.id == this.id &&
          other.hunger == this.hunger &&
          other.thirst == this.thirst &&
          other.energy == this.energy &&
          other.happiness == this.happiness &&
          other.isSleeping == this.isSleeping &&
          other.careXpToday == this.careXpToday &&
          other.careXpDate == this.careXpDate &&
          other.updatedAt == this.updatedAt);
}

class CompanionStatesCompanion extends UpdateCompanion<CompanionStateRow> {
  final Value<int> id;
  final Value<double> hunger;
  final Value<double> thirst;
  final Value<double> energy;
  final Value<double> happiness;
  final Value<bool> isSleeping;
  final Value<int> careXpToday;
  final Value<String?> careXpDate;
  final Value<DateTime> updatedAt;
  const CompanionStatesCompanion({
    this.id = const Value.absent(),
    this.hunger = const Value.absent(),
    this.thirst = const Value.absent(),
    this.energy = const Value.absent(),
    this.happiness = const Value.absent(),
    this.isSleeping = const Value.absent(),
    this.careXpToday = const Value.absent(),
    this.careXpDate = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  CompanionStatesCompanion.insert({
    this.id = const Value.absent(),
    required double hunger,
    required double thirst,
    required double energy,
    required double happiness,
    this.isSleeping = const Value.absent(),
    this.careXpToday = const Value.absent(),
    this.careXpDate = const Value.absent(),
    required DateTime updatedAt,
  }) : hunger = Value(hunger),
       thirst = Value(thirst),
       energy = Value(energy),
       happiness = Value(happiness),
       updatedAt = Value(updatedAt);
  static Insertable<CompanionStateRow> custom({
    Expression<int>? id,
    Expression<double>? hunger,
    Expression<double>? thirst,
    Expression<double>? energy,
    Expression<double>? happiness,
    Expression<bool>? isSleeping,
    Expression<int>? careXpToday,
    Expression<String>? careXpDate,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (hunger != null) 'hunger': hunger,
      if (thirst != null) 'thirst': thirst,
      if (energy != null) 'energy': energy,
      if (happiness != null) 'happiness': happiness,
      if (isSleeping != null) 'is_sleeping': isSleeping,
      if (careXpToday != null) 'care_xp_today': careXpToday,
      if (careXpDate != null) 'care_xp_date': careXpDate,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  CompanionStatesCompanion copyWith({
    Value<int>? id,
    Value<double>? hunger,
    Value<double>? thirst,
    Value<double>? energy,
    Value<double>? happiness,
    Value<bool>? isSleeping,
    Value<int>? careXpToday,
    Value<String?>? careXpDate,
    Value<DateTime>? updatedAt,
  }) {
    return CompanionStatesCompanion(
      id: id ?? this.id,
      hunger: hunger ?? this.hunger,
      thirst: thirst ?? this.thirst,
      energy: energy ?? this.energy,
      happiness: happiness ?? this.happiness,
      isSleeping: isSleeping ?? this.isSleeping,
      careXpToday: careXpToday ?? this.careXpToday,
      careXpDate: careXpDate ?? this.careXpDate,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (hunger.present) {
      map['hunger'] = Variable<double>(hunger.value);
    }
    if (thirst.present) {
      map['thirst'] = Variable<double>(thirst.value);
    }
    if (energy.present) {
      map['energy'] = Variable<double>(energy.value);
    }
    if (happiness.present) {
      map['happiness'] = Variable<double>(happiness.value);
    }
    if (isSleeping.present) {
      map['is_sleeping'] = Variable<bool>(isSleeping.value);
    }
    if (careXpToday.present) {
      map['care_xp_today'] = Variable<int>(careXpToday.value);
    }
    if (careXpDate.present) {
      map['care_xp_date'] = Variable<String>(careXpDate.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CompanionStatesCompanion(')
          ..write('id: $id, ')
          ..write('hunger: $hunger, ')
          ..write('thirst: $thirst, ')
          ..write('energy: $energy, ')
          ..write('happiness: $happiness, ')
          ..write('isSleeping: $isSleeping, ')
          ..write('careXpToday: $careXpToday, ')
          ..write('careXpDate: $careXpDate, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $WordsTable words = $WordsTable(this);
  late final $WordProgressTable wordProgress = $WordProgressTable(this);
  late final $UserProfileTable userProfile = $UserProfileTable(this);
  late final $DailyActivityLogTable dailyActivityLog = $DailyActivityLogTable(
    this,
  );
  late final $ExerciseAttemptsTable exerciseAttempts = $ExerciseAttemptsTable(
    this,
  );
  late final $DinoEvolutionStateTable dinoEvolutionState =
      $DinoEvolutionStateTable(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  late final $SeedMetadataTable seedMetadata = $SeedMetadataTable(this);
  late final $DinoMemoriesTable dinoMemories = $DinoMemoriesTable(this);
  late final $CompanionStatesTable companionStates = $CompanionStatesTable(
    this,
  );
  late final Index idxExerciseAttemptsWordId = Index(
    'idx_exercise_attempts_word_id',
    'CREATE INDEX idx_exercise_attempts_word_id ON exercise_attempts (word_id)',
  );
  late final Index idxExerciseAttemptsAttemptedAt = Index(
    'idx_exercise_attempts_attempted_at',
    'CREATE INDEX idx_exercise_attempts_attempted_at ON exercise_attempts (attempted_at)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    words,
    wordProgress,
    userProfile,
    dailyActivityLog,
    exerciseAttempts,
    dinoEvolutionState,
    appSettings,
    seedMetadata,
    dinoMemories,
    companionStates,
    idxExerciseAttemptsWordId,
    idxExerciseAttemptsAttemptedAt,
  ];
}

typedef $$WordsTableCreateCompanionBuilder =
    WordsCompanion Function({
      required String id,
      required String englishTerm,
      required String portugueseTranslation,
      required String category,
      required int difficulty,
      required int recommendedLevel,
      required String exampleSentenceEn,
      required String exampleSentencePt,
      Value<String?> sensesJson,
      Value<String?> pronunciationAudioAsset,
      Value<String?> imageAsset,
      Value<bool> isActive,
      Value<int> rowid,
    });
typedef $$WordsTableUpdateCompanionBuilder =
    WordsCompanion Function({
      Value<String> id,
      Value<String> englishTerm,
      Value<String> portugueseTranslation,
      Value<String> category,
      Value<int> difficulty,
      Value<int> recommendedLevel,
      Value<String> exampleSentenceEn,
      Value<String> exampleSentencePt,
      Value<String?> sensesJson,
      Value<String?> pronunciationAudioAsset,
      Value<String?> imageAsset,
      Value<bool> isActive,
      Value<int> rowid,
    });

final class $$WordsTableReferences
    extends BaseReferences<_$AppDatabase, $WordsTable, Word> {
  $$WordsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$WordProgressTable, List<WordProgressRow>>
  _wordProgressRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.wordProgress,
    aliasName: 'words__id__word_progress__word_id',
  );

  $$WordProgressTableProcessedTableManager get wordProgressRefs {
    final manager = $$WordProgressTableTableManager(
      $_db,
      $_db.wordProgress,
    ).filter((f) => f.wordId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_wordProgressRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ExerciseAttemptsTable, List<ExerciseAttempt>>
  _exerciseAttemptsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.exerciseAttempts,
    aliasName: 'words__id__exercise_attempts__word_id',
  );

  $$ExerciseAttemptsTableProcessedTableManager get exerciseAttemptsRefs {
    final manager = $$ExerciseAttemptsTableTableManager(
      $_db,
      $_db.exerciseAttempts,
    ).filter((f) => f.wordId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _exerciseAttemptsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$WordsTableFilterComposer extends Composer<_$AppDatabase, $WordsTable> {
  $$WordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get englishTerm => $composableBuilder(
    column: $table.englishTerm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get portugueseTranslation => $composableBuilder(
    column: $table.portugueseTranslation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get recommendedLevel => $composableBuilder(
    column: $table.recommendedLevel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get exampleSentenceEn => $composableBuilder(
    column: $table.exampleSentenceEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get exampleSentencePt => $composableBuilder(
    column: $table.exampleSentencePt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sensesJson => $composableBuilder(
    column: $table.sensesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pronunciationAudioAsset => $composableBuilder(
    column: $table.pronunciationAudioAsset,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imageAsset => $composableBuilder(
    column: $table.imageAsset,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> wordProgressRefs(
    Expression<bool> Function($$WordProgressTableFilterComposer f) f,
  ) {
    final $$WordProgressTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.wordProgress,
      getReferencedColumn: (t) => t.wordId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WordProgressTableFilterComposer(
            $db: $db,
            $table: $db.wordProgress,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> exerciseAttemptsRefs(
    Expression<bool> Function($$ExerciseAttemptsTableFilterComposer f) f,
  ) {
    final $$ExerciseAttemptsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.exerciseAttempts,
      getReferencedColumn: (t) => t.wordId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExerciseAttemptsTableFilterComposer(
            $db: $db,
            $table: $db.exerciseAttempts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$WordsTableOrderingComposer
    extends Composer<_$AppDatabase, $WordsTable> {
  $$WordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get englishTerm => $composableBuilder(
    column: $table.englishTerm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get portugueseTranslation => $composableBuilder(
    column: $table.portugueseTranslation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get recommendedLevel => $composableBuilder(
    column: $table.recommendedLevel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get exampleSentenceEn => $composableBuilder(
    column: $table.exampleSentenceEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get exampleSentencePt => $composableBuilder(
    column: $table.exampleSentencePt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sensesJson => $composableBuilder(
    column: $table.sensesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pronunciationAudioAsset => $composableBuilder(
    column: $table.pronunciationAudioAsset,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imageAsset => $composableBuilder(
    column: $table.imageAsset,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WordsTable> {
  $$WordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get englishTerm => $composableBuilder(
    column: $table.englishTerm,
    builder: (column) => column,
  );

  GeneratedColumn<String> get portugueseTranslation => $composableBuilder(
    column: $table.portugueseTranslation,
    builder: (column) => column,
  );

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<int> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => column,
  );

  GeneratedColumn<int> get recommendedLevel => $composableBuilder(
    column: $table.recommendedLevel,
    builder: (column) => column,
  );

  GeneratedColumn<String> get exampleSentenceEn => $composableBuilder(
    column: $table.exampleSentenceEn,
    builder: (column) => column,
  );

  GeneratedColumn<String> get exampleSentencePt => $composableBuilder(
    column: $table.exampleSentencePt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sensesJson => $composableBuilder(
    column: $table.sensesJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get pronunciationAudioAsset => $composableBuilder(
    column: $table.pronunciationAudioAsset,
    builder: (column) => column,
  );

  GeneratedColumn<String> get imageAsset => $composableBuilder(
    column: $table.imageAsset,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  Expression<T> wordProgressRefs<T extends Object>(
    Expression<T> Function($$WordProgressTableAnnotationComposer a) f,
  ) {
    final $$WordProgressTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.wordProgress,
      getReferencedColumn: (t) => t.wordId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WordProgressTableAnnotationComposer(
            $db: $db,
            $table: $db.wordProgress,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> exerciseAttemptsRefs<T extends Object>(
    Expression<T> Function($$ExerciseAttemptsTableAnnotationComposer a) f,
  ) {
    final $$ExerciseAttemptsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.exerciseAttempts,
      getReferencedColumn: (t) => t.wordId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExerciseAttemptsTableAnnotationComposer(
            $db: $db,
            $table: $db.exerciseAttempts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$WordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WordsTable,
          Word,
          $$WordsTableFilterComposer,
          $$WordsTableOrderingComposer,
          $$WordsTableAnnotationComposer,
          $$WordsTableCreateCompanionBuilder,
          $$WordsTableUpdateCompanionBuilder,
          (Word, $$WordsTableReferences),
          Word,
          PrefetchHooks Function({
            bool wordProgressRefs,
            bool exerciseAttemptsRefs,
          })
        > {
  $$WordsTableTableManager(_$AppDatabase db, $WordsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> englishTerm = const Value.absent(),
                Value<String> portugueseTranslation = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<int> difficulty = const Value.absent(),
                Value<int> recommendedLevel = const Value.absent(),
                Value<String> exampleSentenceEn = const Value.absent(),
                Value<String> exampleSentencePt = const Value.absent(),
                Value<String?> sensesJson = const Value.absent(),
                Value<String?> pronunciationAudioAsset = const Value.absent(),
                Value<String?> imageAsset = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WordsCompanion(
                id: id,
                englishTerm: englishTerm,
                portugueseTranslation: portugueseTranslation,
                category: category,
                difficulty: difficulty,
                recommendedLevel: recommendedLevel,
                exampleSentenceEn: exampleSentenceEn,
                exampleSentencePt: exampleSentencePt,
                sensesJson: sensesJson,
                pronunciationAudioAsset: pronunciationAudioAsset,
                imageAsset: imageAsset,
                isActive: isActive,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String englishTerm,
                required String portugueseTranslation,
                required String category,
                required int difficulty,
                required int recommendedLevel,
                required String exampleSentenceEn,
                required String exampleSentencePt,
                Value<String?> sensesJson = const Value.absent(),
                Value<String?> pronunciationAudioAsset = const Value.absent(),
                Value<String?> imageAsset = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WordsCompanion.insert(
                id: id,
                englishTerm: englishTerm,
                portugueseTranslation: portugueseTranslation,
                category: category,
                difficulty: difficulty,
                recommendedLevel: recommendedLevel,
                exampleSentenceEn: exampleSentenceEn,
                exampleSentencePt: exampleSentencePt,
                sensesJson: sensesJson,
                pronunciationAudioAsset: pronunciationAudioAsset,
                imageAsset: imageAsset,
                isActive: isActive,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$WordsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({wordProgressRefs = false, exerciseAttemptsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (wordProgressRefs) db.wordProgress,
                    if (exerciseAttemptsRefs) db.exerciseAttempts,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (wordProgressRefs)
                        await $_getPrefetchedData<
                          Word,
                          $WordsTable,
                          WordProgressRow
                        >(
                          currentTable: table,
                          referencedTable: $$WordsTableReferences
                              ._wordProgressRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$WordsTableReferences(
                                db,
                                table,
                                p0,
                              ).wordProgressRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.wordId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (exerciseAttemptsRefs)
                        await $_getPrefetchedData<
                          Word,
                          $WordsTable,
                          ExerciseAttempt
                        >(
                          currentTable: table,
                          referencedTable: $$WordsTableReferences
                              ._exerciseAttemptsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$WordsTableReferences(
                                db,
                                table,
                                p0,
                              ).exerciseAttemptsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.wordId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$WordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WordsTable,
      Word,
      $$WordsTableFilterComposer,
      $$WordsTableOrderingComposer,
      $$WordsTableAnnotationComposer,
      $$WordsTableCreateCompanionBuilder,
      $$WordsTableUpdateCompanionBuilder,
      (Word, $$WordsTableReferences),
      Word,
      PrefetchHooks Function({bool wordProgressRefs, bool exerciseAttemptsRefs})
    >;
typedef $$WordProgressTableCreateCompanionBuilder =
    WordProgressCompanion Function({
      required String wordId,
      Value<int> masteryLevel,
      Value<int> correctCount,
      Value<int> incorrectCount,
      Value<int> currentStreak,
      Value<DateTime?> lastSeenAt,
      Value<DateTime?> nextReviewAt,
      Value<bool?> lastResultCorrect,
      Value<int> timesShownTotal,
      Value<DateTime?> introducedAt,
      Value<int> rowid,
    });
typedef $$WordProgressTableUpdateCompanionBuilder =
    WordProgressCompanion Function({
      Value<String> wordId,
      Value<int> masteryLevel,
      Value<int> correctCount,
      Value<int> incorrectCount,
      Value<int> currentStreak,
      Value<DateTime?> lastSeenAt,
      Value<DateTime?> nextReviewAt,
      Value<bool?> lastResultCorrect,
      Value<int> timesShownTotal,
      Value<DateTime?> introducedAt,
      Value<int> rowid,
    });

final class $$WordProgressTableReferences
    extends BaseReferences<_$AppDatabase, $WordProgressTable, WordProgressRow> {
  $$WordProgressTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $WordsTable _wordIdTable(_$AppDatabase db) =>
      db.words.createAlias('word_progress__word_id__words__id');

  $$WordsTableProcessedTableManager get wordId {
    final $_column = $_itemColumn<String>('word_id')!;

    final manager = $$WordsTableTableManager(
      $_db,
      $_db.words,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_wordIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$WordProgressTableFilterComposer
    extends Composer<_$AppDatabase, $WordProgressTable> {
  $$WordProgressTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get masteryLevel => $composableBuilder(
    column: $table.masteryLevel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get correctCount => $composableBuilder(
    column: $table.correctCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get incorrectCount => $composableBuilder(
    column: $table.incorrectCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get currentStreak => $composableBuilder(
    column: $table.currentStreak,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSeenAt => $composableBuilder(
    column: $table.lastSeenAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get nextReviewAt => $composableBuilder(
    column: $table.nextReviewAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get lastResultCorrect => $composableBuilder(
    column: $table.lastResultCorrect,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get timesShownTotal => $composableBuilder(
    column: $table.timesShownTotal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get introducedAt => $composableBuilder(
    column: $table.introducedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$WordsTableFilterComposer get wordId {
    final $$WordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.wordId,
      referencedTable: $db.words,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WordsTableFilterComposer(
            $db: $db,
            $table: $db.words,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WordProgressTableOrderingComposer
    extends Composer<_$AppDatabase, $WordProgressTable> {
  $$WordProgressTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get masteryLevel => $composableBuilder(
    column: $table.masteryLevel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get correctCount => $composableBuilder(
    column: $table.correctCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get incorrectCount => $composableBuilder(
    column: $table.incorrectCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get currentStreak => $composableBuilder(
    column: $table.currentStreak,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSeenAt => $composableBuilder(
    column: $table.lastSeenAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get nextReviewAt => $composableBuilder(
    column: $table.nextReviewAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get lastResultCorrect => $composableBuilder(
    column: $table.lastResultCorrect,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get timesShownTotal => $composableBuilder(
    column: $table.timesShownTotal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get introducedAt => $composableBuilder(
    column: $table.introducedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$WordsTableOrderingComposer get wordId {
    final $$WordsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.wordId,
      referencedTable: $db.words,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WordsTableOrderingComposer(
            $db: $db,
            $table: $db.words,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WordProgressTableAnnotationComposer
    extends Composer<_$AppDatabase, $WordProgressTable> {
  $$WordProgressTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get masteryLevel => $composableBuilder(
    column: $table.masteryLevel,
    builder: (column) => column,
  );

  GeneratedColumn<int> get correctCount => $composableBuilder(
    column: $table.correctCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get incorrectCount => $composableBuilder(
    column: $table.incorrectCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get currentStreak => $composableBuilder(
    column: $table.currentStreak,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastSeenAt => $composableBuilder(
    column: $table.lastSeenAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get nextReviewAt => $composableBuilder(
    column: $table.nextReviewAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get lastResultCorrect => $composableBuilder(
    column: $table.lastResultCorrect,
    builder: (column) => column,
  );

  GeneratedColumn<int> get timesShownTotal => $composableBuilder(
    column: $table.timesShownTotal,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get introducedAt => $composableBuilder(
    column: $table.introducedAt,
    builder: (column) => column,
  );

  $$WordsTableAnnotationComposer get wordId {
    final $$WordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.wordId,
      referencedTable: $db.words,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WordsTableAnnotationComposer(
            $db: $db,
            $table: $db.words,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WordProgressTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WordProgressTable,
          WordProgressRow,
          $$WordProgressTableFilterComposer,
          $$WordProgressTableOrderingComposer,
          $$WordProgressTableAnnotationComposer,
          $$WordProgressTableCreateCompanionBuilder,
          $$WordProgressTableUpdateCompanionBuilder,
          (WordProgressRow, $$WordProgressTableReferences),
          WordProgressRow,
          PrefetchHooks Function({bool wordId})
        > {
  $$WordProgressTableTableManager(_$AppDatabase db, $WordProgressTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WordProgressTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WordProgressTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WordProgressTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> wordId = const Value.absent(),
                Value<int> masteryLevel = const Value.absent(),
                Value<int> correctCount = const Value.absent(),
                Value<int> incorrectCount = const Value.absent(),
                Value<int> currentStreak = const Value.absent(),
                Value<DateTime?> lastSeenAt = const Value.absent(),
                Value<DateTime?> nextReviewAt = const Value.absent(),
                Value<bool?> lastResultCorrect = const Value.absent(),
                Value<int> timesShownTotal = const Value.absent(),
                Value<DateTime?> introducedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WordProgressCompanion(
                wordId: wordId,
                masteryLevel: masteryLevel,
                correctCount: correctCount,
                incorrectCount: incorrectCount,
                currentStreak: currentStreak,
                lastSeenAt: lastSeenAt,
                nextReviewAt: nextReviewAt,
                lastResultCorrect: lastResultCorrect,
                timesShownTotal: timesShownTotal,
                introducedAt: introducedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String wordId,
                Value<int> masteryLevel = const Value.absent(),
                Value<int> correctCount = const Value.absent(),
                Value<int> incorrectCount = const Value.absent(),
                Value<int> currentStreak = const Value.absent(),
                Value<DateTime?> lastSeenAt = const Value.absent(),
                Value<DateTime?> nextReviewAt = const Value.absent(),
                Value<bool?> lastResultCorrect = const Value.absent(),
                Value<int> timesShownTotal = const Value.absent(),
                Value<DateTime?> introducedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WordProgressCompanion.insert(
                wordId: wordId,
                masteryLevel: masteryLevel,
                correctCount: correctCount,
                incorrectCount: incorrectCount,
                currentStreak: currentStreak,
                lastSeenAt: lastSeenAt,
                nextReviewAt: nextReviewAt,
                lastResultCorrect: lastResultCorrect,
                timesShownTotal: timesShownTotal,
                introducedAt: introducedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$WordProgressTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({wordId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (wordId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.wordId,
                                referencedTable: $$WordProgressTableReferences
                                    ._wordIdTable(db),
                                referencedColumn: $$WordProgressTableReferences
                                    ._wordIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$WordProgressTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WordProgressTable,
      WordProgressRow,
      $$WordProgressTableFilterComposer,
      $$WordProgressTableOrderingComposer,
      $$WordProgressTableAnnotationComposer,
      $$WordProgressTableCreateCompanionBuilder,
      $$WordProgressTableUpdateCompanionBuilder,
      (WordProgressRow, $$WordProgressTableReferences),
      WordProgressRow,
      PrefetchHooks Function({bool wordId})
    >;
typedef $$UserProfileTableCreateCompanionBuilder =
    UserProfileCompanion Function({
      Value<int> id,
      Value<int> totalXp,
      Value<int> currentLevel,
      Value<int> currentStreakDays,
      Value<int> longestStreakDays,
      Value<String?> lastStudyDate,
      required DateTime createdAt,
    });
typedef $$UserProfileTableUpdateCompanionBuilder =
    UserProfileCompanion Function({
      Value<int> id,
      Value<int> totalXp,
      Value<int> currentLevel,
      Value<int> currentStreakDays,
      Value<int> longestStreakDays,
      Value<String?> lastStudyDate,
      Value<DateTime> createdAt,
    });

class $$UserProfileTableFilterComposer
    extends Composer<_$AppDatabase, $UserProfileTable> {
  $$UserProfileTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalXp => $composableBuilder(
    column: $table.totalXp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get currentLevel => $composableBuilder(
    column: $table.currentLevel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get currentStreakDays => $composableBuilder(
    column: $table.currentStreakDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get longestStreakDays => $composableBuilder(
    column: $table.longestStreakDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastStudyDate => $composableBuilder(
    column: $table.lastStudyDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UserProfileTableOrderingComposer
    extends Composer<_$AppDatabase, $UserProfileTable> {
  $$UserProfileTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalXp => $composableBuilder(
    column: $table.totalXp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get currentLevel => $composableBuilder(
    column: $table.currentLevel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get currentStreakDays => $composableBuilder(
    column: $table.currentStreakDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get longestStreakDays => $composableBuilder(
    column: $table.longestStreakDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastStudyDate => $composableBuilder(
    column: $table.lastStudyDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UserProfileTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserProfileTable> {
  $$UserProfileTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get totalXp =>
      $composableBuilder(column: $table.totalXp, builder: (column) => column);

  GeneratedColumn<int> get currentLevel => $composableBuilder(
    column: $table.currentLevel,
    builder: (column) => column,
  );

  GeneratedColumn<int> get currentStreakDays => $composableBuilder(
    column: $table.currentStreakDays,
    builder: (column) => column,
  );

  GeneratedColumn<int> get longestStreakDays => $composableBuilder(
    column: $table.longestStreakDays,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastStudyDate => $composableBuilder(
    column: $table.lastStudyDate,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$UserProfileTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UserProfileTable,
          UserProfileRow,
          $$UserProfileTableFilterComposer,
          $$UserProfileTableOrderingComposer,
          $$UserProfileTableAnnotationComposer,
          $$UserProfileTableCreateCompanionBuilder,
          $$UserProfileTableUpdateCompanionBuilder,
          (
            UserProfileRow,
            BaseReferences<_$AppDatabase, $UserProfileTable, UserProfileRow>,
          ),
          UserProfileRow,
          PrefetchHooks Function()
        > {
  $$UserProfileTableTableManager(_$AppDatabase db, $UserProfileTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserProfileTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserProfileTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserProfileTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> totalXp = const Value.absent(),
                Value<int> currentLevel = const Value.absent(),
                Value<int> currentStreakDays = const Value.absent(),
                Value<int> longestStreakDays = const Value.absent(),
                Value<String?> lastStudyDate = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => UserProfileCompanion(
                id: id,
                totalXp: totalXp,
                currentLevel: currentLevel,
                currentStreakDays: currentStreakDays,
                longestStreakDays: longestStreakDays,
                lastStudyDate: lastStudyDate,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> totalXp = const Value.absent(),
                Value<int> currentLevel = const Value.absent(),
                Value<int> currentStreakDays = const Value.absent(),
                Value<int> longestStreakDays = const Value.absent(),
                Value<String?> lastStudyDate = const Value.absent(),
                required DateTime createdAt,
              }) => UserProfileCompanion.insert(
                id: id,
                totalXp: totalXp,
                currentLevel: currentLevel,
                currentStreakDays: currentStreakDays,
                longestStreakDays: longestStreakDays,
                lastStudyDate: lastStudyDate,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UserProfileTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UserProfileTable,
      UserProfileRow,
      $$UserProfileTableFilterComposer,
      $$UserProfileTableOrderingComposer,
      $$UserProfileTableAnnotationComposer,
      $$UserProfileTableCreateCompanionBuilder,
      $$UserProfileTableUpdateCompanionBuilder,
      (
        UserProfileRow,
        BaseReferences<_$AppDatabase, $UserProfileTable, UserProfileRow>,
      ),
      UserProfileRow,
      PrefetchHooks Function()
    >;
typedef $$DailyActivityLogTableCreateCompanionBuilder =
    DailyActivityLogCompanion Function({
      required String studyDate,
      Value<int> exercisesCompleted,
      Value<int> correctCount,
      Value<int> xpEarned,
      Value<bool> countsAsActiveDay,
      Value<int> rowid,
    });
typedef $$DailyActivityLogTableUpdateCompanionBuilder =
    DailyActivityLogCompanion Function({
      Value<String> studyDate,
      Value<int> exercisesCompleted,
      Value<int> correctCount,
      Value<int> xpEarned,
      Value<bool> countsAsActiveDay,
      Value<int> rowid,
    });

class $$DailyActivityLogTableFilterComposer
    extends Composer<_$AppDatabase, $DailyActivityLogTable> {
  $$DailyActivityLogTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get studyDate => $composableBuilder(
    column: $table.studyDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get exercisesCompleted => $composableBuilder(
    column: $table.exercisesCompleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get correctCount => $composableBuilder(
    column: $table.correctCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get xpEarned => $composableBuilder(
    column: $table.xpEarned,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get countsAsActiveDay => $composableBuilder(
    column: $table.countsAsActiveDay,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DailyActivityLogTableOrderingComposer
    extends Composer<_$AppDatabase, $DailyActivityLogTable> {
  $$DailyActivityLogTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get studyDate => $composableBuilder(
    column: $table.studyDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get exercisesCompleted => $composableBuilder(
    column: $table.exercisesCompleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get correctCount => $composableBuilder(
    column: $table.correctCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get xpEarned => $composableBuilder(
    column: $table.xpEarned,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get countsAsActiveDay => $composableBuilder(
    column: $table.countsAsActiveDay,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DailyActivityLogTableAnnotationComposer
    extends Composer<_$AppDatabase, $DailyActivityLogTable> {
  $$DailyActivityLogTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get studyDate =>
      $composableBuilder(column: $table.studyDate, builder: (column) => column);

  GeneratedColumn<int> get exercisesCompleted => $composableBuilder(
    column: $table.exercisesCompleted,
    builder: (column) => column,
  );

  GeneratedColumn<int> get correctCount => $composableBuilder(
    column: $table.correctCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get xpEarned =>
      $composableBuilder(column: $table.xpEarned, builder: (column) => column);

  GeneratedColumn<bool> get countsAsActiveDay => $composableBuilder(
    column: $table.countsAsActiveDay,
    builder: (column) => column,
  );
}

class $$DailyActivityLogTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DailyActivityLogTable,
          DailyActivityLogRow,
          $$DailyActivityLogTableFilterComposer,
          $$DailyActivityLogTableOrderingComposer,
          $$DailyActivityLogTableAnnotationComposer,
          $$DailyActivityLogTableCreateCompanionBuilder,
          $$DailyActivityLogTableUpdateCompanionBuilder,
          (
            DailyActivityLogRow,
            BaseReferences<
              _$AppDatabase,
              $DailyActivityLogTable,
              DailyActivityLogRow
            >,
          ),
          DailyActivityLogRow,
          PrefetchHooks Function()
        > {
  $$DailyActivityLogTableTableManager(
    _$AppDatabase db,
    $DailyActivityLogTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DailyActivityLogTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DailyActivityLogTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DailyActivityLogTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> studyDate = const Value.absent(),
                Value<int> exercisesCompleted = const Value.absent(),
                Value<int> correctCount = const Value.absent(),
                Value<int> xpEarned = const Value.absent(),
                Value<bool> countsAsActiveDay = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DailyActivityLogCompanion(
                studyDate: studyDate,
                exercisesCompleted: exercisesCompleted,
                correctCount: correctCount,
                xpEarned: xpEarned,
                countsAsActiveDay: countsAsActiveDay,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String studyDate,
                Value<int> exercisesCompleted = const Value.absent(),
                Value<int> correctCount = const Value.absent(),
                Value<int> xpEarned = const Value.absent(),
                Value<bool> countsAsActiveDay = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DailyActivityLogCompanion.insert(
                studyDate: studyDate,
                exercisesCompleted: exercisesCompleted,
                correctCount: correctCount,
                xpEarned: xpEarned,
                countsAsActiveDay: countsAsActiveDay,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DailyActivityLogTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DailyActivityLogTable,
      DailyActivityLogRow,
      $$DailyActivityLogTableFilterComposer,
      $$DailyActivityLogTableOrderingComposer,
      $$DailyActivityLogTableAnnotationComposer,
      $$DailyActivityLogTableCreateCompanionBuilder,
      $$DailyActivityLogTableUpdateCompanionBuilder,
      (
        DailyActivityLogRow,
        BaseReferences<
          _$AppDatabase,
          $DailyActivityLogTable,
          DailyActivityLogRow
        >,
      ),
      DailyActivityLogRow,
      PrefetchHooks Function()
    >;
typedef $$ExerciseAttemptsTableCreateCompanionBuilder =
    ExerciseAttemptsCompanion Function({
      Value<int> id,
      Value<String?> wordId,
      required String exerciseType,
      required String sessionId,
      required String sessionKind,
      required bool wasCorrect,
      Value<String?> userAnswer,
      required int masteryLevelBefore,
      required int masteryLevelAfter,
      Value<int> xpAwarded,
      Value<int?> responseTimeMs,
      required DateTime attemptedAt,
    });
typedef $$ExerciseAttemptsTableUpdateCompanionBuilder =
    ExerciseAttemptsCompanion Function({
      Value<int> id,
      Value<String?> wordId,
      Value<String> exerciseType,
      Value<String> sessionId,
      Value<String> sessionKind,
      Value<bool> wasCorrect,
      Value<String?> userAnswer,
      Value<int> masteryLevelBefore,
      Value<int> masteryLevelAfter,
      Value<int> xpAwarded,
      Value<int?> responseTimeMs,
      Value<DateTime> attemptedAt,
    });

final class $$ExerciseAttemptsTableReferences
    extends
        BaseReferences<_$AppDatabase, $ExerciseAttemptsTable, ExerciseAttempt> {
  $$ExerciseAttemptsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $WordsTable _wordIdTable(_$AppDatabase db) =>
      db.words.createAlias('exercise_attempts__word_id__words__id');

  $$WordsTableProcessedTableManager? get wordId {
    final $_column = $_itemColumn<String>('word_id');
    if ($_column == null) return null;
    final manager = $$WordsTableTableManager(
      $_db,
      $_db.words,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_wordIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ExerciseAttemptsTableFilterComposer
    extends Composer<_$AppDatabase, $ExerciseAttemptsTable> {
  $$ExerciseAttemptsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get exerciseType => $composableBuilder(
    column: $table.exerciseType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sessionKind => $composableBuilder(
    column: $table.sessionKind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get wasCorrect => $composableBuilder(
    column: $table.wasCorrect,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userAnswer => $composableBuilder(
    column: $table.userAnswer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get masteryLevelBefore => $composableBuilder(
    column: $table.masteryLevelBefore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get masteryLevelAfter => $composableBuilder(
    column: $table.masteryLevelAfter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get xpAwarded => $composableBuilder(
    column: $table.xpAwarded,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get responseTimeMs => $composableBuilder(
    column: $table.responseTimeMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get attemptedAt => $composableBuilder(
    column: $table.attemptedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$WordsTableFilterComposer get wordId {
    final $$WordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.wordId,
      referencedTable: $db.words,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WordsTableFilterComposer(
            $db: $db,
            $table: $db.words,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExerciseAttemptsTableOrderingComposer
    extends Composer<_$AppDatabase, $ExerciseAttemptsTable> {
  $$ExerciseAttemptsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get exerciseType => $composableBuilder(
    column: $table.exerciseType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sessionKind => $composableBuilder(
    column: $table.sessionKind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get wasCorrect => $composableBuilder(
    column: $table.wasCorrect,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userAnswer => $composableBuilder(
    column: $table.userAnswer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get masteryLevelBefore => $composableBuilder(
    column: $table.masteryLevelBefore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get masteryLevelAfter => $composableBuilder(
    column: $table.masteryLevelAfter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get xpAwarded => $composableBuilder(
    column: $table.xpAwarded,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get responseTimeMs => $composableBuilder(
    column: $table.responseTimeMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get attemptedAt => $composableBuilder(
    column: $table.attemptedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$WordsTableOrderingComposer get wordId {
    final $$WordsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.wordId,
      referencedTable: $db.words,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WordsTableOrderingComposer(
            $db: $db,
            $table: $db.words,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExerciseAttemptsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExerciseAttemptsTable> {
  $$ExerciseAttemptsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get exerciseType => $composableBuilder(
    column: $table.exerciseType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<String> get sessionKind => $composableBuilder(
    column: $table.sessionKind,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get wasCorrect => $composableBuilder(
    column: $table.wasCorrect,
    builder: (column) => column,
  );

  GeneratedColumn<String> get userAnswer => $composableBuilder(
    column: $table.userAnswer,
    builder: (column) => column,
  );

  GeneratedColumn<int> get masteryLevelBefore => $composableBuilder(
    column: $table.masteryLevelBefore,
    builder: (column) => column,
  );

  GeneratedColumn<int> get masteryLevelAfter => $composableBuilder(
    column: $table.masteryLevelAfter,
    builder: (column) => column,
  );

  GeneratedColumn<int> get xpAwarded =>
      $composableBuilder(column: $table.xpAwarded, builder: (column) => column);

  GeneratedColumn<int> get responseTimeMs => $composableBuilder(
    column: $table.responseTimeMs,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get attemptedAt => $composableBuilder(
    column: $table.attemptedAt,
    builder: (column) => column,
  );

  $$WordsTableAnnotationComposer get wordId {
    final $$WordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.wordId,
      referencedTable: $db.words,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WordsTableAnnotationComposer(
            $db: $db,
            $table: $db.words,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExerciseAttemptsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ExerciseAttemptsTable,
          ExerciseAttempt,
          $$ExerciseAttemptsTableFilterComposer,
          $$ExerciseAttemptsTableOrderingComposer,
          $$ExerciseAttemptsTableAnnotationComposer,
          $$ExerciseAttemptsTableCreateCompanionBuilder,
          $$ExerciseAttemptsTableUpdateCompanionBuilder,
          (ExerciseAttempt, $$ExerciseAttemptsTableReferences),
          ExerciseAttempt,
          PrefetchHooks Function({bool wordId})
        > {
  $$ExerciseAttemptsTableTableManager(
    _$AppDatabase db,
    $ExerciseAttemptsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExerciseAttemptsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExerciseAttemptsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExerciseAttemptsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> wordId = const Value.absent(),
                Value<String> exerciseType = const Value.absent(),
                Value<String> sessionId = const Value.absent(),
                Value<String> sessionKind = const Value.absent(),
                Value<bool> wasCorrect = const Value.absent(),
                Value<String?> userAnswer = const Value.absent(),
                Value<int> masteryLevelBefore = const Value.absent(),
                Value<int> masteryLevelAfter = const Value.absent(),
                Value<int> xpAwarded = const Value.absent(),
                Value<int?> responseTimeMs = const Value.absent(),
                Value<DateTime> attemptedAt = const Value.absent(),
              }) => ExerciseAttemptsCompanion(
                id: id,
                wordId: wordId,
                exerciseType: exerciseType,
                sessionId: sessionId,
                sessionKind: sessionKind,
                wasCorrect: wasCorrect,
                userAnswer: userAnswer,
                masteryLevelBefore: masteryLevelBefore,
                masteryLevelAfter: masteryLevelAfter,
                xpAwarded: xpAwarded,
                responseTimeMs: responseTimeMs,
                attemptedAt: attemptedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> wordId = const Value.absent(),
                required String exerciseType,
                required String sessionId,
                required String sessionKind,
                required bool wasCorrect,
                Value<String?> userAnswer = const Value.absent(),
                required int masteryLevelBefore,
                required int masteryLevelAfter,
                Value<int> xpAwarded = const Value.absent(),
                Value<int?> responseTimeMs = const Value.absent(),
                required DateTime attemptedAt,
              }) => ExerciseAttemptsCompanion.insert(
                id: id,
                wordId: wordId,
                exerciseType: exerciseType,
                sessionId: sessionId,
                sessionKind: sessionKind,
                wasCorrect: wasCorrect,
                userAnswer: userAnswer,
                masteryLevelBefore: masteryLevelBefore,
                masteryLevelAfter: masteryLevelAfter,
                xpAwarded: xpAwarded,
                responseTimeMs: responseTimeMs,
                attemptedAt: attemptedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ExerciseAttemptsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({wordId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (wordId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.wordId,
                                referencedTable:
                                    $$ExerciseAttemptsTableReferences
                                        ._wordIdTable(db),
                                referencedColumn:
                                    $$ExerciseAttemptsTableReferences
                                        ._wordIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ExerciseAttemptsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ExerciseAttemptsTable,
      ExerciseAttempt,
      $$ExerciseAttemptsTableFilterComposer,
      $$ExerciseAttemptsTableOrderingComposer,
      $$ExerciseAttemptsTableAnnotationComposer,
      $$ExerciseAttemptsTableCreateCompanionBuilder,
      $$ExerciseAttemptsTableUpdateCompanionBuilder,
      (ExerciseAttempt, $$ExerciseAttemptsTableReferences),
      ExerciseAttempt,
      PrefetchHooks Function({bool wordId})
    >;
typedef $$DinoEvolutionStateTableCreateCompanionBuilder =
    DinoEvolutionStateCompanion Function({
      Value<int> id,
      Value<String> stage,
      Value<DateTime?> hatchingStartedAt,
      Value<DateTime?> hatchedAt,
    });
typedef $$DinoEvolutionStateTableUpdateCompanionBuilder =
    DinoEvolutionStateCompanion Function({
      Value<int> id,
      Value<String> stage,
      Value<DateTime?> hatchingStartedAt,
      Value<DateTime?> hatchedAt,
    });

class $$DinoEvolutionStateTableFilterComposer
    extends Composer<_$AppDatabase, $DinoEvolutionStateTable> {
  $$DinoEvolutionStateTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stage => $composableBuilder(
    column: $table.stage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get hatchingStartedAt => $composableBuilder(
    column: $table.hatchingStartedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get hatchedAt => $composableBuilder(
    column: $table.hatchedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DinoEvolutionStateTableOrderingComposer
    extends Composer<_$AppDatabase, $DinoEvolutionStateTable> {
  $$DinoEvolutionStateTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stage => $composableBuilder(
    column: $table.stage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get hatchingStartedAt => $composableBuilder(
    column: $table.hatchingStartedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get hatchedAt => $composableBuilder(
    column: $table.hatchedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DinoEvolutionStateTableAnnotationComposer
    extends Composer<_$AppDatabase, $DinoEvolutionStateTable> {
  $$DinoEvolutionStateTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get stage =>
      $composableBuilder(column: $table.stage, builder: (column) => column);

  GeneratedColumn<DateTime> get hatchingStartedAt => $composableBuilder(
    column: $table.hatchingStartedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get hatchedAt =>
      $composableBuilder(column: $table.hatchedAt, builder: (column) => column);
}

class $$DinoEvolutionStateTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DinoEvolutionStateTable,
          DinoEvolutionStateRow,
          $$DinoEvolutionStateTableFilterComposer,
          $$DinoEvolutionStateTableOrderingComposer,
          $$DinoEvolutionStateTableAnnotationComposer,
          $$DinoEvolutionStateTableCreateCompanionBuilder,
          $$DinoEvolutionStateTableUpdateCompanionBuilder,
          (
            DinoEvolutionStateRow,
            BaseReferences<
              _$AppDatabase,
              $DinoEvolutionStateTable,
              DinoEvolutionStateRow
            >,
          ),
          DinoEvolutionStateRow,
          PrefetchHooks Function()
        > {
  $$DinoEvolutionStateTableTableManager(
    _$AppDatabase db,
    $DinoEvolutionStateTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DinoEvolutionStateTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DinoEvolutionStateTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DinoEvolutionStateTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> stage = const Value.absent(),
                Value<DateTime?> hatchingStartedAt = const Value.absent(),
                Value<DateTime?> hatchedAt = const Value.absent(),
              }) => DinoEvolutionStateCompanion(
                id: id,
                stage: stage,
                hatchingStartedAt: hatchingStartedAt,
                hatchedAt: hatchedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> stage = const Value.absent(),
                Value<DateTime?> hatchingStartedAt = const Value.absent(),
                Value<DateTime?> hatchedAt = const Value.absent(),
              }) => DinoEvolutionStateCompanion.insert(
                id: id,
                stage: stage,
                hatchingStartedAt: hatchingStartedAt,
                hatchedAt: hatchedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DinoEvolutionStateTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DinoEvolutionStateTable,
      DinoEvolutionStateRow,
      $$DinoEvolutionStateTableFilterComposer,
      $$DinoEvolutionStateTableOrderingComposer,
      $$DinoEvolutionStateTableAnnotationComposer,
      $$DinoEvolutionStateTableCreateCompanionBuilder,
      $$DinoEvolutionStateTableUpdateCompanionBuilder,
      (
        DinoEvolutionStateRow,
        BaseReferences<
          _$AppDatabase,
          $DinoEvolutionStateTable,
          DinoEvolutionStateRow
        >,
      ),
      DinoEvolutionStateRow,
      PrefetchHooks Function()
    >;
typedef $$AppSettingsTableCreateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<int> id,
      Value<bool> soundEnabled,
      Value<int> dailyGoalExercises,
      Value<String> themeMode,
      Value<bool> onboardingCompleted,
    });
typedef $$AppSettingsTableUpdateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<int> id,
      Value<bool> soundEnabled,
      Value<int> dailyGoalExercises,
      Value<String> themeMode,
      Value<bool> onboardingCompleted,
    });

class $$AppSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get soundEnabled => $composableBuilder(
    column: $table.soundEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dailyGoalExercises => $composableBuilder(
    column: $table.dailyGoalExercises,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get themeMode => $composableBuilder(
    column: $table.themeMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get onboardingCompleted => $composableBuilder(
    column: $table.onboardingCompleted,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get soundEnabled => $composableBuilder(
    column: $table.soundEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dailyGoalExercises => $composableBuilder(
    column: $table.dailyGoalExercises,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get themeMode => $composableBuilder(
    column: $table.themeMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get onboardingCompleted => $composableBuilder(
    column: $table.onboardingCompleted,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<bool> get soundEnabled => $composableBuilder(
    column: $table.soundEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<int> get dailyGoalExercises => $composableBuilder(
    column: $table.dailyGoalExercises,
    builder: (column) => column,
  );

  GeneratedColumn<String> get themeMode =>
      $composableBuilder(column: $table.themeMode, builder: (column) => column);

  GeneratedColumn<bool> get onboardingCompleted => $composableBuilder(
    column: $table.onboardingCompleted,
    builder: (column) => column,
  );
}

class $$AppSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppSettingsTable,
          AppSettingsRow,
          $$AppSettingsTableFilterComposer,
          $$AppSettingsTableOrderingComposer,
          $$AppSettingsTableAnnotationComposer,
          $$AppSettingsTableCreateCompanionBuilder,
          $$AppSettingsTableUpdateCompanionBuilder,
          (
            AppSettingsRow,
            BaseReferences<_$AppDatabase, $AppSettingsTable, AppSettingsRow>,
          ),
          AppSettingsRow,
          PrefetchHooks Function()
        > {
  $$AppSettingsTableTableManager(_$AppDatabase db, $AppSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<bool> soundEnabled = const Value.absent(),
                Value<int> dailyGoalExercises = const Value.absent(),
                Value<String> themeMode = const Value.absent(),
                Value<bool> onboardingCompleted = const Value.absent(),
              }) => AppSettingsCompanion(
                id: id,
                soundEnabled: soundEnabled,
                dailyGoalExercises: dailyGoalExercises,
                themeMode: themeMode,
                onboardingCompleted: onboardingCompleted,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<bool> soundEnabled = const Value.absent(),
                Value<int> dailyGoalExercises = const Value.absent(),
                Value<String> themeMode = const Value.absent(),
                Value<bool> onboardingCompleted = const Value.absent(),
              }) => AppSettingsCompanion.insert(
                id: id,
                soundEnabled: soundEnabled,
                dailyGoalExercises: dailyGoalExercises,
                themeMode: themeMode,
                onboardingCompleted: onboardingCompleted,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppSettingsTable,
      AppSettingsRow,
      $$AppSettingsTableFilterComposer,
      $$AppSettingsTableOrderingComposer,
      $$AppSettingsTableAnnotationComposer,
      $$AppSettingsTableCreateCompanionBuilder,
      $$AppSettingsTableUpdateCompanionBuilder,
      (
        AppSettingsRow,
        BaseReferences<_$AppDatabase, $AppSettingsTable, AppSettingsRow>,
      ),
      AppSettingsRow,
      PrefetchHooks Function()
    >;
typedef $$SeedMetadataTableCreateCompanionBuilder =
    SeedMetadataCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$SeedMetadataTableUpdateCompanionBuilder =
    SeedMetadataCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$SeedMetadataTableFilterComposer
    extends Composer<_$AppDatabase, $SeedMetadataTable> {
  $$SeedMetadataTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SeedMetadataTableOrderingComposer
    extends Composer<_$AppDatabase, $SeedMetadataTable> {
  $$SeedMetadataTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SeedMetadataTableAnnotationComposer
    extends Composer<_$AppDatabase, $SeedMetadataTable> {
  $$SeedMetadataTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SeedMetadataTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SeedMetadataTable,
          SeedMetadataRow,
          $$SeedMetadataTableFilterComposer,
          $$SeedMetadataTableOrderingComposer,
          $$SeedMetadataTableAnnotationComposer,
          $$SeedMetadataTableCreateCompanionBuilder,
          $$SeedMetadataTableUpdateCompanionBuilder,
          (
            SeedMetadataRow,
            BaseReferences<_$AppDatabase, $SeedMetadataTable, SeedMetadataRow>,
          ),
          SeedMetadataRow,
          PrefetchHooks Function()
        > {
  $$SeedMetadataTableTableManager(_$AppDatabase db, $SeedMetadataTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SeedMetadataTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SeedMetadataTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SeedMetadataTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SeedMetadataCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => SeedMetadataCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SeedMetadataTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SeedMetadataTable,
      SeedMetadataRow,
      $$SeedMetadataTableFilterComposer,
      $$SeedMetadataTableOrderingComposer,
      $$SeedMetadataTableAnnotationComposer,
      $$SeedMetadataTableCreateCompanionBuilder,
      $$SeedMetadataTableUpdateCompanionBuilder,
      (
        SeedMetadataRow,
        BaseReferences<_$AppDatabase, $SeedMetadataTable, SeedMetadataRow>,
      ),
      SeedMetadataRow,
      PrefetchHooks Function()
    >;
typedef $$DinoMemoriesTableCreateCompanionBuilder =
    DinoMemoriesCompanion Function({
      required String kind,
      required String memoryKey,
      required String value,
      Value<double> confidence,
      Value<int> timesReinforced,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$DinoMemoriesTableUpdateCompanionBuilder =
    DinoMemoriesCompanion Function({
      Value<String> kind,
      Value<String> memoryKey,
      Value<String> value,
      Value<double> confidence,
      Value<int> timesReinforced,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$DinoMemoriesTableFilterComposer
    extends Composer<_$AppDatabase, $DinoMemoriesTable> {
  $$DinoMemoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get memoryKey => $composableBuilder(
    column: $table.memoryKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get timesReinforced => $composableBuilder(
    column: $table.timesReinforced,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DinoMemoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $DinoMemoriesTable> {
  $$DinoMemoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get memoryKey => $composableBuilder(
    column: $table.memoryKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get timesReinforced => $composableBuilder(
    column: $table.timesReinforced,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DinoMemoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $DinoMemoriesTable> {
  $$DinoMemoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get memoryKey =>
      $composableBuilder(column: $table.memoryKey, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => column,
  );

  GeneratedColumn<int> get timesReinforced => $composableBuilder(
    column: $table.timesReinforced,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$DinoMemoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DinoMemoriesTable,
          DinoMemoryRow,
          $$DinoMemoriesTableFilterComposer,
          $$DinoMemoriesTableOrderingComposer,
          $$DinoMemoriesTableAnnotationComposer,
          $$DinoMemoriesTableCreateCompanionBuilder,
          $$DinoMemoriesTableUpdateCompanionBuilder,
          (
            DinoMemoryRow,
            BaseReferences<_$AppDatabase, $DinoMemoriesTable, DinoMemoryRow>,
          ),
          DinoMemoryRow,
          PrefetchHooks Function()
        > {
  $$DinoMemoriesTableTableManager(_$AppDatabase db, $DinoMemoriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DinoMemoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DinoMemoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DinoMemoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> kind = const Value.absent(),
                Value<String> memoryKey = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<double> confidence = const Value.absent(),
                Value<int> timesReinforced = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DinoMemoriesCompanion(
                kind: kind,
                memoryKey: memoryKey,
                value: value,
                confidence: confidence,
                timesReinforced: timesReinforced,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String kind,
                required String memoryKey,
                required String value,
                Value<double> confidence = const Value.absent(),
                Value<int> timesReinforced = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => DinoMemoriesCompanion.insert(
                kind: kind,
                memoryKey: memoryKey,
                value: value,
                confidence: confidence,
                timesReinforced: timesReinforced,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DinoMemoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DinoMemoriesTable,
      DinoMemoryRow,
      $$DinoMemoriesTableFilterComposer,
      $$DinoMemoriesTableOrderingComposer,
      $$DinoMemoriesTableAnnotationComposer,
      $$DinoMemoriesTableCreateCompanionBuilder,
      $$DinoMemoriesTableUpdateCompanionBuilder,
      (
        DinoMemoryRow,
        BaseReferences<_$AppDatabase, $DinoMemoriesTable, DinoMemoryRow>,
      ),
      DinoMemoryRow,
      PrefetchHooks Function()
    >;
typedef $$CompanionStatesTableCreateCompanionBuilder =
    CompanionStatesCompanion Function({
      Value<int> id,
      required double hunger,
      required double thirst,
      required double energy,
      required double happiness,
      Value<bool> isSleeping,
      Value<int> careXpToday,
      Value<String?> careXpDate,
      required DateTime updatedAt,
    });
typedef $$CompanionStatesTableUpdateCompanionBuilder =
    CompanionStatesCompanion Function({
      Value<int> id,
      Value<double> hunger,
      Value<double> thirst,
      Value<double> energy,
      Value<double> happiness,
      Value<bool> isSleeping,
      Value<int> careXpToday,
      Value<String?> careXpDate,
      Value<DateTime> updatedAt,
    });

class $$CompanionStatesTableFilterComposer
    extends Composer<_$AppDatabase, $CompanionStatesTable> {
  $$CompanionStatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get hunger => $composableBuilder(
    column: $table.hunger,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get thirst => $composableBuilder(
    column: $table.thirst,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get energy => $composableBuilder(
    column: $table.energy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get happiness => $composableBuilder(
    column: $table.happiness,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSleeping => $composableBuilder(
    column: $table.isSleeping,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get careXpToday => $composableBuilder(
    column: $table.careXpToday,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get careXpDate => $composableBuilder(
    column: $table.careXpDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CompanionStatesTableOrderingComposer
    extends Composer<_$AppDatabase, $CompanionStatesTable> {
  $$CompanionStatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get hunger => $composableBuilder(
    column: $table.hunger,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get thirst => $composableBuilder(
    column: $table.thirst,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get energy => $composableBuilder(
    column: $table.energy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get happiness => $composableBuilder(
    column: $table.happiness,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSleeping => $composableBuilder(
    column: $table.isSleeping,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get careXpToday => $composableBuilder(
    column: $table.careXpToday,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get careXpDate => $composableBuilder(
    column: $table.careXpDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CompanionStatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CompanionStatesTable> {
  $$CompanionStatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get hunger =>
      $composableBuilder(column: $table.hunger, builder: (column) => column);

  GeneratedColumn<double> get thirst =>
      $composableBuilder(column: $table.thirst, builder: (column) => column);

  GeneratedColumn<double> get energy =>
      $composableBuilder(column: $table.energy, builder: (column) => column);

  GeneratedColumn<double> get happiness =>
      $composableBuilder(column: $table.happiness, builder: (column) => column);

  GeneratedColumn<bool> get isSleeping => $composableBuilder(
    column: $table.isSleeping,
    builder: (column) => column,
  );

  GeneratedColumn<int> get careXpToday => $composableBuilder(
    column: $table.careXpToday,
    builder: (column) => column,
  );

  GeneratedColumn<String> get careXpDate => $composableBuilder(
    column: $table.careXpDate,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CompanionStatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CompanionStatesTable,
          CompanionStateRow,
          $$CompanionStatesTableFilterComposer,
          $$CompanionStatesTableOrderingComposer,
          $$CompanionStatesTableAnnotationComposer,
          $$CompanionStatesTableCreateCompanionBuilder,
          $$CompanionStatesTableUpdateCompanionBuilder,
          (
            CompanionStateRow,
            BaseReferences<
              _$AppDatabase,
              $CompanionStatesTable,
              CompanionStateRow
            >,
          ),
          CompanionStateRow,
          PrefetchHooks Function()
        > {
  $$CompanionStatesTableTableManager(
    _$AppDatabase db,
    $CompanionStatesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CompanionStatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CompanionStatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CompanionStatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<double> hunger = const Value.absent(),
                Value<double> thirst = const Value.absent(),
                Value<double> energy = const Value.absent(),
                Value<double> happiness = const Value.absent(),
                Value<bool> isSleeping = const Value.absent(),
                Value<int> careXpToday = const Value.absent(),
                Value<String?> careXpDate = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => CompanionStatesCompanion(
                id: id,
                hunger: hunger,
                thirst: thirst,
                energy: energy,
                happiness: happiness,
                isSleeping: isSleeping,
                careXpToday: careXpToday,
                careXpDate: careXpDate,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required double hunger,
                required double thirst,
                required double energy,
                required double happiness,
                Value<bool> isSleeping = const Value.absent(),
                Value<int> careXpToday = const Value.absent(),
                Value<String?> careXpDate = const Value.absent(),
                required DateTime updatedAt,
              }) => CompanionStatesCompanion.insert(
                id: id,
                hunger: hunger,
                thirst: thirst,
                energy: energy,
                happiness: happiness,
                isSleeping: isSleeping,
                careXpToday: careXpToday,
                careXpDate: careXpDate,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CompanionStatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CompanionStatesTable,
      CompanionStateRow,
      $$CompanionStatesTableFilterComposer,
      $$CompanionStatesTableOrderingComposer,
      $$CompanionStatesTableAnnotationComposer,
      $$CompanionStatesTableCreateCompanionBuilder,
      $$CompanionStatesTableUpdateCompanionBuilder,
      (
        CompanionStateRow,
        BaseReferences<_$AppDatabase, $CompanionStatesTable, CompanionStateRow>,
      ),
      CompanionStateRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$WordsTableTableManager get words =>
      $$WordsTableTableManager(_db, _db.words);
  $$WordProgressTableTableManager get wordProgress =>
      $$WordProgressTableTableManager(_db, _db.wordProgress);
  $$UserProfileTableTableManager get userProfile =>
      $$UserProfileTableTableManager(_db, _db.userProfile);
  $$DailyActivityLogTableTableManager get dailyActivityLog =>
      $$DailyActivityLogTableTableManager(_db, _db.dailyActivityLog);
  $$ExerciseAttemptsTableTableManager get exerciseAttempts =>
      $$ExerciseAttemptsTableTableManager(_db, _db.exerciseAttempts);
  $$DinoEvolutionStateTableTableManager get dinoEvolutionState =>
      $$DinoEvolutionStateTableTableManager(_db, _db.dinoEvolutionState);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
  $$SeedMetadataTableTableManager get seedMetadata =>
      $$SeedMetadataTableTableManager(_db, _db.seedMetadata);
  $$DinoMemoriesTableTableManager get dinoMemories =>
      $$DinoMemoriesTableTableManager(_db, _db.dinoMemories);
  $$CompanionStatesTableTableManager get companionStates =>
      $$CompanionStatesTableTableManager(_db, _db.companionStates);
}
