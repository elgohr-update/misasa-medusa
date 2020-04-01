// OpacityLayerControl
L.Control.OpacityLayers = L.Control.Layers.extend({
    onAdd: function (map) {
      this._initLayout();
      this._update();

      this._map = map;
      map.on('zoomend', this._checkDisabledLayers, this);
      map.on('changeorder', this._onLayerChange, this);
      for (var i = 0; i < this._layers.length; i++) {
        this._layers[i].layer.on('add remove', this._onLayerChange, this);
      }

      return this._container;
    },
    onRemove: function () {
      this._map.off('zoomend', this._checkDisabledLayers, this);
      this._map.off('changeorder', this._onLayerChange, this);
      for (var i = 0; i < this._layers.length; i++) {
        this._layers[i].layer.off('add remove', this._onLayerChange, this);
      }
    },
    _initLayout: function(){
        L.Control.Layers.prototype._initLayout.call(this);
        base = $(this._container).find(".leaflet-control-layers-base");
        overlays = $(this._container).find(".leaflet-control-layers-overlays");
        separator = $(this._container).find(".leaflet-control-layers-separator");
        overlays.after(separator);
        separator.after(base);
    },
    _addLayer: function (layer, name, overlay) {
        if (this._map) {
          layer.on('add remove', this._onLayerChange, this);
        }

        this._layers.push({
          layer: layer,
          name: name,
          overlay: overlay
        });

        if (this.options.sortLayers) {
          this._layers.sort(Util.bind(function (a, b) {
            return this.options.sortFunction(a.layer, b.layer, a.name, b.name);
          }, this));
        }

        if (this.options.autoZIndex && layer.setZIndex) {
          this._lastZIndex++;
          layer.setZIndex(this._lastZIndex);
        }
        this._expandIfNotCollapsed();
    },
    _update: function() {
        if (!this._container) { return this; }

        L.DomUtil.empty(this._baseLayersList);
        L.DomUtil.empty(this._overlaysList);

        this._layerControlInputs = [];
        var baseLayersPresent, overlaysPresent, i, obj, baseLayersCount = 0;

        for (i = 0; i < this._layers.length; i++) {
          obj = this._layers[i];
          this._addItem(obj);
	  overlaysPresent = overlaysPresent || obj.overlay;
	  baseLayersPresent = baseLayersPresent || !obj.overlay;
          baseLayersCount += !obj.overlay ? 1 : 0;
        }

        // Hide base layers section if there's only one layer.
        if (this.options.hideSingleBase) {
          baseLayersPresent = baseLayersPresent && baseLayersCount > 1;
          this._baseLayersList.style.display = baseLayersPresent ? '' : 'none';
        }
        this._separator.style.display = overlaysPresent && baseLayersPresent ? '' : 'none';
        return this;
    },
    _addItem: function (obj) {
	//var row = L.DomUtil.create('div','leaflet-row');
        var label = document.createElement('label'),
            checked = this._map.hasLayer(obj.layer),
            input;

        if (obj.overlay) {
          input = document.createElement('input');
          input.type = 'checkbox';
          input.className = 'leaflet-control-layers-selector';
          input.defaultChecked = checked;
        } else {
          input = this._createRadioElement('leaflet-base-layers', checked);
        }

        this._layerControlInputs.push(input);
        input.layerId = L.Util.stamp(obj.layer);

        L.DomEvent.on(input, 'click', this._onInputClick, this);

        var name = document.createElement('span');
        name.innerHTML = ' ' + obj.name;
        //var col = L.DomUtil.create('div','leaflet-input');
        //col.appendChild(input);
        //row.appendChild(col);
        //var col = L.DomUtil.create('div', 'leaflet-name');
        //label.htmlFor = input.id;
        //col.appendChild(label);
        //row.appendChild(col);
        //label.appendChild(name);
        // Helps from preventing layer control flicker when checkboxes are disabled
        // https://github.com/Leaflet/Leaflet/issues/2771
        var holder = document.createElement('div');
        label.appendChild(holder);
        holder.appendChild(input);
        holder.appendChild(name);

        if (obj.overlay) {
          var up = L.DomUtil.create('div','leaflet-up');
          L.DomEvent.on(up, 'click', this._onUpClick, this);
          up.layerId = input.layerId;
          //holder.appendChild(up);
          var down = L.DomUtil.create('div','leaflet-down');
          L.DomEvent.on(down, 'click', this._onDownClick, this);
          down.layerId = input.layerId;
          //holder.appendChild(down);

          input = document.createElement('input');
          input.type = 'range';
          input.min = 0;
          input.max = 100;
          if (obj.layer && obj.layer.getLayers() && obj.layer.getLayers()[0]){
	          input.value = 100 * obj.layer.getLayers()[0].options.opacity
          } else {
            input.value = 100;
          }
          this._layerControlInputs.push(input);
          input.layerId = L.stamp(obj.layer);
          if (this._map.hasLayer(obj.layer)) {
            input.style.display = 'block';
          } else {
            input.style.display = 'none';
          }

          L.DomEvent.on(input, 'change', this._onInputClick, this);

          label.appendChild(input);
        }

        var container = obj.overlay ? this._overlaysList : this._baseLayersList;
        //container.appendChild(label);
        container.prependChild(label);
        this._checkDisabledLayers();


        return label;
    },
    _onUpClick: function(e){
      var layerId = e.currentTarget.layerId;
      var obj = this._getLayer(layerId);
      if(!obj.overlay){
        return;
      }
      replaceLayer = null;
      var zidx = this._getZIndex(obj);
      for(var i=0; i < this._layers.length; i++){
         ly = this._layers[i];
         var auxIdx = this._getZIndex(ly);
         if(ly.overlay && (zidx + 1) === auxIdx){
           replaceLayer = ly;
           break;
         }
      }

      var newZIndex = zidx + 1;
      if(replaceLayer){
        obj.layer.setZIndex(newZIndex);
        replaceLayer.layer.setZIndex(newZIndex - 1);
        this._layers.splice(i,1);
        this._layers.splice(i+1,0,replaceLayer);
        this._map.fire('changeorder', obj, this);
      }
    },
    _onDownClick: function(e){
      var layerId = e.currentTarget.layerId;
      var obj = this._getLayer(layerId);
      if(!obj.overlay){
        return;
      }
      replaceLayer = null;
      var zidx = this._getZIndex(obj);
      for(var i=0; i < this._layers.length; i++){
         ly = this._layers[i];
         layerId = L.Util.stamp(ly.layer);
         var auxIdx = this._getZIndex(ly);
         if(ly.overlay && (zidx - 1) === auxIdx){
           replaceLayer = ly;
           break;
         }
      }

      var newZIndex = zidx - 1;
      if(replaceLayer){
        obj.layer.setZIndex(newZIndex);
        replaceLayer.layer.setZIndex(newZIndex + 1);
        this._layers.splice(i,1);
        this._layers.splice(i-1,0,replaceLayer);
        this._map.fire('changeorder', obj, this);
      }
    },
    _onInputClick: function () {
        var i, input, obj,
        //inputs = this._form.getElementsByTagName('input');
        inputs = this._layerControlInputs;
        inputsLen = inputs.length;

        this._handlingClick = true;

        for (i = 0; i < inputsLen; i++) {
            input = inputs[i];

            //obj = this._layers[input.layerId];
	          obj = this._getLayer(input.layerId);
            
            if (input.type == 'range' && this._map.hasLayer(obj.layer)) {
                input.style.display = 'block';
                opacity = input.value / 100.0;
		            group_layers = obj.layer.getLayers();
		            for (var j = 0; j < group_layers.length; j++){
		              var _layer = group_layers[j];
		              if (typeof _layer._url === 'undefined'){
		              } else {
			              _layer.setOpacity(opacity);
		              }
		            }
                continue;
            } else if (input.type == 'range' && !this._map.hasLayer(obj.layer)) {
                input.style.display = 'none';
                continue;
            }

            if (input.checked && !this._map.hasLayer(obj.layer)) {
                this._map.addLayer(obj.layer);

            } else if (!input.checked && this._map.hasLayer(obj.layer)) {
                this._map.removeLayer(obj.layer);
            } //end if
        } //end loop

        this._handlingClick = false;

        this._refocusOnMap();
	},
        _getZIndex: function(ly){
	  var zindex = 9999999999;
          if(ly.layer.options && ly.layer.options.zIndex){
	      zindex = ly.layer.options.zIndex;
          } else if (ly.layer.getLayers && ly.layer.eachLayer){
              ly.layer.eachLayer(function(lay){
	        if(lay.options && lay.options.zIndex){
		    zindex = Math.min(lay.options.zIndex, zindex);
                }
              });
          }
          return zindex;
        } 
});

