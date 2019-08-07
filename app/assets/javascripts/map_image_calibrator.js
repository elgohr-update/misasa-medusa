function initMapImageCalibrator() {
  var div = document.getElementById("surface-map");
  var baseUrl = div.dataset.baseUrl;
  var urlRoot = div.dataset.urlRoot;
  var global_id = div.dataset.globalId;
  var length = parseFloat(div.dataset.length);
  var center = JSON.parse(div.dataset.center);
  var baseImage = JSON.parse(div.dataset.baseImage);
  var layerGroups = JSON.parse(div.dataset.layerGroups);
  var images = JSON.parse(div.dataset.images);
  //var spots = JSON.parse(div.dataset.spots);
  if (("bounds" in div.dataset)){
    var _bounds = JSON.parse(div.dataset.bounds);
  }
  var layers = [];
  var baseMaps = {};
  var overlayMaps = {};
  var zoom = 1;
  var g_opacity = 0.5;

  var map = L.map('surface-map').setView([0,0],0);

  var latLng2world = function(latLng){
    point = map.project(latLng,0)
    ratio = 2*20037508.34/length
    x = center[0] - length/2.0 + point.x * length/256;
    y = center[1] + length/2.0 - point.y * length/256;
    return [x, y]
  };

  var world2latLng = function(world){
      x_w = world[0];
      y_w = world[1];
      x = (x_w - center[0] + length/2.0)*256/length
      y = (-y_w + center[1] + length/2.0)*256/length
      latLng = map.unproject([x,y],0)
      return latLng;
  };

  var map_LabelFcn = function(ll, opts){
    lng =L.NumberFormatter.round(ll.lng, opts.decimals, opts.decimalSeperator);
    lat = L.NumberFormatter.round(ll.lat, opts.decimals, opts.decimalSeperator);
    point = map.project(ll,0)
    xy_str = "x: " + point.x + " y: " + point.y;
    world = latLng2world(ll);
    gxy_str = "x_vs: " + world[0] + " y_vs: " + world[1];
    lngLat_str = "lng:" + lng + " lat:" + lat;
    str = gxy_str + " " + xy_str + " " + lngLat_str;
    return str;
  };

  var b_bounds = L.latLngBounds([
    world2latLng([baseImage.bounds[0], baseImage.bounds[1]]),
    world2latLng([baseImage.bounds[2], baseImage.bounds[3]])
  ]);

  L.imageOverlay(baseImage.path, b_bounds, {opacity: 0.5, attribute: baseImage.path}).addTo(map);

  map.addControl(new L.Control.Coordinates({position: 'topright', customLabelFcn:map_LabelFcn}));

  map.addControl(new L.Control.Fullscreen());

  imgActionArray = function(){
      return [CToggleTransparency, CToggleOutline, CToggleLock, CToggleRotateScale, CToggleOrder, CRevert, SaveImageAction];
  };

  var CToggleTransparency = L.EditAction.extend({
      initialize: function (map, overlay, options) {
	var edit = overlay.editing,
	  href,
	  tooltip,
	  symbol;

	if (edit._transparent) {
	  href = '<use xlink:href="#opacity"></use>';
	  symbol = '<symbol viewBox="0 0 18 18" id="opacity" xmlns="http://www.w3.org/2000/svg"><path fill="#0078A8" d="M13.245 6L9 1.763 4.755 6A6.015 6.015 0 0 0 3 10.23c0 1.5.585 3.082 1.755 4.252a5.993 5.993 0 0 0 8.49 0A6.066 6.066 0 0 0 15 10.23c0-1.5-.585-3.06-1.755-4.23zM4.5 10.5c.008-1.5.465-2.453 1.32-3.3L9 3.952l3.18 3.285c.855.84 1.313 1.763 1.32 3.263h-9z"/></symbol>';
	  tooltip = 'Make Image Opaque';
	} else {
	  href = '<use xlink:href="#opacity-empty"></use>';
	  symbol = '<symbol viewBox="0 0 14 18" id="opacity-empty" xmlns="http://www.w3.org/2000/svg"><path fill="#0078A8" stroke="#0078A8" stroke-width="1.7" d="M10.708 6.25A5.113 5.113 0 0 1 12.2 9.846c0 1.275-.497 2.62-1.492 3.614a5.094 5.094 0 0 1-7.216 0A5.156 5.156 0 0 1 2 9.846c0-1.275.497-2.601 1.492-3.596L7.1 2.648l3.608 3.602zm0 0L7.1 2.648 3.492 6.25A5.113 5.113 0 0 0 2 9.846c0 1.275.497 2.62 1.492 3.614a5.094 5.094 0 0 0 7.216 0A5.156 5.156 0 0 0 12.2 9.846a5.113 5.113 0 0 0-1.492-3.596z"/></symbol>';
	  tooltip = 'Make Image Transparent';
	}

	options = options || {};
	options.toolbarIcon = {
	  html: '<svg class="svg-icons">' + href + symbol + '</svg>',
	  tooltip: tooltip
	};

	L.EditAction.prototype.initialize.call(this, map, overlay, options);
      },

      addHooks: function () {
	var editing = this._overlay.editing;

	//editing._toggleTransparency();
        var image = editing._overlay._image, opacity;
        editing._transparent = !editing._transparent;
        opacity = editing._transparent ? 0 : g_opacity;
        L.DomUtil.setOpacity(image, opacity);
        image.setAttribute("opacity", opacity);
        editing._showToolbar();
      }
  });  


  var CToggleOutline = L.EditAction.extend({
      initialize: function (map, overlay, options) {
	var edit = overlay.editing,
	  href,
	  tooltip,
	  symbol;


	if (edit._outlined) {
	  href = '<use xlink:href="#border_clear"></use>';
	  symbol = '<symbol viewBox="0 0 18 18" id="border_clear" xmlns="http://www.w3.org/2000/svg"><path fill="#0078A8" d="M5.25 3.75h1.5v-1.5h-1.5v1.5zm0 6h1.5v-1.5h-1.5v1.5zm0 6h1.5v-1.5h-1.5v1.5zm3-3h1.5v-1.5h-1.5v1.5zm0 3h1.5v-1.5h-1.5v1.5zm-6 0h1.5v-1.5h-1.5v1.5zm0-3h1.5v-1.5h-1.5v1.5zm0-3h1.5v-1.5h-1.5v1.5zm0-3h1.5v-1.5h-1.5v1.5zm0-3h1.5v-1.5h-1.5v1.5zm6 6h1.5v-1.5h-1.5v1.5zm6 3h1.5v-1.5h-1.5v1.5zm0-3h1.5v-1.5h-1.5v1.5zm0 6h1.5v-1.5h-1.5v1.5zm0-9h1.5v-1.5h-1.5v1.5zm-6 0h1.5v-1.5h-1.5v1.5zm6-4.5v1.5h1.5v-1.5h-1.5zm-6 1.5h1.5v-1.5h-1.5v1.5zm3 12h1.5v-1.5h-1.5v1.5zm0-6h1.5v-1.5h-1.5v1.5zm0-6h1.5v-1.5h-1.5v1.5z"/></symbol>';
	  tooltip = 'Remove Border';
	} else {
	  href = '<use xlink:href="#border_outer"></use>';
	  symbol = '<symbol viewBox="0 0 18 18" id="border_outer" xmlns="http://www.w3.org/2000/svg"><path fill="#0078A8" d="M9.75 5.25h-1.5v1.5h1.5v-1.5zm0 3h-1.5v1.5h1.5v-1.5zm3 0h-1.5v1.5h1.5v-1.5zm-10.5-6v13.5h13.5V2.25H2.25zm12 12H3.75V3.75h10.5v10.5zm-4.5-3h-1.5v1.5h1.5v-1.5zm-3-3h-1.5v1.5h1.5v-1.5z" /></symbol>'
	  tooltip = 'Add Border';
	}

	options = options || {};
	options.toolbarIcon = {
	  html: '<svg class="svg-icons">' + href + symbol + '</svg>',
	  tooltip: tooltip
	};

	L.EditAction.prototype.initialize.call(this, map, overlay, options);
      },

      addHooks: function () {
	var editing = this._overlay.editing;

	editing._toggleOutline();
      }
  });

  var CDelete = L.EditAction.extend({
      initialize: function (map, overlay, options) {
	var href = '<use xlink:href="#delete_forever"></use>';
	var symbol = '<symbol viewBox="0 0 18 18" id="delete_forever" xmlns="http://www.w3.org/2000/svg"><path fill="#c10d0d" d="M4.5 14.25c0 .825.675 1.5 1.5 1.5h6c.825 0 1.5-.675 1.5-1.5v-9h-9v9zm1.845-5.34l1.058-1.058L9 9.443l1.59-1.59 1.058 1.058-1.59 1.59 1.59 1.59-1.058 1.058L9 11.558l-1.59 1.59-1.058-1.058 1.59-1.59-1.597-1.59zM11.625 3l-.75-.75h-3.75l-.75.75H3.75v1.5h10.5V3h-2.625z" /></symbol>';

	options = options || {};
	options.toolbarIcon = {
	  html: '<svg class="svg-icons">' + href + symbol + '</svg>',
	  tooltip: 'Delete Image'
	};

	L.EditAction.prototype.initialize.call(this, map, overlay, options);
      },

      addHooks: function () {
	var editing = this._overlay.editing;

	editing._removeOverlay();
      }
  });

  var CToggleLock = L.EditAction.extend({
      initialize: function (map, overlay, options) {
	var edit = overlay.editing,
	  href,
	  tooltip,
	  symbol;

	if (edit._mode === 'lock') {
	  href = '<use xlink:href="#unlock"></use>';
	  symbol = '<symbol viewBox="0 0 18 18" id="unlock" xmlns="http://www.w3.org/2000/svg"><path fill="#0078A8" d="M13.5 6h-.75V4.5C12.75 2.43 11.07.75 9 .75 6.93.75 5.25 2.43 5.25 4.5h1.5A2.247 2.247 0 0 1 9 2.25a2.247 2.247 0 0 1 2.25 2.25V6H4.5C3.675 6 3 6.675 3 7.5V15c0 .825.675 1.5 1.5 1.5h9c.825 0 1.5-.675 1.5-1.5V7.5c0-.825-.675-1.5-1.5-1.5zm0 9h-9V7.5h9V15zM9 12.75c.825 0 1.5-.675 1.5-1.5s-.675-1.5-1.5-1.5-1.5.675-1.5 1.5.675 1.5 1.5 1.5z"/></symbol>';
	  tooltip = 'Unlock';
	} else {
	  href = '<use xlink:href="#lock"></use>';
	  symbol = '<symbol viewBox="0 0 18 18" id="lock" xmlns="http://www.w3.org/2000/svg"><path fill="#0078A8" d="M13.5 6h-.75V4.5C12.75 2.43 11.07.75 9 .75 6.93.75 5.25 2.43 5.25 4.5V6H4.5C3.675 6 3 6.675 3 7.5V15c0 .825.675 1.5 1.5 1.5h9c.825 0 1.5-.675 1.5-1.5V7.5c0-.825-.675-1.5-1.5-1.5zM6.75 4.5A2.247 2.247 0 0 1 9 2.25a2.247 2.247 0 0 1 2.25 2.25V6h-4.5V4.5zM13.5 15h-9V7.5h9V15zM9 12.75c.825 0 1.5-.675 1.5-1.5s-.675-1.5-1.5-1.5-1.5.675-1.5 1.5.675 1.5 1.5 1.5z"/></symbol>';
	  tooltip = 'Lock';
	}

	options = options || {};
	options.toolbarIcon = {
	  html: '<svg class="svg-icons">' + href + symbol + '</svg>',
	  tooltip: tooltip
	};

	L.EditAction.prototype.initialize.call(this, map, overlay, options);
      },

      addHooks: function () {
	var editing = this._overlay.editing;

	editing._toggleLock();
      }
  });

  var CToggleRotateScale = L.EditAction.extend({
      initialize: function (map, overlay, options) {
	var edit = overlay.editing,
	  href,
	  tooltip,
	  symbol;

	if (edit._mode === 'rotateScale') {
	  href = '<use xlink:href="#transform"></use>';
	  symbol = '<symbol viewBox="0 0 18 18" id="transform" xmlns="http://www.w3.org/2000/svg"><path fill="#0078A8" d="M16.5 13.5V12H6V3h1.5L5.25.75 3 3h1.5v1.5h-3V6h3v6c0 .825.675 1.5 1.5 1.5h6V15h-1.5l2.25 2.25L15 15h-1.5v-1.5h3zM7.5 6H12v4.5h1.5V6c0-.825-.675-1.5-1.5-1.5H7.5V6z"/></symbol>';
	  tooltip = 'Distort';
	} else {
	  href = '<use xlink:href="#crop_rotate"></use>';
	  symbol = '<symbol viewBox="0 0 18 18" id="crop_rotate" xmlns="http://www.w3.org/2000/svg"><path fill="#0078A8" d="M5.603 16.117C3.15 14.947 1.394 12.57 1.125 9.75H0C.383 14.37 4.245 18 8.963 18c.172 0 .33-.015.495-.023L6.6 15.113l-.997 1.005zM9.037 0c-.172 0-.33.015-.495.03L11.4 2.888l.998-.998a7.876 7.876 0 0 1 4.477 6.36H18C17.617 3.63 13.755 0 9.037 0zM12 10.5h1.5V6A1.5 1.5 0 0 0 12 4.5H7.5V6H12v4.5zM6 12V3H4.5v1.5H3V6h1.5v6A1.5 1.5 0 0 0 6 13.5h6V15h1.5v-1.5H15V12H6z" /></symbol>';
	  tooltip = 'Rotate+Scale';
	}

	options = options || {};
	options.toolbarIcon = {
	  html: '<svg class="svg-icons">' + href + symbol + '</svg>',
	  tooltip: tooltip
	};

	L.EditAction.prototype.initialize.call(this, map, overlay, options);
      },

      addHooks: function () {
	var editing = this._overlay.editing;

	editing._toggleRotateScale();
      }
  });

  var CToggleOrder = L.EditAction.extend({
      initialize: function (map, overlay, options) {
	var edit = overlay.editing,
	  href,
	  tooltip,
	  symbol;

	if (edit._toggledImage) {
	  href = '<use xlink:href="#flip_to_front"></use>';
	  symbol = '<symbol viewBox="0 0 18 18" id="flip_to_front" xmlns="http://www.w3.org/2000/svg"><path fill="#0078A8" d="M2.25 9.75h1.5v-1.5h-1.5v1.5zm0 3h1.5v-1.5h-1.5v1.5zm1.5 3v-1.5h-1.5a1.5 1.5 0 0 0 1.5 1.5zm-1.5-9h1.5v-1.5h-1.5v1.5zm9 9h1.5v-1.5h-1.5v1.5zm3-13.5h-7.5a1.5 1.5 0 0 0-1.5 1.5v7.5a1.5 1.5 0 0 0 1.5 1.5h7.5c.825 0 1.5-.675 1.5-1.5v-7.5c0-.825-.675-1.5-1.5-1.5zm0 9h-7.5v-7.5h7.5v7.5zm-6 4.5h1.5v-1.5h-1.5v1.5zm-3 0h1.5v-1.5h-1.5v1.5z"/></symbol>';
	  tooltip = 'Stack to Front';
	} else {
	  href = '<use xlink:href="#flip_to_back"></use>';
	  symbol = '<symbol viewBox="0 0 18 18" id="flip_to_back" xmlns="http://www.w3.org/2000/svg"><path fill="#0078A8" d="M6.75 5.25h-1.5v1.5h1.5v-1.5zm0 3h-1.5v1.5h1.5v-1.5zm0-6a1.5 1.5 0 0 0-1.5 1.5h1.5v-1.5zm3 9h-1.5v1.5h1.5v-1.5zm4.5-9v1.5h1.5c0-.825-.675-1.5-1.5-1.5zm-4.5 0h-1.5v1.5h1.5v-1.5zm-3 10.5v-1.5h-1.5a1.5 1.5 0 0 0 1.5 1.5zm7.5-3h1.5v-1.5h-1.5v1.5zm0-3h1.5v-1.5h-1.5v1.5zm0 6c.825 0 1.5-.675 1.5-1.5h-1.5v1.5zm-10.5-7.5h-1.5v9a1.5 1.5 0 0 0 1.5 1.5h9v-1.5h-9v-9zm7.5-1.5h1.5v-1.5h-1.5v1.5zm0 9h1.5v-1.5h-1.5v1.5z"/></symbol>';
	  tooltip = 'Stack to Back';
	}

	options = options || {};
	options.toolbarIcon = {
	  html: '<svg class="svg-icons">' + href + symbol + '</svg>',
	  tooltip: tooltip
	};

	L.EditAction.prototype.initialize.call(this, map, overlay, options);
      },

      addHooks: function () {
	var editing = this._overlay.editing;

	editing._toggleOrder();
      }
  });
  var CRevert = L.EditAction.extend({
      initialize: function (map, overlay, options) {
	var href = '<use xlink:href="#restore"></use>';
	var symbol = '<symbol viewBox="0 0 18 18" id="restore" xmlns="http://www.w3.org/2000/svg"><path fill="#058dc4" d="M15.67 3.839a.295.295 0 0 0-.22.103l-5.116 3.249V4.179a.342.342 0 0 0-.193-.315.29.29 0 0 0-.338.078L3.806 7.751v-4.63h-.002l.002-.022c0-.277-.204-.502-.456-.502h-.873V2.6c-.253 0-.457.225-.457.503l.002.026v10.883h.005c.021.257.217.454.452.455l.016-.002h.822c.013.001.025.004.038.004.252 0 .457-.225.457-.502a.505.505 0 0 0-.006-.068V9.318l6.001 3.811a.288.288 0 0 0 .332.074.34.34 0 0 0 .194-.306V9.878l5.12 3.252a.288.288 0 0 0 .332.073.34.34 0 0 0 .194-.306V4.18a.358.358 0 0 0-.09-.24.296.296 0 0 0-.218-.1z"/></symbol>';

	options = options || {};
	options.toolbarIcon = {
	  html: '<svg class="svg-icons">' + href + symbol + '</svg>',
	  tooltip: 'Restore'
	};

	L.EditAction.prototype.initialize.call(this, map, overlay, options);
      },

      addHooks: function () {
	var editing = this._overlay.editing;

	editing._revert();
      }
  });

  var SaveImageAction = L.EditAction.extend({
	  initialize: function (map, overlay, options){
              var use = '<use xlink:href="#get_app"></use>'
              var symbol = '<symbol viewBox="0 0 18 18" id="get_app" xmlns="http://www.w3.org/2000/svg"><path fill="#058dc4" d="M14.662 6.95h-3.15v-4.5H6.787v4.5h-3.15L9.15 12.2l5.512-5.25zM3.637 13.7v1.5h11.025v-1.5H3.637z"/></symbol></svg>'

	      var href = '<use xlink:href="/assets/icons/symbol/sprite.symbol.svg#get_app"></use>';
              options = options || {};
              options.toolbarIcon = {
		  html: '<svg class="svg-icons">' + use + symbol + '</svg>',
		  tooltip: 'Save Image'
	      };
	      L.EditAction.prototype.initialize.call(this, map, overlay, options);
	  },
	  addHooks: function(){
	      var img = this._overlay;
              saveImage.bind(img)();
	  }
  });
 
  saveImage = function(){
      var img = this;
      var corners_on_map = [];
      var corners_on_world = [];
      img._corners.forEach(function(_corner){
        corners_on_map.push(map.project(_corner,0))
	corners_on_world.push(latLng2world(_corner));
      });
      $.ajax(img.resource_url + ".json",{
        type: 'PUT',
	data: {surface_image: 
		  {corners_on_world:
		      corners_on_world[0][0] + ',' + corners_on_world[0][1] + ':' +
		      corners_on_world[1][0] + ',' + corners_on_world[1][1] + ':' +
		      corners_on_world[3][0] + ',' + corners_on_world[3][1] + ':' +
		      corners_on_world[2][0] + ',' + corners_on_world[2][1],
		  }
	},
	beforeSend: function(e){ console.log('saving...')},
        complete: function(e){ 'ok' },
	error: function(e) {console.log(e)}
      })
  }; 
  var imgs = [];
  layerGroups.concat([{ name: "", opacity: 100 }]).forEach(function(layerGroup) {
    var group = L.layerGroup(), name = layerGroup.name, opacity = layerGroup.opacity / 100.0;
    if (images[name]) {
      image = images[name][0];
      var corners = [
        world2latLng(image.corners[0]),
        world2latLng(image.corners[1]),
        world2latLng(image.corners[3]),
        world2latLng(image.corners[2])
      ];
      opts = {mode: "rotateScale", actions: imgActionArray(), corners: corners}
      img = L.distortableImageOverlay(image.path,opts).addTo(map);
      L.DomUtil.setOpacity(img._image, g_opacity);
      img._image.setAttribute("opacity", g_opacity);
      imgs.push(img);
      img.warpable_id = image.id
      img.resource_url = image.resource_url
      img.addTo(map)
    }
  });
  imgGroup = L.distortableCollection().addTo(map);
  imgs.forEach(function(img){
    imgGroup.addLayer(img);
  });

  surfaceMap = map;
}