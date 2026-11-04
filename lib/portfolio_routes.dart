import 'dart:math' as math;

enum CubeFace { home, projects, caseStudy, skills, about, contact }

extension FaceData on CubeFace {
  String get label => switch (this) {
    CubeFace.home => 'HOME',
    CubeFace.projects => 'PROJECTS',
    CubeFace.caseStudy => 'EXPERIENCE',
    CubeFace.skills => 'SKILLS',
    CubeFace.about => 'ABOUT',
    CubeFace.contact => 'CONTACT',
  };

  String get path => switch (this) {
    CubeFace.home => '/',
    CubeFace.projects => '/project',
    CubeFace.caseStudy => '/experience',
    CubeFace.skills => '/skills',
    CubeFace.about => '/about',
    CubeFace.contact => '/contact',
  };

  (double, double) get angle => switch (this) {
    CubeFace.home => (0, 0),
    CubeFace.projects => (0, -math.pi / 2),
    CubeFace.caseStudy => (0, math.pi),
    CubeFace.skills => (0, math.pi / 2),
    CubeFace.about => (-math.pi / 2, 0),
    CubeFace.contact => (math.pi / 2, 0),
  };
}

CubeFace faceForUri(Uri uri) {
  final path = uri.fragment.startsWith('/') ? uri.fragment : uri.path;
  return switch (path) {
    '/project' => CubeFace.projects,
    '/work' || '/experience' => CubeFace.caseStudy,
    '/skills' => CubeFace.skills,
    '/about' => CubeFace.about,
    '/contact' => CubeFace.contact,
    _ => CubeFace.home,
  };
}

/// Uses a hash route so direct links and refreshes remain inside a static host's
/// base path (for example `/porfoliodin/` on GitHub Pages).
Uri uriForFace(CubeFace face, Uri baseUri) {
  final basePath = baseUri.path.endsWith('/')
      ? baseUri.path
      : baseUri.path.substring(0, baseUri.path.lastIndexOf('/') + 1);
  return baseUri.replace(path: basePath, query: null, fragment: face.path);
}
