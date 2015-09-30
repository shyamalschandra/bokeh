_ = require "underscore"
{expect} = require "chai"
utils = require "../../utils"

base = utils.require "common/base"
Geo = utils.require "renderer/geo/tile_layer"

describe "Projection Utils", ->
  utils = new Geo.ProjectionUtils()
  tol = 0.01

  it "should convert lat/lng to meters", ->
    [x, y] = utils.geographic_to_meters(-90.17578125, 29.840643899834436)
    expect(x).to.be.closeTo(-10038322.050635627, tol)
    expect(y).to.be.closeTo(3483082.504898913, tol)

  it "should convert meters to lat/lng", ->
    [x, y] = utils.meters_to_geographic(-10038322.050635627, 3483082.504898913)
    expect(x).to.be.closeTo(-90.17578125, tol)
    expect(y).to.be.closeTo(29.840643899834436, tol)

  it "should convert geographic extent to meters", ->
    extent = [-67.5, -21.943045533438166, -45, 0]
    bounds = utils.geographic_extent_to_meters(extent)
    expect(bounds[0]).to.be.closeTo(-7514065.628545966, tol)
    expect(bounds[1]).to.be.closeTo(-2504688.542848654, tol)
    expect(bounds[2]).to.be.closeTo(-5009377.085697312, tol)
    expect(bounds[3]).to.be.closeTo(0, tol)

  it "should convert meters extent to geographic", ->
    extent = [-7514065.628545966, -2504688.542848654, -5009377.085697312, 0]
    bounds = utils.meters_extent_to_geographic(extent)
    expect(bounds[0]).to.be.closeTo(-67.5, tol)
    expect(bounds[1]).to.be.closeTo(-21.943045533438166, tol)
    expect(bounds[2]).to.be.closeTo(-45, tol)
    expect(bounds[3]).to.be.closeTo(0, tol)

class TileExpects

  constructor:() ->
    n = 20037508.34
    @MERCATOR_BOUNDS = [n * -1, n * -1, n, n]
    @GEOGRAPHIC_BOUNDS = [-180, -90, 180, 90]

  expect_mercator_tile_counts: (provider) ->
    for zoom_level in [1..5] by 1
      tiles = provider.get_tiles_by_extent(@MERCATOR_BOUNDS, zoom_level, 0)
      expect(tiles.length).to.be.equal(4 ** zoom_level)

  expect_geographic_tile_counts: (provider) ->
    #assumes 512 tile size
    for zoom_level in [0..5] by 1
      tiles = provider.get_tiles_by_extent(@GEOGRAPHIC_BOUNDS, zoom_level, 0)
      expect(tiles.length).to.be.equal(4 ** zoom_level * 2)

