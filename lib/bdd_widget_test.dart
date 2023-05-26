import 'package:bdd_widget_test/src/existing_steps.dart';
import 'package:bdd_widget_test/src/feature_file.dart';
import 'package:bdd_widget_test/src/generator_options.dart';
import 'package:bdd_widget_test/src/step_file.dart';
import 'package:bdd_widget_test/src/util/fs.dart';
import 'package:build/build.dart';

Builder featureBuilder(BuilderOptions options) => FeatureBuilder(
      GeneratorOptions.fromMap(options.config),
    );

class FeatureBuilder implements Builder {
  FeatureBuilder(this.generatorOptions);

  final GeneratorOptions generatorOptions;

  @override
  Future<void> build(BuildStep buildStep) async {
    final options = await prepareOptions();

    final inputId = buildStep.inputId;
    final contents = await buildStep.readAsString(inputId);

    final isIntegrationTest = inputId.pathSegments.contains('integration_test');

    final featureDir = isIntegrationTest ? 'integration_test' : 'test';

    final featureTestFolder = expectedOutputs(this, inputId).last;
    final name = featureTestFolder.pathSegments.last;

    final feature = FeatureFile(
      featureDir: featureTestFolder.path,
      package: inputId.package,
      isIntegrationTest: isIntegrationTest,
      existingSteps: getExistingStepSubfolders(featureDir, 'step'),
      input: contents,
      generatorOptions: options,
    );

    var i = 1;

    for (final content in feature.dartContent) {
      await createFileRecursively(
        '${featureTestFolder.path}/${name}_scenario_${(i++).toString().padLeft(2, '0')}_test.dart',
        content,
      );
    }

    final expectedOutput = expectedOutputs(this, inputId).first;

    await buildStep.writeAsString(expectedOutput, contents);

    final steps = feature
        .getStepFiles()
        .whereType<NewStepFile>()
        .map((e) => createFileRecursively(e.filename, e.dartContent));
    await Future.wait(steps);
  }

  Future<GeneratorOptions> prepareOptions() async {
    final fileOptions = fs.file('bdd_options.yaml').existsSync()
        ? readFromUri(Uri.file('bdd_options.yaml'))
        : null;
    final mergedOptions = fileOptions != null
        ? merge(generatorOptions, fileOptions)
        : generatorOptions;
    final options = await flattenOptions(mergedOptions);
    return options;
  }

  Future<void> createFileRecursively(String filename, String content) async {
    final f = fs.file(filename);
    if (f.existsSync()) {
      f.deleteSync(recursive: true);
    }
    final file = await f.create(recursive: true);
    await file.writeAsString(content);
  }

  @override
  final buildExtensions = const {
    'test/features/{{name}}.feature': [
      'test/{{name}}/.tracker',
      'test/{{name}}/'
    ],
  };
}
