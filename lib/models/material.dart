class Material {
  final String name;
  final int defaultMinTemp;
  final int defaultMaxTemp;
  final int defaultBedMinTemp;
  final int defaultBedMaxTemp;

  const Material(
    this.name,
    this.defaultMinTemp,
    this.defaultMaxTemp,
    this.defaultBedMinTemp,
    this.defaultBedMaxTemp,
  );
}