L.control.opacityLayers = function (baseLayers, overlays, options) {
        return new L.Control.OpacityLayers(baseLayers, overlays, options);
};
// Customized scale control for surface.
L.Control.SurfaceScale = L.Control.Scale.extend({
  options: L.Util.extend({}, L.Control.Scale.prototype.options, { length: undefined }),
  _updateMetric: function(maxMeters) {
    var map = this._map,
	pixelsPerMeter = this.options.maxWidth / (maxMeters * map.getZoomScale(map.getZoom(), 0)),
	microMetersPerPixel = this.options.length / 256;
	rate = pixelsPerMeter * microMetersPerPixel,
	meters = this._getRoundNum(maxMeters * rate),
	label = meters < 1000 ? meters + ' μm' : (meters / 1000) + ' mm';
    this._updateScale(this._mScale, label, meters / rate / maxMeters);
  }
});
L.control.surfaceScale = function(options) {
  return new L.Control.SurfaceScale(options);
};


// Customized circle for spot.
L.circle.spot = function(map, spot, urlRoot, options) {
    var options = L.Util.extend({}, { color: 'red', fillColor: '#f03', fillOpacity: 0.5, radius: 3 }, options),
      marker = new L.circle(map.unproject([spot.x, spot.y], 0), options);
  marker.on('click', function() {
    var latlng = this.getLatLng(),
        link = '<a href=' + urlRoot + 'records/' + spot.id + '>' + spot.name + '</a><br/>';
    this.bindPopup(link + "x: " + latlng.lng.toFixed(2) + "<br />y: " + -latlng.lat.toFixed(2)).openPopup();
  });
  return marker;
};


