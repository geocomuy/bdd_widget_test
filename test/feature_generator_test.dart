import 'package:bdd_widget_test/bdd_widget_test.dart';
import 'package:bdd_widget_test/src/util/fs.dart';
import 'package:bdd_widget_test/src/util/isolate_helper.dart';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:file/memory.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'util/testing_data.dart';

void main() {
  setUp(() {
    resolvePackageUriFactory = (uri) {
      if (uri.path == 'non-existing-file') {
        return Future.value();
      }
      return Future.value(uri);
    };
    fsInstance = MemoryFileSystem.test();
  });

  test('existing step should not regenerate', () async {
    const scenario = 'existing_step';
    final dummyStepPath =
        p.join(getStepFolderName(scenario), 'the_app_is_running.dart');
    const expectedFileContent = '// existing step';
    fs.file(dummyStepPath)
      ..createSync(recursive: true)
      ..writeAsStringSync(expectedFileContent);

    await generate(scenario);

    final content = fs.file(dummyStepPath).readAsStringSync();
    expect(content, expectedFileContent);
  });
}

// ----------------------------------------------------------------------------
const pkgName = 'pkg';

Future<String> generate(String scenario, [BuilderOptions? options]) async {
  const path = 'test/features';

  final srcs = <String, String>{
    '$pkgName|$path/sample.feature': minimalFeatureFile,
  };

  final writer = InMemoryAssetWriter();
  await testBuilder(
    featureBuilder(options ?? BuilderOptions.empty),
    srcs,
    rootPackage: pkgName,
    writer: writer,
  );
  return String.fromCharCodes(
    writer.assets[AssetId(pkgName, 'test/sample/.tracker')] ?? [],
  );
}

String getStepFolderName(String scenario) => p.joinAll([
      fs.currentDirectory.path,
      'test',
      'builder_scenarios',
      scenario,
      'step',
    ]);
