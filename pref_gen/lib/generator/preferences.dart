import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:pref_gen_annotations/pref_gen_annotations.dart';
import 'package:source_gen/source_gen.dart';
import 'package:pref_gen/generator/generator.dart';

Builder sharedPreferencesGenerator(BuilderOptions options) {
  return SharedPartBuilder(
      [SharedPreferenecesGenerator()], "shared_preferences_generator");
}

class SharedPreferenecesGenerator
    extends GeneratorForAnnotation<PreferencesHolder> {
  @override
  FutureOr<String> generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) {
    if (element is ClassElement) {
      final generatedClass = generateClassBuilder(element).build();
      final emitter = DartEmitter();
      return (DartFormatter().format(
          '${generatedClass.accept(emitter)} \n${generateAbstractClass(element)}'));
    }
    return "// Annotation found but it's not annotating a class";
  }
}

String generateAbstractClass(ClassElement element) {
  final generatedClass = ClassBuilder()
    ..abstract = true
    ..name = "${element.name}Preferences"
    ..methods.addAll(element.fields.map((field) => Method((b) => b
      ..name = "${field.name}Async"
      ..returns = refer("Future<${field.type.displayName}>"))))
    ..methods.addAll(element.fields.map((field) => Method((b) => b
      ..name = "${field.name}AsyncSet"
      ..requiredParameters.add(Parameter((b) => b
        ..name = 'value'
        ..type = refer(field.type.displayName)))
      ..returns = refer("Future<void>"))));
  final emitter = DartEmitter();
  return (DartFormatter().format('${generatedClass.build().accept(emitter)}'));
}