// Radius control for Circle.
L.Control.Radius = L.Control.extend({
  initialize: function (layerGroup, options) {
    this._layerGroup = layerGroup;
    L.Util.setOptions(this, options);
  },
  onAdd: function(map) {
    var layerGroup = this._layerGroup,
	div = L.DomUtil.create('div', 'leaflet-control-layers'),
        range = this.range = L.DomUtil.create('input');
    range.type = 'range';
    range.min = 0.1;
    range.max = 10;
    range.step = 0.1;
    range.value = 3;
    range.style = 'width:60px;margin:3px;';
    div.appendChild(range);
    L.DomEvent.on(range, 'click', function(event) {
      event.preventDefault();
    });
    L.DomEvent.on(range, 'change', function() {
      layerGroup.eachLayer(function(layer) {
	layer.setRadius(range.value);
      });
    });
    L.DomEvent.on(range, 'input', function() {
      layerGroup.eachLayer(function(layer) {
	layer.setRadius(range.value);
      });
    });
    L.DomEvent.on(range, 'mouseenter', function(e) {
      map.dragging.disable()
    });
    L.DomEvent.on(range, 'mouseleave', function(e) {
      map.dragging.enable();
    });
    return div;
  },
  getValue: function() {
    return this.range.value;
  }
});
L.control.radius = function(layerGroup, options) {
  return new L.Control.Radius(layerGroup, options);
};


// Customized layer group for spots.
L.layerGroup.spots = function(map, spots, urlRoot) {
  var group = L.layerGroup();
  for(var i = 0; i < spots.length; i++) {
    L.circle.spot(map, spots[i], urlRoot).addTo(group);
  }
  return group;
};


// Customized layer group for grid.
L.layerGroup.grid = function(map, length) {
  var group = L.layerGroup(),
      pixelsPerMiliMeter = 256 * 1000 / length,
      getFromTo = function(half, step) {
        var center = 256 / 2;
        return {
	  from: center - Math.ceil(half / step) * step,
	  to: center + Math.ceil(half / step) * step
	}
      },
      xFromTo = getFromTo(map.getSize().x / 2, pixelsPerMiliMeter),
      yFromTo = getFromTo(map.getSize().y / 2, pixelsPerMiliMeter);
  for (y = yFromTo.from; y < yFromTo.to + 1; y += pixelsPerMiliMeter) {
    var left = map.unproject([xFromTo.from, y], 0),
	right = map.unproject([xFromTo.to, y]);
    L.polyline([left, right], { color: 'red', weight: 1, opacity: 0.5 }).addTo(group);
  }
  for (x = xFromTo.from; x < xFromTo.to + 1; x += pixelsPerMiliMeter) {
    var top = map.unproject([x, yFromTo.from], 0),
	bottom = map.unproject([x, yFromTo.to]);
    L.polyline([top, bottom], { color: 'red', weight: 1, opacity: 0.5 }).addTo(group);
  }
  return group;
};


