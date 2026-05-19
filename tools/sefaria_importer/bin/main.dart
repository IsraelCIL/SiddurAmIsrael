import 'dart:io';

import 'package:args/args.dart';
import 'package:http/http.dart' as http;
import 'package:sefaria_importer/sefaria_service.dart';
import 'package:sefaria_importer/segment_builder.dart';
import 'package:sefaria_importer/text_processor.dart';

Future<void> main(List<String> args) async {
  final parser = ArgParser()
    ..addOption(
      'output-dir',
      abbr: 'o',
      // Default: resolve relative to this script's location
      defaultsTo: '../../../assets/prayers',
      help: 'Path to assets/prayers/ directory (absolute or relative to CWD).',
    )
    ..addFlag(
      'dry-run',
      abbr: 'n',
      defaultsTo: false,
      negatable: false,
      help: 'Print what would be written without creating any files.',
    )
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Show this help.');

  ArgResults results;
  try {
    results = parser.parse(args);
  } on FormatException catch (e) {
    stderr.writeln('Error: ${e.message}\n');
    _printUsage(parser);
    exit(1);
  }

  if (results['help'] as bool) {
    _printUsage(parser);
    exit(0);
  }

  final outputDir = results['output-dir'] as String;
  final dryRun = results['dry-run'] as bool;

  // Resolve output dir relative to CWD when not absolute.
  final resolvedOutput = Directory(outputDir).absolute.path;

  stdout.writeln('Smart Siddur — Sefaria Importer');
  stdout.writeln('  Output dir : $resolvedOutput');
  stdout.writeln('  Dry run    : $dryRun');
  stdout.writeln('');

  if (!dryRun) {
    final dir = Directory(resolvedOutput);
    if (!await dir.exists()) {
      stderr.writeln(
        '[ERROR] Output directory does not exist: $resolvedOutput\n'
        '        Run from the project root or pass --output-dir explicitly.',
      );
      exit(1);
    }
  }

  final client = http.Client();
  try {
    final processor = TextProcessor();
    final service = SefariaService(client, processor: processor);
    final builder = SegmentBuilder(service, processor);

    await builder.buildMincha(resolvedOutput, dryRun: dryRun);
  } catch (e, st) {
    stderr.writeln('[FATAL] Unexpected error: $e\n$st');
    exit(2);
  } finally {
    client.close();
  }
}

void _printUsage(ArgParser parser) {
  stdout.writeln('Usage: dart run bin/main.dart [options]\n');
  stdout.writeln(parser.usage);
  stdout.writeln('');
  stdout.writeln('Examples:');
  stdout.writeln('  dart run bin/main.dart --dry-run');
  stdout.writeln('  dart run bin/main.dart -o /path/to/assets/prayers');
}
