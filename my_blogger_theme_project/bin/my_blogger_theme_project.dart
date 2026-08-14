import 'dart:io';
import 'package:blogger_theme/blogger_theme.dart';
import 'package:my_blogger_theme_project/theme_builder.dart';

void main() {
  print('Building AMP E-Commerce Blogger Theme...');

  final theme = ThemeBuilder.buildTheme();

  var xml = theme.generate();

  // Clean up Blogger widgets.js scripts to preserve AMP compliance
  // (Reference: Replacing the closing </body> with a commented version or textarea)
  xml = xml.replaceFirst(
    '</body>',
    '''&lt;textarea id=&#39;template_widgets_js&#39; disabled=&#39;disabled&#39;
 readonly=&#39;readonly&#39; hidden=&#39;hidden&#39; aria-hidden=&#39;true&#39;
class=&#39;notranslate&#39;&gt;
  </body>
  &lt;/textarea&gt;
  &lt;/body&gt;''',
  );

  print('Theme XML generated successfully.');

  // Validate the generated HTML/XML against standard AMP specifications
  print('Running AmpValidator on generated theme...');
  final errors = AmpValidator.validate(xml);
  if (errors.isEmpty) {
    print('🎉 Perfect! No AMP validation errors found.');
  } else {
    print('⚠️ Found ${errors.length} potential AMP issues/warnings:');
    for (final error in errors) {
      print('  - $error');
    }
  }

  // Ensure output directory exists
  final distDir = Directory('../dist');
  if (!distDir.existsSync()) {
    distDir.createSync(recursive: true);
  }

  final outputFile = File('../dist/amp_theme.xml');
  outputFile.writeAsStringSync(xml);
  print('💾 Saved compiled AMP theme to ${outputFile.path}');
}
