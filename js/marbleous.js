(function() {
  /* @const */  var Block, Compressor, DEBUG, Game, Map, OVERLAY, Palette, Renderer;
  var __indexOf = Array.prototype.indexOf || function(item) {
    for (var i = 0, l = this.length; i < l; i++) {
      if (this[i] === item) return i;
    }
    return -1;
  }, __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  DEBUG = false;
  OVERLAY = false;
  Block = (function() {
    Block.canStack = function(bottom, top) {
      var midRotation, midType, topRotation, topType, _ref, _ref2;
      _ref = top.getProperty('middle'), midType = _ref[0], midRotation = _ref[1];
      _ref2 = bottom.getProperty('top'), topType = _ref2[0], topRotation = _ref2[1];
      if (topType) {
        if (midType === 'drop-low') {
          return false;
        }
        if (midType === 'dive' || midType === 'exchange' || midType === 'exchange-alt') {
          return false;
        }
      }
      return true;
    };
    Block.ofType = function(type, rotation) {
      if (rotation == null) {
        rotation = 0;
      }
      if (!Block.Types[type]) {
        throw new Error("Unknown type " + type);
      }
      return new Block(Block.Types[type], rotation);
    };
    function Block(description) {
      var key, value, _ref;
      this.properties = {
        'top': [null, 0],
        'middle': [null, 0],
        'low': [null, 0]
      };
      _ref = this.properties;
      for (key in _ref) {
        value = _ref[key];
        this.properties[key] = description[key] || value;
      }
      this.validate();
    }
    Block.prototype.validate = function(properties) {
      var level, lowRotation, lowType, midRotation, midType, rotation, topRotation, topType, type, _ref, _ref2, _ref3, _ref4, _ref5;
      if (properties == null) {
        properties = this.properties;
      }
      _ref = this.properties;
      for (level in _ref) {
        _ref2 = _ref[level], type = _ref2[0], rotation = _ref2[1];
        if (type && !(__indexOf.call(Block.Components[level], type) >= 0)) {
          throw new Error("Unknown " + level + " type " + type);
        }
        if (rotation !== 0 && rotation !== 90 && rotation !== 180 && rotation !== 270) {
          throw new Error("Rotation must be multiple of 90, was " + type);
        }
      }
      _ref3 = this.getProperty('top'), topType = _ref3[0], topRotation = _ref3[1];
      _ref4 = this.getProperty('middle'), midType = _ref4[0], midRotation = _ref4[1];
      _ref5 = this.getProperty('low'), lowType = _ref5[0], lowRotation = _ref5[1];
      if (topType === 'crossing-hole' && midType !== 'drop-middle' && midType !== 'drop-low') {
        throw new Error("Top type crossing with hole requires middle type drop, was " + midType);
      }
      if (topType !== 'crossing-hole' && (midType === 'drop-middle' || midType === 'drop-low')) {
        throw new Error("Middle type drop requires top type crossing with hole, was " + topType);
      }
      if (lowType && midType === 'drop-low') {
        throw new Error("Middle type " + midType + " is incompatible with low type " + lowType);
      }
    };
    Block.prototype.setOpacity = function(opacity) {
      if (!((0 <= opacity && opacity <= 1.0))) {
        throw new Error("Illegal value for opacity");
      }
      return this.opacity = opacity;
    };
    Block.prototype.setSelected = function(selected) {
      this.selected = selected;
    };
    Block.prototype.setDragged = function(dragged) {
      this.dragged = dragged;
    };
    Block.prototype.getProperty = function(property) {
      if (property !== 'top' && property !== 'middle' && property !== 'low') {
        throw new Error("Unknown property " + property);
      }
      return this.properties[property];
    };
    Block.prototype.setProperty = function(property, type, rotation) {
      var newProperties, oldRotation, oldType, _ref;
      _ref = this.getProperty(property), oldType = _ref[0], oldRotation = _ref[1];
      newProperties = {};
      if (rotation === null) {
        rotation = oldRotation;
      }
      newProperties[property] = [type, rotation];
      return this.setProperties(newProperties);
    };
    Block.prototype.setProperties = function(properties) {
      var key, newProperties, value, _ref, _ref2, _results;
      newProperties = {};
      _ref = this.properties;
      for (key in _ref) {
        value = _ref[key];
        newProperties[key] = properties[key] || value;
      }
      this.validate(newProperties);
      _ref2 = this.properties;
      _results = [];
      for (key in _ref2) {
        value = _ref2[key];
        _results.push(this.properties[key] = properties[key] || value);
      }
      return _results;
    };
    Block.prototype.rotateCW = function() {
      return this.rotate(true);
    };
    Block.prototype.rotateCCW = function() {
      return this.rotate(false);
    };
    Block.prototype.rotate = function(clockwise, top, middle, low) {
      var lowRotation, lowType, midRotation, midType, topRotation, topType, _ref, _ref2, _ref3;
      if (top == null) {
        top = true;
      }
      if (middle == null) {
        middle = true;
      }
      if (low == null) {
        low = true;
      }
      _ref = this.properties['top'], topType = _ref[0], topRotation = _ref[1];
      _ref2 = this.properties['middle'], midType = _ref2[0], midRotation = _ref2[1];
      _ref3 = this.properties['low'], lowType = _ref3[0], lowRotation = _ref3[1];
      if (clockwise) {
        return this.setProperties({
          'top': top ? [topType, (topRotation + 90) % 360] : void 0,
          'middle': middle ? [midType, (midRotation + 90) % 360] : void 0,
          'low': low ? [lowType, (lowRotation + 90) % 360] : void 0
        });
      } else {
        return this.setProperties({
          'top': top ? [topType, (topRotation + 270) % 360] : void 0,
          'middle': middle ? [midType, (midRotation + 270) % 360] : void 0,
          'low': low ? [lowType, (lowRotation + 270) % 360] : void 0
        });
      }
    };
    Block.prototype.toString = function() {
      var lowRotation, lowType, midRotation, midType, topRotation, topType, _ref, _ref2, _ref3;
      _ref = this.properties['top'], topType = _ref[0], topRotation = _ref[1];
      _ref2 = this.properties['middle'], midType = _ref2[0], midRotation = _ref2[1];
      _ref3 = this.properties['low'], lowType = _ref3[0], lowRotation = _ref3[1];
      return ("" + topType + topRotation) + ("" + midType + midRotation) + ("" + lowType + lowRotation) + ("" + this.opacity + this.selected);
    };
    Block.Components = {
      'top': ['crossing', 'crossing-hole', 'curve', 'straight'],
      'middle': ['crossing', 'curve', 'straight', 'dive', 'drop-middle', 'drop-low', 'exchange-alt', 'exchange'],
      'low': ['crossing', 'curve', 'straight']
    };
    Block.Types = {
      'blank': {},
      'double-straight': {
        'top': ['straight', 0],
        'middle': ['straight', 0]
      },
      'curve-straight': {
        'top': ['curve', 270],
        'middle': ['straight', 0]
      },
      'curve-straight-alt': {
        'top': ['curve', 180],
        'middle': ['straight', 0]
      },
      'double-curve': {
        'top': ['curve', 270],
        'middle': ['curve', 0]
      },
      'double-curve-alt': {
        'top': ['curve', 90],
        'middle': ['curve', 0]
      },
      'curve-exchange': {
        'top': ['curve', 270],
        'middle': ['exchange', 0]
      },
      'curve-exchange-alt': {
        'top': ['curve', 180],
        'middle': ['exchange-alt', 0]
      },
      'straight-exchange': {
        'top': ['straight', 0],
        'middle': ['exchange', 0]
      },
      'straight-exchange-alt': {
        'top': ['straight', 0],
        'middle': ['exchange-alt', 0]
      },
      'curve-dive': {
        'top': ['curve', 270],
        'middle': ['dive', 0]
      },
      'curve-dive-alt': {
        'top': ['curve', 0],
        'middle': ['dive', 0]
      },
      'crossing-straight': {
        'top': ['crossing', 270],
        'middle': ['straight', 0]
      },
      'crossing-hole': {
        'top': ['crossing-hole', 270],
        'middle': ['drop-middle', 0]
      },
      'crossing-hole-alt': {
        'top': ['crossing-hole', 270],
        'middle': ['drop-low', 0]
      }
    };
    return Block;
  })();
  Map = (function() {
    function Map(size) {
      var x, _ref;
      if (!((1 < size && size < 255))) {
        throw new Error("Size must be between 1 and 255");
      }
      /* @constant */
      this.size = size;
      /* @constant */
      this.grid = new Array(Math.pow(this.size, 3));
      for (x = 0, _ref = Math.pow(this.size, 3); (0 <= _ref ? x < _ref : x > _ref); (0 <= _ref ? x += 1 : x -= 1)) {
        this.grid[x] = null;
      }
      this.rotation = 0;
      this.setNeedsRedraw(true);
    }
    Map.prototype.setBlock = function(block, x, y, z) {
      var _ref;
      this.validateCoordinates(x, y, z);
      if (this.rotation) {
        _ref = this.applyRotation(x, y), x = _ref[0], y = _ref[1];
      }
      this.grid[x + y * this.size + z * this.size * this.size] = block;
      return this.setNeedsRedraw(true);
    };
    Map.prototype.getBlock = function(x, y, z) {
      var _ref;
      this.validateCoordinates(x, y, z);
      if (this.rotation) {
        _ref = this.applyRotation(x, y), x = _ref[0], y = _ref[1];
      }
      return this.grid[x + y * this.size + z * this.size * this.size];
    };
    Map.prototype.removeBlock = function(x, y, z) {
      var block;
      block = this.getBlock(x, y, z);
      this.setBlock(null, x, y, z);
      return block;
    };
    Map.prototype.heightAt = function(x, y) {
      var height;
      this.validateCoordinates(x, y, 0);
      height = 0;
      while (height < this.size && this.getBlock(x, y, height)) {
        height++;
      }
      return height;
    };
    Map.prototype.getStack = function(x, y, z) {
      var blocks, currentZ, height;
      if (z == null) {
        z = 0;
      }
      this.validateCoordinates(x, y, z);
      if (z > (height = this.heightAt(x, y))) {
        return [];
      }
      blocks = new Array;
      for (currentZ = z; (z <= height ? currentZ < height : currentZ > height); (z <= height ? currentZ += 1 : currentZ -= 1)) {
        blocks.push(this.getBlock(x, y, currentZ));
      }
      return blocks;
    };
    Map.prototype.setStack = function(blocks, x, y, z) {
      var block, _i, _len, _results;
      if (z == null) {
        z = 0;
      }
      this.validateCoordinates(x, y, z);
      if (!(blocks.length - 1 + z < this.size)) {
        throw new Error("Cannot place stack, height out of bounds");
      }
      _results = [];
      for (_i = 0, _len = blocks.length; _i < _len; _i++) {
        block = blocks[_i];
        _results.push(this.setBlock(block, x, y, z++));
      }
      return _results;
    };
    Map.prototype.removeStack = function(x, y, z) {
      var currentZ, stack, _ref;
      if (z == null) {
        z = 0;
      }
      stack = this.getStack(x, y, z);
      for (currentZ = z, _ref = z + stack.length; (z <= _ref ? currentZ < _ref : currentZ > _ref); (z <= _ref ? currentZ += 1 : currentZ -= 1)) {
        this.setBlock(null, x, y, currentZ);
      }
      return stack;
    };
    Map.prototype.validate = function() {
      return this.blocksEach(__bind(function(block, x, y, z) {
        if (block && z > 0 && !this.getBlock(x, y, z - 1)) {
          throw new Error("Encountered floating block at " + x + ":" + y + ":" + z);
        }
      }, this));
    };
    Map.prototype.validateCoordinates = function(x, y, z) {
      if (!((0 <= x && x < this.size) && (0 <= y && y < this.size) && (0 <= z && z < this.size))) {
        throw new Error("Index out of bounds " + x + ":" + y + ":" + z);
      }
    };
    Map.prototype.applyRotation = function(x, y) {
      switch (this.rotation) {
        case 90:
          return [this.size - 1 - y, x];
        case 180:
          return [this.size - 1 - x, this.size - 1 - y];
        case 270:
          return [y, this.size - 1 - x];
        default:
          return [x, y];
      }
    };
    Map.prototype.setNeedsRedraw = function(needsRedraw) {
      this.needsRedraw = needsRedraw;
    };
    Map.prototype.blocksEach = function(functionToApply) {
      var x, y, z, _results;
      x = this.size - 1;
      _results = [];
      while (x + 1) {
        y = 0;
        while (y < this.size) {
          z = 0;
          while (z < this.size) {
            functionToApply(this.getBlock(x, y, z), x, y, z);
            z++;
          }
          y++;
        }
        _results.push(x--);
      }
      return _results;
    };
    Map.prototype.rotateCW = function() {
      return this.rotate(true);
    };
    Map.prototype.rotateCCW = function() {
      return this.rotate(false);
    };
    Map.prototype.rotate = function(clockwise) {
      var block, _i, _len, _ref;
      if (clockwise) {
        this.rotation = (this.rotation + 90) % 360;
      } else {
        this.rotation = (this.rotation + 270) % 360;
      }
      _ref = this.grid;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        block = _ref[_i];
        if (block) {
          block.rotate(clockwise);
        }
      }
      return this.setNeedsRedraw(true);
    };
    return Map;
  })();
  Renderer = (function() {
    Renderer.defaultSettings = {
      mainCanvasID: '#main-canvas',
      draggedCanvasID: '#dragged-canvas',
      blockSize: 101,
      blockSizeHalf: Math.floor(101 / 2),
      blockSizeQuarter: Math.floor(Math.floor(101 / 2) / 2),
      canvasHeight: 7 * 101,
      canvasWidth: 7 * 101,
      textureFile: '/img/textures.png',
      textureBlockSize: 101
    };
    function Renderer(map, onload, settings) {
      var key, onloadCallback, textureFile, value, _ref;
      this.map = map;
      this.onload = onload;
      this.settings = settings != null ? settings : {};
      _ref = Renderer.defaultSettings;
      for (key in _ref) {
        value = _ref[key];
        this.settings[key] = this.settings[key] || Renderer.defaultSettings[key];
      }
      this.canvas = $(this.settings.mainCanvasID);
      this.canvas.attr('width', this.settings.canvasWidth);
      this.canvas.attr('height', this.settings.canvasHeight);
      this.context = this.canvas.get(0).getContext('2d');
      this.hittestCanvas = document.createElement('canvas');
      this.hittestCanvas.width = this.settings.canvasWidth;
      this.hittestCanvas.height = this.settings.canvasHeight;
      this.hittestContext = this.hittestCanvas.getContext('2d');
      this.draggedCanvas = $(this.settings.draggedCanvasID);
      this.draggedContext = this.draggedCanvas.get(0).getContext('2d');
      this.textures = {};
      this.Cache = {};
      onloadCallback = __bind(function() {
        this.setupTextures(textureFile);
        return this.onload();
      }, this);
      textureFile = new Image;
      textureFile.onload = onloadCallback;
      textureFile.src = this.settings.textureFile;
    }
    Renderer.prototype.setupTextures = function(textureFile) {
      var canvas, context, rotation, rotationsCount, texture, textureBSize, textureDescription, textureGroup, textureOffset, _ref, _results;
      textureOffset = 0;
      _ref = Renderer.TextureFileDescription;
      _results = [];
      for (textureGroup in _ref) {
        textureDescription = _ref[textureGroup];
        _results.push((function() {
          var _base, _ref, _results;
          _results = [];
          for (texture in textureDescription) {
            rotationsCount = textureDescription[texture];
            if (DEBUG) {
              console.log("loading " + textureGroup + "." + texture);
            }
            (_ref = (_base = this.textures)[textureGroup]) != null ? _ref : _base[textureGroup] = {};
            this.textures[textureGroup][texture] = new Array(rotationsCount);
            for (rotation = 0; (0 <= rotationsCount ? rotation < rotationsCount : rotation > rotationsCount); (0 <= rotationsCount ? rotation += 1 : rotation -= 1)) {
              canvas = document.createElement('canvas');
              canvas.width = this.settings.blockSize;
              canvas.height = this.settings.blockSize;
              context = canvas.getContext('2d');
              try {
                textureBSize = this.settings.textureBlockSize;
                context.drawImage(textureFile, rotation * textureBSize, textureOffset * textureBSize, textureBSize, textureBSize, 0, 0, this.settings.blockSize, this.settings.blockSize);
              } catch (error) {
                if (DEBUG) {
                  console.log("Encountered error " + error + " while loading texture: " + texture);
                  if (error.name === "INDEX_SIZE_ERR") {
                    console.log("Texture file may be too small");
                  }
                }
                break;
              }
              this.textures[textureGroup][texture][rotation] = canvas;
            }
            _results.push(textureOffset++);
          }
          return _results;
        }).call(this));
      }
      return _results;
    };
    Renderer.prototype.renderingCoordinatesForBlock = function(x, y, z) {
      var screenX, screenY;
      screenX = (x + y) * this.settings.blockSizeHalf;
      screenY = this.settings.canvasHeight - 3 * this.settings.blockSizeQuarter - (2 * z + x - y + this.map.size) * this.settings.blockSizeQuarter;
      return [screenX, screenY];
    };
    Renderer.prototype.sideAtScreenCoordinates = function(x, y) {
      var pixel;
      pixel = this.hittestContext.getImageData(x, y, 1, 1);
      if (pixel.data[0] > 0) {
        return 'south';
      } else if (pixel.data[1] > 0) {
        return 'east';
      } else if (pixel.data[2] > 0) {
        return 'top';
      } else if (pixel.data[3] > 0) {
        return 'floor';
      } else {
        return null;
      }
    };
    Renderer.prototype.resolveScreenCoordinates = function(x, y) {
      var blockX, blockY, blockZ, currentBlock, pixel, screenX, screenY, side, _ref, _ref2, _ref3, _ref4, _ref5, _ref6, _ref7, _results, _results2;
      if (!((0 < x && x < this.settings.canvasWidth) && (0 < y && y < this.settings.canvasHeight))) {
        return {};
      }
      side = this.sideAtScreenCoordinates(x, y);
      if (side === 'floor') {
        _results = [];
        for (blockX = 0, _ref = this.map.size; (0 <= _ref ? blockX < _ref : blockX > _ref); (0 <= _ref ? blockX += 1 : blockX -= 1)) {
          for (blockY = _ref2 = this.map.size - 1; (_ref2 <= 0 ? blockY <= 0 : blockY >= 0); (_ref2 <= 0 ? blockY += 1 : blockY -= 1)) {
            _ref3 = this.renderingCoordinatesForBlock(blockX, blockY, 0), screenX = _ref3[0], screenY = _ref3[1];
            if (!((screenX <= x && x < (screenX + this.settings.blockSize)) && (screenY <= y && y < (screenY + this.settings.blockSize)))) {
              continue;
            }
            pixel = this.getTexture('basic', 'floor-hitbox').getContext('2d').getImageData(x - screenX, y - screenY, 1, 1);
            if (pixel.data[3] > 0) {
              return {
                coordinates: [blockX, blockY, 0],
                side: 'floor'
              };
            }
          }
        }
        return _results;
      } else if (side) {
        _results2 = [];
        for (blockX = 0, _ref4 = this.map.size; (0 <= _ref4 ? blockX < _ref4 : blockX > _ref4); (0 <= _ref4 ? blockX += 1 : blockX -= 1)) {
          for (blockY = _ref5 = this.map.size - 1; (_ref5 <= 0 ? blockY <= 0 : blockY >= 0); (_ref5 <= 0 ? blockY += 1 : blockY -= 1)) {
            for (blockZ = _ref6 = this.map.size - 1; (_ref6 <= 0 ? blockZ <= 0 : blockZ >= 0); (_ref6 <= 0 ? blockZ += 1 : blockZ -= 1)) {
              currentBlock = this.map.getBlock(blockX, blockY, blockZ);
              if (!currentBlock || currentBlock.dragged) {
                continue;
              }
              _ref7 = this.renderingCoordinatesForBlock(blockX, blockY, blockZ), screenX = _ref7[0], screenY = _ref7[1];
              if (!((screenX <= x && x < (screenX + this.settings.blockSize)) && (screenY <= y && y < (screenY + this.settings.blockSize)))) {
                continue;
              }
              pixel = this.getTexture('basic', 'hitbox').getContext('2d').getImageData(x - screenX, y - screenY, 1, 1);
              if (pixel.data[3] > 0) {
                return {
                  block: currentBlock,
                  coordinates: [blockX, blockY, blockZ],
                  side: side
                };
              }
            }
          }
        }
        return _results2;
      } else {
        return {};
      }
    };
    Renderer.prototype.getTexture = function(group, type, rotation) {
      var rotationCount;
      if (!rotation) {
        if (Renderer.TextureFileDescription[group][type] != null) {
          return this.textures[group][type][0];
        }
      }
      rotationCount = Renderer.TextureFileDescription[group][type];
      if (rotationCount == null) {
        return null;
      }
      return this.textures[group][type][rotation / 90 % rotationCount];
    };
    Renderer.prototype.drawMap = function(force) {
      if (force == null) {
        force = false;
      }
      if ((this.isDrawing || !this.map.needsRedraw) && !force) {
        return;
      }
      if (DEBUG) {
        console.time("draw");
      }
      this.isDrawing = true;
      this.context.clearRect(0, 0, this.settings.canvasWidth, this.settings.canvasHeight);
      this.hittestContext.clearRect(0, 0, this.settings.canvasWidth, this.settings.canvasHeight);
      this.drawFloor();
      this.map.blocksEach(__bind(function(block, x, y, z) {
        var screenX, screenY, _ref;
        if (!block) {
          return;
        }
        _ref = this.renderingCoordinatesForBlock(x, y, z), screenX = _ref[0], screenY = _ref[1];
        return this.drawBlock(this.context, block, screenX, screenY);
      }, this));
      this.drawHitmap();
      if (OVERLAY) {
        this.context.globalAlpha = 0.4;
        this.context.drawImage(this.hittestCanvas, 0, 0, this.settings.canvasWidth, this.settings.canvasHeight);
        this.context.globalAlpha = 1.0;
      }
      this.map.setNeedsRedraw(false);
      this.isDrawing = false;
      if (DEBUG) {
        return console.timeEnd("draw");
      }
    };
    Renderer.prototype.drawHitmap = function() {
      return this.map.blocksEach(__bind(function(block, x, y, z) {
        var screenX, screenY, _ref, _ref2;
        if (z === 0) {
          _ref = this.renderingCoordinatesForBlock(x, y, 0), screenX = _ref[0], screenY = _ref[1];
          this.hittestContext.drawImage(this.getTexture('basic', 'floor-hitbox'), screenX, screenY, this.settings.blockSize, this.settings.blockSize);
        }
        if (block && !block.dragged) {
          _ref2 = this.renderingCoordinatesForBlock(x, y, z), screenX = _ref2[0], screenY = _ref2[1];
          return this.hittestContext.drawImage(this.getTexture('basic', 'hitbox'), screenX, screenY, this.settings.blockSize, this.settings.blockSize);
        }
      }, this));
    };
    Renderer.prototype.drawFloor = function() {
      var screenX, screenY, x, y, _ref, _results;
      _results = [];
      for (x = 0, _ref = this.map.size; (0 <= _ref ? x < _ref : x > _ref); (0 <= _ref ? x += 1 : x -= 1)) {
        _results.push((function() {
          var _ref, _ref2, _results;
          _results = [];
          for (y = 0, _ref = this.map.size; (0 <= _ref ? y < _ref : y > _ref); (0 <= _ref ? y += 1 : y -= 1)) {
            _ref2 = this.renderingCoordinatesForBlock(x, y, 0), screenX = _ref2[0], screenY = _ref2[1];
            _results.push(this.context.drawImage(this.getTexture('basic', 'floor'), screenX, screenY, this.settings.blockSize, this.settings.blockSize));
          }
          return _results;
        }).call(this));
      }
      return _results;
    };
    Renderer.prototype.drawBlock = function(context, block, x, y) {
      var backside, bottomHoleEast, bottomHoleSouth, bottomHoles, buffer, cache_key, cached, cutouts, lowHoleEast, lowHoleSouth, lowHoles, lowRotation, lowType, low_texture, midHoleEast, midHoleSouth, midHoles, midRotation, midType, mid_texture, pos, solid, topRotation, topType, top_texture, type, _i, _j, _k, _len, _len2, _len3, _ref, _ref2, _ref3;
      if (x == null) {
        x = 0;
      }
      if (y == null) {
        y = 0;
      }
      cache_key = block.toString();
      if (!(cached = this.Cache[cache_key])) {
        _ref = block.getProperty('top'), topType = _ref[0], topRotation = _ref[1];
        _ref2 = block.getProperty('middle'), midType = _ref2[0], midRotation = _ref2[1];
        _ref3 = block.getProperty('low'), lowType = _ref3[0], lowRotation = _ref3[1];
        this.Cache[cache_key] = cached = document.createElement('canvas');
        cached.height = cached.width = this.settings.blockSize;
        buffer = cached.getContext("2d");
        if (block.selected || block.opacity !== 1.0) {
          backside = this.getTexture('basic', 'backside');
          buffer.drawImage(backside, 0, 0, this.settings.blockSize, this.settings.blockSize);
          if (lowType) {
            low_texture = this.getTexture('low', lowType, lowRotation);
            if (low_texture != null) {
              buffer.drawImage(low_texture, 0, 0, this.settings.blockSize, this.settings.blockSize);
            }
          }
          if (midType) {
            mid_texture = this.getTexture('middle', midType, midRotation);
            if (mid_texture != null) {
              buffer.drawImage(mid_texture, 0, 0, this.settings.blockSize, this.settings.blockSize);
            }
          }
        }
        if (block.selected) {
          buffer.globalAlpha = 0.3;
        } else {
          buffer.globalAlpha = block.opacity || 1.0;
        }
        solid = this.getTexture('basic', 'solid');
        buffer.drawImage(solid, 0, 0, this.settings.blockSize, this.settings.blockSize);
        buffer.globalAlpha = 1.0;
        if (topType) {
          top_texture = this.getTexture('top', topType, topRotation);
          if (top_texture != null) {
            if (block.selected) {
              buffer.globalAlpha = 0.6;
            }
            buffer.drawImage(top_texture, 0, 0, this.settings.blockSize, this.settings.blockSize);
            buffer.globalAlpha = 1.0;
          }
        }
        midHoles = Renderer.MidHoles[midType];
        if (midHoles) {
          for (_i = 0, _len = midHoles.length; _i < _len; _i++) {
            pos = midHoles[_i];
            if ((pos + midRotation) % 360 === 0) {
              midHoleSouth = this.getTexture('basic', 'hole-middle', 0);
              buffer.drawImage(midHoleSouth, 0, 0, this.settings.blockSize, this.settings.blockSize);
            }
            if ((pos + midRotation) % 360 === 90) {
              midHoleEast = this.getTexture('basic', 'hole-middle', 90);
              buffer.drawImage(midHoleEast, 0, 0, this.settings.blockSize, this.settings.blockSize);
            }
          }
        }
        lowHoles = Renderer.LowHoles[midType];
        if (lowHoles) {
          for (_j = 0, _len2 = lowHoles.length; _j < _len2; _j++) {
            pos = lowHoles[_j];
            if ((pos + midRotation) % 360 === 0) {
              lowHoleSouth = this.getTexture('basic', 'hole-low', 0);
              buffer.drawImage(lowHoleSouth, 0, 0, this.settings.blockSize, this.settings.blockSize);
            }
            if ((pos + midRotation) % 360 === 90) {
              lowHoleEast = this.getTexture('basic', 'hole-low', 90);
              buffer.drawImage(lowHoleEast, 0, 0, this.settings.blockSize, this.settings.blockSize);
            }
          }
        }
        bottomHoles = Renderer.BottomHoles[lowType];
        if (bottomHoles) {
          for (_k = 0, _len3 = bottomHoles.length; _k < _len3; _k++) {
            pos = bottomHoles[_k];
            if ((pos + lowRotation) % 360 === 0) {
              bottomHoleSouth = this.getTexture('basic', 'hole-bottom', 0);
              buffer.drawImage(bottomHoleSouth, 0, 0, this.settings.blockSize, this.settings.blockSize);
            }
            if ((pos + lowRotation) % 360 === 90) {
              bottomHoleEast = this.getTexture('basic', 'hole-bottom', 90);
              buffer.drawImage(bottomHoleEast, 0, 0, this.settings.blockSize, this.settings.blockSize);
            }
          }
        }
        this.drawOutline(buffer, 0, 0);
        type = topType === 'crossing-hole' ? 'crossing' : topType;
        cutouts = this.getTexture('cutouts-top', type, topRotation);
        if (cutouts) {
          buffer.globalCompositeOperation = 'destination-out';
          buffer.drawImage(cutouts, 0, 0, this.settings.blockSize, this.settings.blockSize);
          buffer.globalCompositeOperation = 'source-over';
        }
        cutouts = this.getTexture('cutouts-bottom', lowType, lowRotation);
        if (cutouts) {
          buffer.globalCompositeOperation = 'destination-out';
          buffer.drawImage(cutouts, 0, 0, this.settings.blockSize, this.settings.blockSize);
          buffer.globalCompositeOperation = 'source-over';
        }
      }
      return context.drawImage(cached, x, y, this.settings.blockSize, this.settings.blockSize);
    };
    Renderer.prototype.drawOutline = function(context, x, y) {
      return context.drawImage(this.getTexture('basic', 'outline'), x, y, this.settings.blockSize, this.settings.blockSize);
    };
    Renderer.prototype.drawDraggedBlocks = function(stack) {
      var block, height, index, width, _len, _results;
      width = this.settings.blockSize;
      height = stack.length === 1 ? this.settings.blockSize : this.settings.blockSize + this.settings.blockSizeHalf * (stack.length - 1);
      this.draggedCanvas.attr('width', width);
      this.draggedCanvas.attr('height', height);
      _results = [];
      for (index = 0, _len = stack.length; index < _len; index++) {
        block = stack[index];
        _results.push(this.drawBlock(this.draggedContext, block, 0, height - this.settings.blockSize - index * this.settings.blockSizeHalf));
      }
      return _results;
    };
    Renderer.TextureFileDescription = {
      'basic': {
        'hitbox': 1,
        'floor-hitbox': 1,
        'solid': 1,
        'floor': 1,
        'backside': 1,
        'outline': 1,
        'hole-middle': 2,
        'hole-low': 2,
        'hole-bottom': 2
      },
      'cutouts-top': {
        'crossing': 1,
        'curve': 4,
        'straight': 2
      },
      'cutouts-bottom': {
        'crossing': 1,
        'curve': 4,
        'straight': 2
      },
      'top': {
        'crossing': 1,
        'crossing-hole': 1,
        'curve': 4,
        'straight': 2
      },
      'middle': {
        'crossing': 1,
        'curve': 4,
        'straight': 2,
        'dive': 4,
        'drop-middle': 4,
        'drop-low': 4,
        'exchange-alt': 4,
        'exchange': 4
      },
      'low': {
        'crossing': 1,
        'curve': 4,
        'straight': 2
      }
    };
    Renderer.Cutouts = {
      'straight': [0, 180],
      'curve': [0, 90],
      'crossing': [0, 90, 180, 270]
    };
    Renderer.MidHoles = {
      'crossing': [0, 90, 180, 270],
      'curve': [0, 90],
      'straight': [0, 180],
      'dive': [0],
      'drop-middle': [0],
      'exchange': [0],
      'exchange-alt': [90]
    };
    Renderer.LowHoles = {
      'dive': [180],
      'drop-low': [0],
      'exchange': [90],
      'exchange-alt': [0]
    };
    Renderer.BottomHoles = {
      'straight': [0, 180],
      'curve': [0, 90],
      'crossing': [0, 90, 180, 270]
    };
    return Renderer;
  })();
  Compressor = (function() {
    Compressor.BytesPerBlock = 4;
    function Compressor() {}
    Compressor.prototype.compress = function(map) {
      var block, bytes, currentByte, gapSize, x, y, z, _i, _len, _ref, _ref2, _ref3, _ref4;
      bytes = new Array;
      gapSize = 0;
      for (x = 0, _ref = map.size; (0 <= _ref ? x < _ref : x > _ref); (0 <= _ref ? x += 1 : x -= 1)) {
        for (y = 0, _ref2 = map.size; (0 <= _ref2 ? y < _ref2 : y > _ref2); (0 <= _ref2 ? y += 1 : y -= 1)) {
          for (z = 0, _ref3 = map.size; (0 <= _ref3 ? z < _ref3 : z > _ref3); (0 <= _ref3 ? z += 1 : z -= 1)) {
            if (!(block = map.getBlock(x, y, z))) {
              gapSize++;
              continue;
            }
            if (gapSize > 0) {
              bytes.push(0xFF);
              bytes.push((gapSize & 0xFF0000) >> 16);
              bytes.push((gapSize & 0x00FF00) >> 8);
              bytes.push(gapSize & 0x0000FF);
              gapSize = 0;
            }
            _ref4 = this.encodeBlock(block);
            for (_i = 0, _len = _ref4.length; _i < _len; _i++) {
              currentByte = _ref4[_i];
              bytes.push(currentByte);
            }
          }
        }
      }
      return this.encodeArray(bytes);
    };
    Compressor.prototype.decompress = function(string, map) {
      var block, blockPosition, bytes, bytesIndex, gapSize, remainder, x, y, z, _ref, _ref2, _results;
      try {
        bytes = this.decodeArray(string);
      } catch (e) {
        throw e;
      }
      bytesIndex = 0;
      blockPosition = 0;
      _results = [];
      while (bytesIndex < (bytes.length - 2)) {
        if (bytes[bytesIndex] === 0xFF) {
          gapSize = bytes[bytesIndex + 1] << 16 | bytes[bytesIndex + 2] << 8 | bytes[bytesIndex + 3];
          blockPosition += gapSize;
          bytesIndex += Compressor.BytesPerBlock;
        }
        try {
          block = this.decodeBlock(bytes.slice(bytesIndex, (bytesIndex + Compressor.BytesPerBlock + 1) || 9e9));
        } catch (e) {
          throw e;
        }
        _ref = this.quotientAndRemainder(blockPosition, map.size * map.size), x = _ref[0], remainder = _ref[1];
        _ref2 = this.quotientAndRemainder(remainder, map.size), y = _ref2[0], remainder = _ref2[1];
        z = remainder;
        map.setBlock(block, x, y, z);
        bytesIndex += Compressor.BytesPerBlock;
        _results.push(blockPosition++);
      }
      return _results;
    };
    Compressor.prototype.quotientAndRemainder = function(dividend, divisor) {
      var quotient, remainder;
      quotient = Math.floor(dividend / divisor);
      remainder = dividend % divisor;
      return [quotient, remainder];
    };
    Compressor.prototype.encodeArray = function(bytes) {
      var counter, currentByte, padding, string, tmp, _i, _len;
      string = new Array;
      counter = 0;
      tmp = 0;
      for (_i = 0, _len = bytes.length; _i < _len; _i++) {
        currentByte = bytes[_i];
        tmp = (tmp << 8) | currentByte;
        counter++;
        if (counter % 3 === 0) {
          string.push(this.encodeBytes(tmp));
          tmp = 0;
        }
      }
      if (counter % 3) {
        padding = 3 - counter % 3;
        tmp = tmp << (padding * 8);
        string.push(this.encodeBytes(tmp));
        if (padding === 1) {
          string.push('=');
        }
        if (padding === 2) {
          string.push('==');
        }
      }
      return string.join('');
    };
    Compressor.prototype.decodeArray = function(string) {
      var bytes, index, tmp;
      bytes = new Array;
      index = 0;
      while (index < string.length) {
        if (string[index] === '=') {
          index++;
          continue;
        }
        try {
          tmp = this.decodeBytes(string.slice(index, index + 4));
        } catch (e) {
          throw e;
        }
        bytes.push((tmp & 0xFF0000) >> 16);
        bytes.push((tmp & 0x00FF00) >> 8);
        bytes.push(tmp & 0x0000FF);
        index += 4;
      }
      return bytes;
    };
    Compressor.prototype.encodeBlock = function(block) {
      var bytes, lowRotation, lowType, midRotation, midType, topRotation, topType, _ref, _ref2, _ref3;
      bytes = new Array;
      _ref = block.getProperty('top'), topType = _ref[0], topRotation = _ref[1];
      _ref2 = block.getProperty('middle'), midType = _ref2[0], midRotation = _ref2[1];
      _ref3 = block.getProperty('low'), lowType = _ref3[0], lowRotation = _ref3[1];
      bytes.push((topRotation / 90) << 4 | (midRotation / 90) << 2 | (lowRotation / 90));
      bytes.push(Compressor.CompressionTable[topType] || 0x00);
      bytes.push(Compressor.CompressionTable[midType] || 0x00);
      bytes.push(Compressor.CompressionTable[lowType] || 0x00);
      return bytes;
    };
    Compressor.prototype.decodeBlock = function(bytes) {
      var code, lowRotation, lowType, midRotation, midType, properties, rotations, topRotation, topType, type, _ref;
      rotations = bytes[0];
      topRotation = 90 * ((rotations & 0x30) >> 4);
      midRotation = 90 * ((rotations & 0x0C) >> 2);
      lowRotation = 90 * (rotations & 0x03);
      _ref = Compressor.CompressionTable;
      for (type in _ref) {
        code = _ref[type];
        if (code === bytes[1]) {
          topType = type;
        }
        if (code === bytes[2]) {
          midType = type;
        }
        if (code === bytes[3]) {
          lowType = type;
        }
      }
      properties = {
        'top': [topType || null, topRotation],
        'middle': [midType || null, midRotation],
        'low': [lowType || null, lowRotation]
      };
      return new Block(properties);
    };
    Compressor.prototype.encodeBytes = function(bytes) {
      var result;
      try {
        return result = this.encodeBits((bytes & 0xFC0000) >> 18) + this.encodeBits((bytes & 0x03F000) >> 12) + this.encodeBits((bytes & 0x000FC0) >> 6) + this.encodeBits(bytes & 0x00003F);
      } catch (e) {
        throw e;
      }
    };
    Compressor.prototype.decodeBytes = function(string) {
      var result;
      if (string.length !== 4) {
        throw new Error("Illegal chunk size, was " + string.length);
      }
      try {
        result = (this.decodeBits(string[0]) << 18) | (this.decodeBits(string[1]) << 12) | (this.decodeBits(string[2]) << 6) | this.decodeBits(string[3]);
        return result;
      } catch (e) {
        throw e;
      }
    };
    Compressor.prototype.encodeBits = function(bits) {
      if ((0 <= bits && bits <= 25)) {
        return String.fromCharCode(65 + bits);
      }
      if ((26 <= bits && bits <= 51)) {
        return String.fromCharCode(97 + bits - 26);
      }
      if ((52 <= bits && bits <= 61)) {
        return String.fromCharCode(48 + bits - 52);
      }
      if (bits === 62) {
        return '-';
      }
      if (bits === 63) {
        return '_';
      }
      throw new Error("Invalid argument " + bits + " must be smaller than 0x3F (63)");
    };
    Compressor.prototype.decodeBits = function(character) {
      var charCode;
      charCode = character.charCodeAt(0);
      if ((65 <= charCode && charCode <= 90)) {
        return charCode - 65;
      }
      if ((97 <= charCode && charCode <= 122)) {
        return charCode - 97 + 26;
      }
      if ((48 <= charCode && charCode <= 57)) {
        return charCode - 48 + 52;
      }
      if (charCode === 45) {
        return 62;
      }
      if (charCode === 95) {
        return 63;
      }
      throw new Error("Invalid argument, char must be of [A-Za-z0-9-_], was " + character);
    };
    Compressor.CompressionTable = {
      'straight': 0x01,
      'curve': 0x02,
      'crossing': 0x03,
      'exchange': 0x04,
      'exchange-alt': 0x05,
      'dive': 0x06,
      'crossing-hole': 0x07,
      'drop-middle': 0x08,
      'drop-low': 0x09
    };
    return Compressor;
  })();
  Game = (function() {
    Game.defaultSettings = {
      mapSize: 7,
      mainCanvasID: '#main-canvas',
      draggedCanvasID: '#dragged-canvas',
      selectorID: '#selector',
      defaultCursor: 'auto',
      dragCursor: $.browser.webkit && '-webkit-grab' || $.browser.mozilla && '-moz-grab' || 'auto',
      draggingCursor: $.browser.webkit && '-webkit-grabbing' || $.browser.mozilla && '-moz-grabbing' || 'auto',
      draggingOffset: 10
    };
    function Game(settings, onload) {
      this.draggingUp = __bind(this.draggingUp, this);;
      this.startDragWithBlocks = __bind(this.startDragWithBlocks, this);;
      this.draggingMove = __bind(this.draggingMove, this);;
      this.canvasDown = __bind(this.canvasDown, this);;
      this.canvasMove = __bind(this.canvasMove, this);;
      this.canvasUp = __bind(this.canvasUp, this);;
      this.bodyUp = __bind(this.bodyUp, this);;
      this.bodyMove = __bind(this.bodyMove, this);;
      this.bodyDown = __bind(this.bodyDown, this);;      var key, value, _ref, _ref2;
      this.settings = {};
      _ref = Game.defaultSettings;
      for (key in _ref) {
        value = _ref[key];
        this.settings[key] = settings[key] || Game.defaultSettings[key];
      }
      this.map = new Map(this.settings.mapSize);
      (_ref2 = window.state) != null ? _ref2 : window.state = {};
      state.type = 'normal';
      this.mainCanvas = $(this.settings.mainCanvasID);
      this.draggedCanvas = $(this.settings.draggedCanvasID);
      this.selector = $(this.settings.selectorID);
      this.renderer = new Renderer(this.map, __bind(function() {
        var $body, paletteSettings, renderingLoop;
        this.mainCanvas.bind('mouseup', this.canvasUp);
        this.mainCanvas.bind('mousemove', this.canvasMove);
        this.mainCanvas.bind('mousedown', this.canvasDown);
        this.mainCanvas.bind('touchstart', this.normalizeCoordinates(this.canvasDown));
        this.mainCanvas.bind('touchmove', this.normalizeCoordinates(this.canvasMove));
        this.mainCanvas.bind('touchend', this.normalizeCoordinates(this.canvasUp));
        $body = $('body');
        $body.bind('mouseup', this.bodyUp);
        $body.bind('mousemove', this.bodyMove);
        $body.bind('mousedown', this.bodyDown);
        $body.bind('touchstart', this.normalizeCoordinates(this.bodyDown));
        $body.bind('touchmove', this.normalizeCoordinates(this.bodyMove));
        $body.bind('touchend', this.normalizeCoordinates(this.bodyUp));
        $('#game .left').bind('mousedown', __bind(function(event) {
          this.map.rotateCCW();
          this.selectBlock(null);
          return this.hideSelector();
        }, this));
        $('#game .right').bind('mousedown', __bind(function(event) {
          this.map.rotateCW();
          this.selectBlock(null);
          return this.hideSelector();
        }, this));
        this.selector.children('.left').bind('mousedown', __bind(function(event) {
          var block, blockOnTop, x, y, z, _ref;
          _ref = state.info.coordinates, x = _ref[0], y = _ref[1], z = _ref[2];
          block = this.map.getBlock(x, y, z);
          if (z + 1 < this.map.size) {
            blockOnTop = this.map.getBlock(x, y, z + 1);
          }
          block.rotate(false, true, true, false);
          if (blockOnTop) {
            blockOnTop.rotate(false, false, false, true);
          }
          this.map.setNeedsRedraw(true);
          event.preventDefault();
          return false;
        }, this));
        this.selector.children('.right').bind('mousedown', __bind(function(event) {
          var block, blockOnTop, x, y, z, _ref;
          _ref = state.info.coordinates, x = _ref[0], y = _ref[1], z = _ref[2];
          block = this.map.getBlock(x, y, z);
          if (z + 1 < this.map.size) {
            blockOnTop = this.map.getBlock(x, y, z + 1);
          }
          block.rotate(true, true, true, false);
          if (blockOnTop) {
            blockOnTop.rotate(true, false, false, true);
          }
          this.map.setNeedsRedraw(true);
          event.preventDefault();
          return false;
        }, this));
        renderingLoop = __bind(function() {
          return this.renderer.drawMap();
        }, this);
        setInterval(renderingLoop, 20);
        paletteSettings = {
          startDragCallback: this.startDragWithBlocks
        };
        this.palette = new Palette(this.renderer, paletteSettings);
        return onload();
      }, this));
    }
    Game.prototype.selectBlock = function(block) {
      if (this.selectedBlock) {
        this.selectedBlock.setSelected(false);
      }
      this.selectedBlock = block;
      if (this.selectedBlock) {
        this.selectedBlock.setSelected(true);
      }
      return this.map.setNeedsRedraw(true);
    };
    Game.prototype.displaySelector = function(x, y) {
      if (x == null) {
        x = 0;
      }
      if (y == null) {
        y = 0;
      }
      return this.selector.css({
        'display': 'block',
        'position': 'absolute',
        'top': this.mainCanvas.offset().top + y,
        'left': this.mainCanvas.offset().left + x
      });
    };
    Game.prototype.hideSelector = function() {
      return this.selector.css({
        'display': 'none'
      });
    };
    Game.prototype.bodyDown = function(event) {
      switch (state.type) {
        case 'normal':
          this.selectBlock(null);
          return this.hideSelector();
      }
    };
    Game.prototype.bodyMove = function(event) {
      switch (state.type) {
        case 'dragging':
          return this.draggingMove(event);
        default:
          return $('body').css('cursor', this.settings.defaultCursor);
      }
    };
    Game.prototype.bodyUp = function(event) {
      switch (state.type) {
        case 'dragging':
          this.draggingUp(event);
      }
      return false;
    };
    Game.prototype.canvasUp = function(event) {
      var mouseX, mouseY, screenX, screenY, _ref, _ref2;
      switch (state.type) {
        case 'dragging':
          this.draggingUp(event);
          break;
        case 'down':
          mouseX = event.pageX - this.mainCanvas.offset().left;
          mouseY = event.pageY - this.mainCanvas.offset().top;
          if (state.info.block === this.renderer.resolveScreenCoordinates(mouseX, mouseY).block) {
            this.selectBlock(state.info.block);
            _ref2 = (_ref = this.renderer).renderingCoordinatesForBlock.apply(_ref, state.info.coordinates), screenX = _ref2[0], screenY = _ref2[1];
            this.displaySelector(screenX, screenY);
            state.type = 'normal';
          }
          break;
        case 'normal':
          this.selectBlock(null);
          this.hideSelector();
          break;
        default:
          if (DEBUG) {
            console.error("Illegal state", state.type);
          }
      }
      return false;
    };
    Game.prototype.canvasMove = function(event) {
      var mouseX, mouseY, side;
      mouseX = event.pageX - this.mainCanvas.offset().left;
      mouseY = event.pageY - this.mainCanvas.offset().top;
      switch (state.type) {
        case 'down':
          if (Math.abs(state.downX - mouseX) > this.settings.draggingOffset || Math.abs(state.downY - mouseY) > this.settings.draggingOffset) {
            this.startDrag(event);
          }
          break;
        case 'dragging':
          this.draggingMove(event);
          break;
        case 'normal':
          if (event.type !== 'touchmove') {
            side = this.renderer.sideAtScreenCoordinates(mouseX, mouseY);
            if (side && side !== 'floor') {
              $('body').css('cursor', this.settings.dragCursor);
            } else {
              $('body').css('cursor', this.settings.defaultCursor);
            }
          }
      }
      if (this.renderer.sideAtScreenCoordinates(mouseX, mouseY) !== null) {
        return event.preventDefault();
      }
    };
    Game.prototype.canvasDown = function(event) {
      var info, mouseX, mouseY;
      switch (state.type) {
        case 'normal':
          mouseX = event.pageX - this.mainCanvas.offset().left;
          mouseY = event.pageY - this.mainCanvas.offset().top;
          info = this.renderer.resolveScreenCoordinates(mouseX, mouseY);
          if (info.block) {
            state.type = 'down';
            state.downX = mouseX;
            state.downY = mouseY;
            state.info = info;
            event.preventDefault();
          }
      }
      return true;
    };
    Game.prototype.draggingMove = function(event) {
      var info, lowestBlock, mouseX, mouseY, offset, rotation, targetBlock, type, x, y, z, _ref, _ref2;
      this.map.blocksEach(__bind(function(block, x, y, z) {
        var changed;
        changed = false;
        if (block && block.dragged) {
          if (this.map.removeBlock(x, y, z)) {
            changed = true;
          }
        }
        if (changed) {
          return this.map.setNeedsRedraw(true);
        }
      }, this));
      mouseX = event.pageX - this.mainCanvas.offset().left;
      mouseY = event.pageY - this.mainCanvas.offset().top;
      info = this.renderer.resolveScreenCoordinates(mouseX, mouseY);
      _ref = info.coordinates || [0, 0, 0], x = _ref[0], y = _ref[1], z = _ref[2];
      targetBlock = this.map.getBlock(x, y, z);
      lowestBlock = state.stack && state.stack[0];
      if (info.side === 'floor' || info.side === 'top' && this.map.heightAt(x, y) + state.stack.length < this.map.size + 1 && Block.canStack(targetBlock, lowestBlock)) {
        this.hideDraggedCanvas(event);
        offset = info.side === 'top' ? 1 : 0;
        this.map.setStack(state.stack, x, y, z + offset);
        if (info.side === 'top') {
          _ref2 = targetBlock.getProperty('top'), type = _ref2[0], rotation = _ref2[1];
          type = (type === 'crossing-hole') && 'crossing' || type;
          lowestBlock.setProperty('low', type, rotation);
        } else {
          lowestBlock.setProperty('low', null, 0);
        }
        return this.map.setNeedsRedraw(true);
      } else {
        return this.showDraggedCanvas(event);
      }
    };
    Game.prototype.startDrag = function(event) {
      var blocks, canvasX, canvasY, info, x, y, z, _ref, _ref2;
      _ref = state.info.coordinates, x = _ref[0], y = _ref[1], z = _ref[2];
      blocks = this.map.removeStack(x, y, z);
      _ref2 = this.renderer.renderingCoordinatesForBlock(x, y, z + blocks.length), canvasX = _ref2[0], canvasY = _ref2[1];
      info = {
        mouseOffsetX: state.downX - canvasX,
        mouseOffsetY: state.downY - canvasY - this.renderer.settings.blockSizeHalf
      };
      this.startDragWithBlocks(blocks, info);
      return this.renderer.drawMap(true);
    };
    Game.prototype.startDragWithBlocks = function(blocks, info) {
      var block, _i, _len, _ref;
      this.selectBlock(null);
      this.hideSelector();
      state.stack = blocks;
      _ref = state.stack;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        block = _ref[_i];
        block.setDragged(true);
      }
      this.renderer.drawDraggedBlocks(state.stack);
      state.mouseOffsetX = info.mouseOffsetX;
      state.mouseOffsetY = info.mouseOffsetY;
      return state.type = 'dragging';
    };
    Game.prototype.hideDraggedCanvas = function(event) {
      return this.draggedCanvas.css('display', 'none');
    };
    Game.prototype.showDraggedCanvas = function(event) {
      var style;
      style = {
        'display': 'block',
        'position': 'absolute',
        'top': event.pageY - state.mouseOffsetY,
        'left': event.pageX - state.mouseOffsetX
      };
      return this.draggedCanvas.css(style);
    };
    Game.prototype.draggingUp = function(event) {
      state.stack = [];
      this.map.blocksEach(__bind(function(block, x, y, z) {
        if (block && block.dragged) {
          return block.setDragged(false);
        }
      }, this));
      state.type = 'normal';
      $('body').css('cursor', this.settings.defaultCursor);
      this.hideDraggedCanvas(event);
      this.updateCanvasMargin();
      return this.renderer.drawMap(true);
    };
    Game.prototype.updateCanvasMargin = function() {
      var height;
      height = 0;
      this.map.blocksEach(__bind(function(block, x, y, z) {
        if (block === null || block.dragged) {
          return;
        }
        if (z > height) {
          return height = z;
        }
      }, this));
      return this.mainCanvas.css({
        'margin-top': -50 + (-5 + height) * this.renderer.settings.blockSizeHalf
      });
    };
    Game.prototype.normalizeCoordinates = function(handler) {
      return function(event) {
        if (event.originalEvent.touches && event.originalEvent.touches[0]) {
          event.pageX = event.originalEvent.touches[0].pageX;
          event.pageY = event.originalEvent.touches[0].pageY;
        }
        return handler(event);
      };
    };
    return Game;
  })();
  Palette = (function() {
    Palette.defaultSettings = {
      paletteID: '#palette',
      startDragCallback: function(block) {},
      defaultCursor: null,
      dragCursor: null,
      draggingCursor: null
    };
    function Palette(renderer, settings) {
      var $image, $palette, block, callback, canvas, context, description, key, type, value, _ref, _ref2;
      this.renderer = renderer;
      if (settings == null) {
        settings = {};
      }
      this.settings = {};
      _ref = Palette.defaultSettings;
      for (key in _ref) {
        value = _ref[key];
        this.settings[key] = settings[key] || Palette.defaultSettings[key];
      }
      $palette = $(this.settings.paletteID);
      _ref2 = Block.Types;
      for (type in _ref2) {
        description = _ref2[type];
        block = Block.ofType(type);
        block.setOpacity(0.4);
        canvas = document.createElement('canvas');
        canvas.width = this.renderer.settings.blockSize;
        canvas.height = this.renderer.settings.blockSize;
        context = canvas.getContext('2d');
        this.renderer.drawBlock(context, block);
        $image = $('<img>');
        $image.data('type', type);
        $image.attr('src', canvas.toDataURL());
        $palette.append($image);
        callback = this.settings.startDragCallback;
        $image.bind('mousedown', function(event) {
          var info;
          info = {
            mouseOffsetX: event.pageX - $(this).offset().left,
            mouseOffsetY: event.pageY - $(this).offset().top
          };
          block = Block.ofType($(this).data('type'));
          return callback([block], info);
        });
        $image.bind('touchstart', function(event) {
          var info;
          if (event.originalEvent.touches.length) {
            info = {
              mouseOffsetX: event.originalEvent.touches[0].pageX - $(this).offset().left,
              mouseOffsetY: event.originalEvent.touches[0].pageY - $(this).offset().top
            };
            block = Block.ofType($(this).data('type'));
            callback([block], info);
            return event.preventDefault();
          }
        });
        renderer = this.renderer;
        $image.bind('mousemove', function(event) {
          var pixel, x, y;
          if (state.type === 'normal') {
            x = event.pageX - $(this).offset().left;
            y = event.pageY - $(this).offset().top;
            pixel = renderer.getTexture('basic', 'hitbox').getContext('2d').getImageData(x, y, 1, 1);
            if (pixel.data[3] > 0) {
              $('body').css('cursor', $.browser.webkit && '-webkit-grab' || $.browser.mozilla && '-moz-grab' || 'auto');
            } else {
              $('body').css('cursor', 'auto');
            }
            return false;
          }
        });
      }
    }
    return Palette;
  })();
  $(document).ready(function() {
    return this.game = new Game({}, __bind(function() {
      var compressor;
      if (window.location.hash.length > 1) {
        try {
          compressor = new Compressor;
          compressor.decompress(window.location.hash.slice(1), this.game.map);
          this.game.updateCanvasMargin();
        } catch (e) {
          if (DEBUG) {
            console.error("Coudl not parse map correctly: " + e);
          }
        }
      }
      return $('.share').bind('click', __bind(function() {
        var string;
        compressor = new Compressor;
        string = compressor.compress(this.game.map);
        window.location.replace('#' + string);
        $('#popup input').val(window.location);
        $('#popup').addClass('visible');
        return $('#popup #dismiss').bind('click', __bind(function() {
          return $('#popup').removeClass('visible');
        }, this));
      }, this));
    }, this));
  });
}).call(this);
