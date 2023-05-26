import 'package:bdd_widget_test/src/cli/cli.dart';
import 'package:bdd_widget_test/src/existing_steps.dart';
import 'package:bdd_widget_test/src/feature_file.dart';
import 'package:bdd_widget_test/src/generator_options.dart';
import 'package:bdd_widget_test/src/step_file.dart';
import 'package:bdd_widget_test/src/util/fs.dart';
import 'package:build/build.dart';
import 'package:mason_logger/mason_logger.dart';

Builder featureBuilder(BuilderOptions options) => FeatureBuilder(
      GeneratorOptions.fromMap(options.config),
    );

class FeatureBuilder implements Builder {
  FeatureBuilder(this.generatorOptions);

  final GeneratorOptions generatorOptions;
  final logger = Logger();

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
      final filePath =
          '${featureTestFolder.path}/${name}_scenario_${(i++).toString().padLeft(2, '0')}_test.dart';

      await createFileRecursively(
        filePath,
        content,
        regenerate: true,
      );
    }

    final expectedOutput = expectedOutputs(this, inputId).first;

    await buildStep.writeAsString(expectedOutput, contents);

    final steps =
        feature.getStepFiles().whereType<NewStepFile>().map((e) async {
      await createFileRecursively(e.filename, e.dartContent);
    });

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

  Future<void> posProccess(String filePath) async {
    await dartFormat(logger, filePath);
    await applyDartFixes(logger, filePath);
    await dartFormat(logger, filePath);
  }

  Future<void> createFileRecursively(
    String filename,
    String content, {
    bool regenerate = false,
  }) async {
    final f = fs.file(filename);
    if (f.existsSync()) {
      if (regenerate) {
        f.deleteSync(recursive: true);
      } else {
        return;
      }
    }
    final file = await f.create(recursive: true);
    await file.writeAsString(content);
    await posProccess(filename);
  }

  @override
  final buildExtensions = const {
    'test/features/{{name}}.feature': [
      'test/{{name}}/.tracker',
      'test/{{name}}/'
    ],
  };
}

Future<void> dartFormat(
  Logger logger,
  String filePath, {
  bool recursive = false,
}) async {
  final isDartInstalled = await Dart.installed(logger: logger);
  if (isDartInstalled) {
    await Dart.format(
      filePath: filePath,
      logger: logger,
    );
  }
}

Future<void> applyDartFixes(
  Logger logger,
  String filePath, {
  bool recursive = false,
}) async {
  final isDartInstalled = await Dart.installed(logger: logger);
  if (isDartInstalled) {
    await Dart.applyFixes(
      filePath: filePath,
      logger: logger,
    );
  }
}
