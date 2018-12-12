import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:shared_pref_annotation/shared_pref_annotation.dart';
import 'package:source_gen/source_gen.dart';

Builder sharedPreferencesGenerator(BuilderOptions options) {
  return SharedPartBuilder(
      [SharedPreferenecesGenerator()], "shared_preferences_generator");
}

Builder reactiveSharedPreferencesGenerator(BuilderOptions options) {
  return SharedPartBuilder([ReactiveSharedPreferencesGenerator()],
      "reactive_shared_preferences_generator");
}

class SharedPreferenecesGenerator
    extends GeneratorForAnnotation<PreferencesHolder> {
  @override
  FutureOr<String> generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) {
    if (element is ClassElement) {
      final generatedClass = _generateClassBuilder(element).build();
      final emitter = DartEmitter();
      return (DartFormatter().format('${generatedClass.accept(emitter)}'));
    }
    return "// Annotation found but it's not annotating a class";
  }
}

class ReactiveSharedPreferencesGenerator
    extends GeneratorForAnnotation<ReactivePreferencesHolder> {
  @override
  FutureOr<String> generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) {
    if (element is ClassElement) {
      final generatedClass = (_generateClassBuilder(element)
            ..fields
                .addAll(element.fields.map<Field>(_generateBehaviourSubject)))
          .build();
      final emitter = DartEmitter();
      return (DartFormatter().format('${generatedClass.accept(emitter)}'));
    }

    return "// Annotation found but it's not annotating a class";
  }
}

Field _generateBehaviourSubject(FieldElement element) {
  return Field((b) => b
    ..name = '_${element.name}Sub'
    ..type = refer('BehaviourSubject<${element.type.displayName}>')
    ..modifier = FieldModifier.final$);
}

ConstructorBuilder _generateBasicConstructor(ConstructorBuilder builder) =>
    builder
      ..initializers.add(const Code('this._adapter = adapter'))
      ..requiredParameters.add(
        Parameter((b) => b
          ..type = refer('PreferenceAdapter')
          ..name = 'adapter'),
      );

ClassBuilder _generateClassBuilder(ClassElement element,
        {Constructor injectedConstructor}) =>
    ClassBuilder()
      ..fields.add(Field((b) => b
        ..name = '_cache'
        ..type = refer('Map<String, dynamic>')
        ..modifier = FieldModifier.final$
        ..assignment = Code('Map<String, dynamic>()')))
      ..fields.add(Field((b) => b
        ..name = '_adapter'
        ..modifier = FieldModifier.final$
        ..type = refer('PreferenceAdapter')))
      ..name = "_\$${element.name}"
      ..implements.add(refer(element.name))
      ..constructors.add(
        injectedConstructor ?? Constructor(_generateBasicConstructor),
      )
      ..methods.addAll(element.fields.map<Method>(_generateAsyncGetter))
      ..methods.addAll(element.fields.map<Method>(_generateAsyncSetter))
      ..methods.addAll(element.fields.map<Method>(_generateSetter))
      ..methods.addAll(element.fields.map<Method>(_generateGetter));

Method _generateSetter(FieldElement field) {
  String code;
  switch (field.type.displayName) {
    case 'bool':
      code = '_adapter.setBool("${field.name}", value);';
      break;
    case 'int':
      code = '_adapter.setInt("${field.name}", value);';
      break;
    case 'String':
      code = '_adapter.setString("${field.name}", value);';
      break;
    case 'List<String>':
      code = '_adapter.setStringList("${field.name}", value);';
      break;
    case 'double':
      code = '_adapter.setDouble("${field.name}", value);';
      break;
  }

  code += '\n _cache["${field.name}"] = value;';
  return Method((b) => b
    ..name = field.name
    ..body = Code(code)
    ..requiredParameters.add(Parameter((b) => b
      ..name = 'value'
      ..type = refer(field.type.displayName)))
    ..type = MethodType.setter);
}

Method _generateGetter(FieldElement field) {
  Code code;
  switch (field.type.displayName) {
    case 'bool':
      code = Code('return _cache["${field.name}"] as bool;');
      break;
    case 'int':
      code = Code('return _cache["${field.name}"] as int;');
      break;
    case 'String':
      code = Code('return _cache["${field.name}"] as String;');
      break;
    case 'List<String>':
      code = Code('return List<String>.from(_cache["${field.name}"] as List);');
      break;
    case 'double':
      code = Code('return _cache["${field.name}"] as double;');
      break;
  }

  return Method((b) => b
    ..name = field.name
    ..body = code
    ..returns = refer(field.type.displayName)
    ..type = MethodType.getter);
}

Method _generateAsyncGetter(FieldElement field) {
  Code code;
  switch (field.type.displayName) {
    case 'bool':
      code = Code('return _adapter.getBool("${field.name}");');
      break;
    case 'int':
      code = Code('return _adapter.getInt("${field.name}");');
      break;
    case 'String':
      code = Code('return _adapter.getString("${field.name}");');
      break;
    case 'List<String>':
      code = Code('return _adapter.getStringList("${field.name}");');
      break;
    case 'double':
      code = Code('return _adapter.getDouble("${field.name}");');
      break;
  }

  return Method((b) => b
    ..name = "${field.name}Async"
    ..body = code
    ..returns = refer("Future<${field.type.displayName}>"));
}

Method _generateAsyncSetter(FieldElement field) {
  String code = '_cache["${field.name}"] = value; \n';
  switch (field.type.displayName) {
    case 'bool':
      code += 'return _adapter.setBool("${field.name}", value);';
      break;
    case 'int':
      code += 'return _adapter.setInt("${field.name}", value);';
      break;
    case 'String':
      code += 'return _adapter.setString("${field.name}", value);';
      break;
    case 'List<String>':
      code += 'return _adapter.setStringList("${field.name}", value);';
      break;
    case 'double':
      code += 'return _adapter.setDouble("${field.name}", value);';
      break;
  }

  return Method((b) => b
    ..name = "${field.name}AsyncSet"
    ..body = Code(code)
    ..requiredParameters.add(Parameter((b) => b
      ..name = 'value'
      ..type = refer(field.type.displayName)))
    ..returns = refer("Future<void>"));
}
