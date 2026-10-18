import 'package:material_ui/material_ui.dart';

/// The same printed sample documents used in the public landing film.
class MatchPreview extends StatelessWidget {
  const MatchPreview({super.key});

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox(
      height: 205,
      width: double.infinity,
      child: Image.asset('assets/brand/search-documents.webp', fit: BoxFit.contain),
    ),
  );
}
