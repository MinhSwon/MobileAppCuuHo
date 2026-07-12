const mapTileUrl = String.fromEnvironment(
  'MAP_TILE_URL',
  defaultValue: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
);

const mapUserAgent = String.fromEnvironment(
  'MAP_USER_AGENT',
  defaultValue: 'vn.rescuevn.mobile',
);
