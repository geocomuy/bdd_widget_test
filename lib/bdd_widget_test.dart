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

    final feature = FeatureFile(
      featureDir: featureDir,
      package: inputId.package,
      isIntegrationTest: isIntegrationTest,
      existingSteps: getExistingStepSubfolders(featureDir, options.stepFolder),
      input: contents,
      generatorOptions: options,
    );

    final featureDart = expectedOutputs(this, inputId).first;
    await buildStep.writeAsString(featureDart, feature.dartContent);

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
      return;
    }
    final file = await f.create(recursive: true);
    await file.writeAsString(content);
  }

  @override
  final buildExtensions = const {
    'test/features/{{}}.feature': ['test/{{}}_test.dart'],
  };
}