function initSurfaceMap() {
  var div = document.getElementById("surface-map");
  var radiusSelect = document.getElementById("spot-radius");
  var baseUrl = div.dataset.baseUrl;
  var resourceUrl = div.dataset.resourceUrl;
  var urlRoot = div.dataset.urlRoot;
  var global_id = div.dataset.globalId;
  var length = parseFloat(div.dataset.length);
  var center = JSON.parse(div.dataset.center);
  //var matrix = JSON.parse(div.dataset.matrix);
  //var addSpot = JSON.parse(div.dataset.addSpot);
  //var addRadius = div.dataset.addRadius;
  var baseImages = JSON.parse(div.dataset.baseImages);
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

  var map = L.map('surface-map', {
    maxZoom: 14,
    minZoom: 0,
    //crs: L.CRS.Simple,
    //    layers: layers
  });

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

  var worldBounds = function(world_bounds){
      return L.latLngBounds([world2latLng([world_bounds[0], world_bounds[1]]),world2latLng([world_bounds[2], world_bounds[3]])]);
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
  map.addControl(new L.Control.Coordinates({position: 'topright', customLabelFcn:map_LabelFcn}));

  
  if (_bounds){
      var bounds = worldBounds(_bounds);
  }

  baseImages.forEach(function(baseImage) {
    var opts = {maxNativeZoom: 6}

    if (baseImage.bounds){
	opts = Object.assign(opts, {bounds: worldBounds(baseImage.bounds)});
    }
    if (baseImage.max_zoom){
	opts = Object.assign(opts, {maxNativeZoom: baseImage.max_zoom});
    }

    var layer = L.tileLayer(baseUrl + global_id + '/' + baseImage.id + '/{z}/{x}_{y}.png',opts);
    layers.push(layer);
    baseMaps[baseImage.name] = layer;
    layer.addTo(map);
  });
  layerGroups.concat([{ name: "", opacity: 100 }]).forEach(function(layerGroup) {
    var group = L.layerGroup(), name = layerGroup.name, opacity = layerGroup.opacity / 100.0;
    opts = {opacity: opacity, maxNativeZoom: 6};

    if (layerGroup.tiled){
      if (layerGroup.bounds){
        opts = Object.assign(opts, {bounds: worldBounds(layerGroup.bounds)});
      }
      if (layerGroup.max_zoom){
        opts = Object.assign(opts, {maxNativeZoom: layerGroup.max_zoom})
      }
      L.tileLayer(baseUrl + global_id + '/layers/' + layerGroup.id + '/{z}/{x}_{y}.png', opts).addTo(group);
      layers.push(group);
      group.addTo(map);
      if (name === "") { name = "top"; }
      overlayMaps[name] = group;
    } else {
      if (images[name]) {
        images[name].forEach(function(image) {
	        if (image.bounds){
            opts = Object.assign(opts, {bounds: worldBounds(image.bounds)});
          }
          if (image.max_zoom){
	          opts = Object.assign(opts, {maxNativeZoom: image.max_zoom})
          }
	        L.tileLayer(baseUrl + global_id + '/' + image.id + '/{z}/{x}_{y}.png', opts).addTo(group);
        });
        layers.push(group);
        group.addTo(map);
        if (name === "") { name = "top"; }
        overlayMaps[name] = group;
      }
    }
  });

  var spotsLayer = L.layerGroup();
  map.addLayer(spotsLayer);
  loadMarkers();

  L.control.surfaceScale({ imperial: false, length: length }).addTo(map);

  //L.control.layers(baseMaps, overlayMaps).addTo(map);
  L.control.opacityLayers(baseMaps, overlayMaps).addTo(map);
  if (bounds){
    map.fitBounds(bounds);
  } else {
    map.setView(map.unproject([256 / 2, 256 / 2], 0), zoom);
  }
  map.addControl(new L.Control.Fullscreen());

  function loadMarkers() {
      var url = resourceUrl + '/spots.json';
      $.get(url, {}, function(data){
        spotsLayer.clearLayers();
	      $(data).each(function(){
		      var spot = this; 
          var pos = world2latLng([spot.world_x, spot.world_y]);
          //var options = { draggable: true, color: 'blue', fillColor: '#f03', fillOpacity: 0.5, radius: 200 };
          var options = { draggable: true, title: spot['name'] };
          var marker = new L.marker(pos, options).addTo(spotsLayer);
          var popupContent = [];
          popupContent.push("<nobr>" + spot['name_with_id'] + "</nobr>");
          popupContent.push("<nobr>coordinate: (" + spot['world_x'] + ", " + spot["world_y"] + ")</nobr>");
          if (spot['attachment_file_id']){
            var image_url = resourceUrl + '/images/' + spot['attachment_file_id'];
            popupContent.push("<nobr>image: <a href=" + image_url + ">" + spot['attachment_file_name'] +  "</a>"+ "</nobr>");
          }
          if (spot['target_uid']){
            popupContent.push("<nobr>link: " + spot['target_link'] +  "</nobr>");
          }
          marker.bindPopup(popupContent.join("<br/>"), {
            maxWidth: "auto",
          });  
	      });
      });
  }

  var marker;
  var toolbarAction = L.Toolbar2.Action.extend({
	  options: {
	    toolbarIcon: {
		    html: '<svg class="svg-icons"><use xlink:href="#restore"></use><symbol id="restore" viewBox="0 0 18 18"><path d="M18 7.875h-1.774c-0.486-3.133-2.968-5.615-6.101-6.101v-1.774h-2.25v1.774c-3.133 0.486-5.615 2.968-6.101 6.101h-1.774v2.25h1.774c0.486 3.133 2.968 5.615 6.101 6.101v1.774h2.25v-1.774c3.133-0.486 5.615-2.968 6.101-6.101h1.774v-2.25zM13.936 7.875h-1.754c-0.339-0.959-1.099-1.719-2.058-2.058v-1.754c1.89 0.43 3.381 1.921 3.811 3.811zM9 10.125c-0.621 0-1.125-0.504-1.125-1.125s0.504-1.125 1.125-1.125c0.621 0 1.125 0.504 1.125 1.125s-0.504 1.125-1.125 1.125zM7.875 4.064v1.754c-0.959 0.339-1.719 1.099-2.058 2.058h-1.754c0.43-1.89 1.921-3.381 3.811-3.811zM4.064 10.125h1.754c0.339 0.959 1.099 1.719 2.058 2.058v1.754c-1.89-0.43-3.381-1.921-3.811-3.811zM10.125 13.936v-1.754c0.959-0.339 1.719-1.099 2.058-2.058h1.754c-0.43 1.89-1.921 3.381-3.811 3.811z"></path></symbol></svg>',
		    tooltip: 'Add spot'
	    }
	  },
	  addHooks: function (){
	      if(marker !== undefined){
		      map.removeLayer(marker);
	      }
	      var pos = map.getCenter();
	      var icon = L.icon({
		      iconUrl: 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAACMAAAAjCAYAAAAe2bNZAAAAAXNSR0IArs4c6QAAAAZiS0dEAP8A/wD/oL2nkwAAAAlwSFlzAAALEwAACxMBAJqcGAAAAHVJREFUWMPt1rENgDAMRNEPi3gERmA0RmAERgmjsAEjhMY0dOBIWHCWTulOL5UN8VmACpRoUdcAU1v19SQaYYQRRhhhhMmIMV//9WGuG/xudmA6C+YApGUGgNF1b0KKjithhBFGGGGE+Rtm9XfL8CHzS8340hzaXWaR1yQVAAAAAABJRU5ErkJggg==',
		      iconSize:     [32, 32],
		      iconAnchor:   [16, 16]
	      });
        var world = latLng2world(pos);
	      marker = new L.marker(pos,{icon: icon, draggable:true}).addTo(map);
	      var popupContent = '<form role="form" id="addspot-form" class="form" enctype="multipart/form-data">' +
	        '<div class="form-group">' +
	        '<label class="control-label">Name:</label>' +
	        '<input type="string" placeholder="untitled spot" id="name"/>' +
	        '</div>' +
	        '<div class="form-group">' +
	        '<label class="control-label">link ID:</label>' +
	        '<input type="string" placeholder="type here" id="target_uid"/>' +
	        '</div>' +
	        '<div class="form-group">' +
	        '<div style="text-align:center;">' +
	        '<button type="submit">Save</button></div>' +
	        '</div>' +
	        '</form>';
        marker.bindPopup(popupContent, {
			    maxWidth: "auto",
		    }).openPopup();
        $('body').on('submit', '#addspot-form', mySubmitFunction);
        function mySubmitFunction(e){
		      e.preventDefault();
		      console.log("didnt submit");
		      var form = document.querySelector('#addspot-form');
          var ll = marker.getLatLng();
          var world = latLng2world(ll);
          var url = resourceUrl + '/spots.json';
		      $.ajax(url,{
			      type: 'POST',
				    data: {spot:{name: form['name'].value, target_uid: form['target_uid'].value, world_x: world[0], world_y: world[1]}},
			      beforeSend: function(e) {console.log('saving...')},
			      complete: function(e){ 
				      marker.remove();
				      loadMarkers();
			      },
			      error: function(e) {console.log(e)}
		      })
        }
	  }
  });
  new L.Toolbar2.Control({
    position: 'topleft',
    actions: [toolbarAction]
  }).addTo(map);
  surfaceMap = map;
}
