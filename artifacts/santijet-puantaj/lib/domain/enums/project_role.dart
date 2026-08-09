enum ProjectRole {
  owner,
  editor,
  viewer;

  String get label => switch (this) {
        ProjectRole.owner => 'Sahip',
        ProjectRole.editor => 'Düzenleyici',
        ProjectRole.viewer => 'Görüntüleyici',
      };

  bool get canEditByDefault => switch (this) {
        ProjectRole.owner => true,
        ProjectRole.editor => true,
        ProjectRole.viewer => false,
      };
}