describe "Tile Providers", ->

  T = new TileExpects()
  tol = 0.01

  describe "Grid Layer", ->
    url = 'http://c.tiles.mapbox.com/v3/examples.map-szwdot65/{Z}/{X}/{Y}.png'
    provider = new Geo.GridLayer(url, 256)

    it "should remove tile and add back to image pool ", ->
      expect(provider.pool.images.length).to.be.equal(0)
      tile_obj = {img: {}}
      provider.tiles['test'] = tile_obj
      provider.remove_tile('test')
      expect(provider.pool.images.length).to.be.equal(1)

    it "should convert tile xyz into a tile key", ->
      k = provider.tile_xyz_to_key(1,1,1)
      expect(k).to.be.equal "1:1:1"

    it "should convert tile key to tile xyz", ->
      xyz = provider.key_to_tile_xyz('1:1:1')
      expect(xyz).to.be.eql [1,1,1]

    it "should prune tiles", ->

    it "should return tiles in ascending distance from center tile", ->

      tiles = []
      for x in [1..6] by 1
        for y in [1..6] by 1
          tiles.push([x, y])

      tiles = _.shuffle(tiles)
      sorted_tiles = provider.sort_tiles_from_center(tiles, [1, 1, 6, 6])

      for i in [0..3] by 1
        t = sorted_tiles[i]
        expect(t[0]).to.be.within(3, 4)
        expect(t[1]).to.be.within(3, 4)

  describe "TMS tile provider", ->
    url = 'http://c.tiles.mapbox.com/v3/examples.map-szwdot65/{Z}/{X}/{Y}.png'
    provider = new Geo.TMSTileProvider(url)

    it "should get tiles for extent correctly", ->
      T.expect_mercator_tile_counts(provider)

    it "should calculate resolution", ->
      expect(provider.get_resolution(1)).to.be.closeTo(78271.517, tol)
      expect(provider.get_resolution(12)).to.be.closeTo(38.2185, tol)

  describe "WMTS tile provider", ->
    url = 'http://mt0.google.com/vt/lyrs=m@169000000&hl=en&x={X}&y={Y}&z={Z}&s=Ga'
    provider = new Geo.WMTSTileProvider(url)

    it "should get tiles for extent correctly", ->
      T.expect_mercator_tile_counts(provider)

    it "should get tile bounds in meters", ->
      [x, y, z] = provider.wmts_to_tms(511, 845, 11)
      bounds = provider.get_tile_meter_bounds(x, y, z)
      expect(bounds[0]).to.be.closeTo(-10038322.050635627, tol)
      expect(bounds[1]).to.be.closeTo(3483082.504898913, tol)
      expect(bounds[2]).to.be.closeTo(-10018754.171394622, tol)
      expect(bounds[3]).to.be.closeTo(3502650.384139918, tol)

    it "should get tile bounds in lat/lng", ->
      [x, y, z] = provider.wmts_to_tms(511, 845, 11)
      bounds = provider.get_tile_geographic_bounds(x, y, z)
      expect(bounds[0]).to.be.closeTo(-90.17578125, tol)
      expect(bounds[1]).to.be.closeTo(29.840643899834436, tol)
      expect(bounds[2]).to.be.closeTo(-90, tol)
      expect(bounds[3]).to.be.closeTo(29.99300228455108, tol)

  describe "QUADKEY tile provider", ->
    url = 'http://t0.tiles.virtualearth.net/tiles/a{Q}.jpeg?g=854&mkt=en-US&token=Anz84uRE1RULeLwuJ0qKu5amcu5rugRXy1vKc27wUaKVyIv1SVZrUjqaOfXJJoI0'
    provider = new Geo.QUADKEYTileProvider(url)

    it "should get tiles for extent correctly", ->
      T.expect_mercator_tile_counts(provider)

    it "should convert tile xyz to quadkey", ->
      expect(provider.tile_xyz_to_quadkey(0, 0, 0)).to.be.equal('')
      expect(provider.tile_xyz_to_quadkey(0, 0, 1)).to.be.equal('0')
      expect(provider.tile_xyz_to_quadkey(0, 0, 2)).to.be.equal('00')
      expect(provider.tile_xyz_to_quadkey(20, 30, 10)).to.be.equal('0000032320')

    it "should convert quadkey to tile xyz", ->
      expect(provider.quadkey_to_tile_xyz('')).to.be.eql [0, 0, 0]
      expect(provider.quadkey_to_tile_xyz('0')).to.be.eql [0, 0, 1]
      expect(provider.quadkey_to_tile_xyz('00')).to.be.eql [0, 0, 2]
      expect(provider.quadkey_to_tile_xyz('0000032320')).to.be.eql [20, 30, 10]

  describe "MERCATOR tile provider", ->

    provider = new Geo.MercatorTileProvider()
    tol = 0.01

    it "should calculate resolution", ->
      expect(provider.get_resolution(1)).to.be.closeTo(78271.517, tol)
      expect(provider.get_resolution(12)).to.be.closeTo(38.2185, tol)

    it "should convert tile x,y,z into cache key", ->
      expect(provider.tile_xyz_to_key(1, 1, 1)).to.be.equal "1:1:1"

    it "should convert cache key into tile x,y,z", ->
      expect(provider.key_to_tile_xyz("1:1:1")).to.be.eql [1,1,1]

    it "should get best zoom level based on extent and height/width", ->
      expect(provider.get_level_by_extent(T.MERCATOR_BOUNDS, 256, 256)).to.be.equal 0
      expect(provider.get_level_by_extent(T.MERCATOR_BOUNDS, 512, 512)).to.be.equal 1
      expect(provider.get_level_by_extent(T.MERCATOR_BOUNDS, 1024, 1024)).to.be.equal 2

    it "should convert pixel x/y to tile x/y", ->
      expect(provider.pixels_to_tile(1, 1)).to.be.eql [0,0]
      expect(provider.pixels_to_tile(0, 0)).to.be.eql [0,0]

    it "should convert pixel x/y to meters x/y", ->
      expect(provider.pixels_to_meters(0, 0, 0)).to.be.eql [-20037508.342789244, -20037508.342789244]

    it "should get tile bounds in meters", ->
      bounds = provider.get_tile_meter_bounds(511, 1202, 11)
      expect(bounds[0]).to.be.closeTo(-10038322.050635627, tol)
      expect(bounds[1]).to.be.closeTo(3483082.504898913, tol)
      expect(bounds[2]).to.be.closeTo(-10018754.171394622, tol)
      expect(bounds[3]).to.be.closeTo(3502650.384139918, tol)

    it "should get tile bounds in lat/lng", ->
      bounds = provider.get_tile_geographic_bounds(511, 1202, 11)
      expect(bounds[0]).to.be.closeTo(-90.17578125, tol)
      expect(bounds[1]).to.be.closeTo(29.840643899834436, tol)
      expect(bounds[2]).to.be.closeTo(-90, tol)
      expect(bounds[3]).to.be.closeTo(29.99300228455108, tol)

    it "should get tile urls by geographic extent", ->
      service = 'http://c.tile.openstreetmap.org/{Z}/{X}/{Y}.png'
      provider = new Geo.TMSTileProvider(service)

      [xmin, ymin, xmax, ymax, level] = [-90.283741, 29.890626, -89.912952,
                                          30.057766, 11]
      expected_tiles = []
      expected_tiles.push('http://c.tile.openstreetmap.org/11/510/1201.png')
      expected_tiles.push('http://c.tile.openstreetmap.org/11/511/1201.png')
      expected_tiles.push('http://c.tile.openstreetmap.org/11/512/1201.png')
      expected_tiles.push('http://c.tile.openstreetmap.org/11/510/1202.png')
      expected_tiles.push('http://c.tile.openstreetmap.org/11/511/1202.png')
      expected_tiles.push('http://c.tile.openstreetmap.org/11/512/1202.png')

      urls = provider.get_tiles_by_extent(xmin, ymin, xmax, ymax, level)
      for url in expected_tiles
        expect(expected_tiles.indexOf(url)).to.be.above -1