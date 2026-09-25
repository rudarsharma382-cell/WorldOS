// WorldOS 3D Mapbox GL Engine Manager
window.WorldOSMapboxEngine = {
  map: null,
  markers: [],
  onMarkerClickCallback: null,
  onCameraChangedCallback: null,
  onLocationSelectedCallback: null,
  userInteracting: false,
  autoRotate: true,
  autoRotateAnimation: null,

  init: function(containerId, accessToken, onMarkerClickCb, onCameraChangedCb, onLocationSelectedCb) {
    if (typeof mapboxgl === 'undefined') {
      console.error('Mapbox GL JS is not loaded yet.');
      return;
    }

    if (onMarkerClickCb) this.onMarkerClickCallback = onMarkerClickCb;
    if (onCameraChangedCb) this.onCameraChangedCallback = onCameraChangedCb;
    if (onLocationSelectedCb) this.onLocationSelectedCallback = onLocationSelectedCb;

    mapboxgl.accessToken = accessToken || 'YOUR_MAPBOX_ACCESS_TOKEN';

    const self = this;

    const setupMap = function() {
      const container = document.getElementById(containerId);
      if (!container) {
        setTimeout(setupMap, 50);
        return;
      }

      // Ensure container expands to 100% of parent screen viewport with explicit dark background
      container.style.width = '100vw';
      container.style.height = '100vh';
      container.style.position = 'absolute';
      container.style.top = '0px';
      container.style.left = '0px';
      container.style.margin = '0px';
      container.style.padding = '0px';
      container.style.border = 'none';
      container.style.backgroundColor = '#000000';

      if (self.map) {
        if (self.map.getContainer() === container && document.body.contains(container)) {
          self.map.resize();
          return;
        } else {
          try {
            self.map.remove();
          } catch(e) {
            console.warn('Map removal warning:', e);
          }
          self.map = null;
        }
      }

      try {
        self.map = new mapboxgl.Map({
          container: containerId,
          style: 'mapbox://styles/mapbox/satellite-streets-v12',
          projection: 'globe',
          center: [78.9629, 20.5937],
          zoom: 1.8,
          pitch: 0,
          bearing: 0,
          attributionControl: false,
          minZoom: 1.2,
          maxZoom: 16.0,
          maxPitch: 75,
          renderWorldCopies: true,
          pitchWithRotate: true,      // UNLOCKED: Re-enable pitch on right-click drag or two-finger swipe
          dragRotate: true,           // UNLOCKED: Re-enable camera rotation and tilting
          touchPitch: true,           // UNLOCKED: Re-enable touch pitch gestures
          dragPan: {
            inertia: false,
            linearity: 0.25,
            maxSpeed: 1400
          }
        });

        // UNLOCKED: Max pitch set to 75 to reveal 3D DEM terrain ridges
        self.map.setMaxPitch(75);
        self.map.setMinPitch(0);
        if (self.map.keyboard) {
          self.map.keyboard.enable();
        }

        // Dynamic Pitch on Zoom: Tilt up for mountains on zoom-in, level back to 0 on space orbit zoom-out
        self.map.on('zoom', () => {
          if (!self.map || self.userInteracting) return;
          const z = self.map.getZoom();
          if (z >= 7.0 && self.map.getPitch() < 30) {
            self.map.easeTo({ pitch: 55, duration: 400 });
          } else if (z <= 3.0 && self.map.getPitch() > 5) {
            self.map.easeTo({ pitch: 0, duration: 400 });
          }
        });
      } catch (err) {
        console.error('Failed to instantiate Mapbox GL Map:', err);
        return;
      }

      self.map.on('error', (e) => {
        console.error('Mapbox runtime error:', e);
      });

      // Strict user gesture listeners to kill auto-rotation instantly
      const stopAllSpin = function() {
        if (self.autoRotateAnimation) {
          cancelAnimationFrame(self.autoRotateAnimation);
          self.autoRotateAnimation = null;
        }
        self.autoRotate = false;
        self.userInteracting = true;
      };

      self.map.on('mousedown', stopAllSpin);
      self.map.on('touchstart', stopAllSpin);
      self.map.on('wheel', stopAllSpin);
      self.map.on('dragstart', stopAllSpin);

      // ResizeObserver continuously keeps WebGL viewport synchronized with container dimensions
      if (window.ResizeObserver) {
        const ro = new ResizeObserver(() => {
          if (self.map) {
            self.map.resize();
          }
        });
        ro.observe(container);
      }

      const applyStyleSettings = function() {
        if (!self.map) return;

        // 1. Set Fog to pure dark void (Erasing milky smog layer)
        self.map.setFog({
          'color': '#000000',
          'high-color': '#020611',
          'space-color': '#000000',
          'horizon-blend': 0.0,
          'star-intensity': 0.9
        });

        // 2. Remove default sun glare / ambient white wash
        if (self.map.setLight) {
          self.map.setLight({
            anchor: 'viewport',
            color: '#ffffff',
            intensity: 0.35 // Lowers specular blowout on landmasses
          });
        }

        // 3. Add Realistic 3D Terrain Elevation (DEM) with tuned contrast
        if (!self.map.getSource('mapbox-dem')) {
          self.map.addSource('mapbox-dem', {
            type: 'raster-dem',
            url: 'mapbox://mapbox.mapbox-terrain-dem-v1',
            tileSize: 512,
            maxzoom: 14
          });
          self.map.setTerrain({ source: 'mapbox-dem', exaggeration: 1.1 });
        }

        // Load commercial airliner silhouette icon, ship chevron icon, and camera reticle icon
        self.createAircraftIcon('airplane-icon', '#38BDF8', '#0284C7');
        self.createChevronIcon('ship-chevron', '#10B981', '#047857');
        self.createCameraIcon('camera-reticle', '#22C55E', '#15803D');

        // Initialize GeoJSON sources for telemetry layers
        self.initGeoJsonSources();

        // Start subtle globe auto-rotation loop if enabled
        if (self.autoRotate) {
          self.startAutoRotation();
        }

        // Trigger immediate and staggered WebGL viewport resizes
        self.map.resize();
        [50, 150, 300, 600, 1200].forEach(ms => setTimeout(() => { if (self.map) self.map.resize(); }, ms));
      };

      if (self.map.isStyleLoaded()) {
        applyStyleSettings();
      } else {
        self.map.once('style.load', applyStyleSettings);
      }

      // Handle user camera interactions
      self.map.on('mouseup', () => { self.userInteracting = false; });
      self.map.on('touchend', () => { self.userInteracting = false; });
      self.map.on('moveend', () => {
        if (self.map && self.onCameraChangedCallback) {
          const center = self.map.getCenter();
          self.onCameraChangedCallback(center.lat, center.lng, self.map.getZoom());
        }
      });

      // Global map tap handler for location selection
      self.map.on('click', (e) => {
        const layers = ['flights-layer', 'fires-heat-layer', 'quakes-layer', 'ships-layer', 'general-events-layer'];
        const features = self.map.queryRenderedFeatures(e.point, { layers: layers });
        if (!features || features.length === 0) {
          stopAllSpin();
          if (self.onLocationSelectedCallback) {
            self.onLocationSelectedCallback(e.lngLat.lat, e.lngLat.lng);
          }
        }
      });
    };

    setupMap();
  },

  createAircraftIcon: function(name, fillColor, shadowColor) {
    if (!this.map) return;
    const size = 32;
    const canvas = document.createElement('canvas');
    canvas.width = size;
    canvas.height = size;
    const ctx = canvas.getContext('2d');

    ctx.fillStyle = fillColor;
    ctx.shadowColor = shadowColor || '#0284C7';
    ctx.shadowBlur = 6;

    // Drawing top-down commercial airliner silhouette vector
    ctx.beginPath();
    ctx.moveTo(16, 2);
    ctx.bezierCurveTo(18, 6, 18, 10, 18, 13);
    ctx.lineTo(31, 19);
    ctx.lineTo(31, 21);
    ctx.lineTo(18, 18);
    ctx.lineTo(18, 25);
    ctx.lineTo(24, 28);
    ctx.lineTo(24, 30);
    ctx.lineTo(16, 28);
    ctx.lineTo(8, 30);
    ctx.lineTo(8, 28);
    ctx.lineTo(14, 25);
    ctx.lineTo(14, 18);
    ctx.lineTo(1, 21);
    ctx.lineTo(1, 19);
    ctx.lineTo(14, 13);
    ctx.bezierCurveTo(14, 10, 14, 6, 16, 2);
    ctx.closePath();
    ctx.fill();

    const imageData = ctx.getImageData(0, 0, size, size);
    if (!this.map.hasImage(name)) {
      this.map.addImage(name, imageData, { pixelRatio: 2 });
    }
  },

  createChevronIcon: function(name, fillColor, shadowColor) {
    if (!this.map) return;
    const size = 32;
    const canvas = document.createElement('canvas');
    canvas.width = size;
    canvas.height = size;
    const ctx = canvas.getContext('2d');

    ctx.fillStyle = fillColor;
    ctx.shadowColor = shadowColor;
    ctx.shadowBlur = 6;
    ctx.beginPath();
    ctx.moveTo(16, 4);
    ctx.lineTo(26, 26);
    ctx.lineTo(16, 20);
    ctx.lineTo(6, 26);
    ctx.closePath();
    ctx.fill();

    const imageData = ctx.getImageData(0, 0, size, size);
    if (!this.map.hasImage(name)) {
      this.map.addImage(name, imageData, { pixelRatio: 2 });
    }
  },

  createCameraIcon: function(name, fillColor, shadowColor) {
    if (!this.map) return;
    const size = 32;
    const canvas = document.createElement('canvas');
    canvas.width = size;
    canvas.height = size;
    const ctx = canvas.getContext('2d');

    ctx.strokeStyle = fillColor || '#22C55E';
    ctx.lineWidth = 2.5;
    ctx.shadowColor = shadowColor || '#15803D';
    ctx.shadowBlur = 8;

    // Viewfinder box frame
    const margin = 6;
    const len = 7;
    ctx.beginPath();
    // Top-Left corner
    ctx.moveTo(margin, margin + len);
    ctx.lineTo(margin, margin);
    ctx.lineTo(margin + len, margin);

    // Top-Right corner
    ctx.moveTo(size - margin - len, margin);
    ctx.lineTo(size - margin, margin);
    ctx.lineTo(size - margin, margin + len);

    // Bottom-Right corner
    ctx.moveTo(size - margin, size - margin - len);
    ctx.lineTo(size - margin, size - margin);
    ctx.lineTo(size - margin - len, size - margin);

    // Bottom-Left corner
    ctx.moveTo(margin + len, size - margin);
    ctx.lineTo(margin, size - margin);
    ctx.lineTo(margin, size - margin - len);
    ctx.stroke();

    // Center dot
    ctx.fillStyle = fillColor || '#22C55E';
    ctx.beginPath();
    ctx.arc(size / 2, size / 2, 3, 0, 2 * Math.PI);
    ctx.fill();

    const imageData = ctx.getImageData(0, 0, size, size);
    if (!this.map.hasImage(name)) {
      this.map.addImage(name, imageData, { pixelRatio: 2 });
    }
  },

  initGeoJsonSources: function() {
    if (!this.map) return;

    // 1. Flight Layer Source (Top-Down Commercial Airliner Silhouettes)
    if (!this.map.getSource('worldos-flights')) {
      this.map.addSource('worldos-flights', {
        type: 'geojson',
        data: { type: 'FeatureCollection', features: [] }
      });

      this.map.addLayer({
        id: 'flights-layer',
        type: 'symbol',
        source: 'worldos-flights',
        layout: {
          'icon-image': 'airplane-icon',
          'icon-size': 0.65,
          'icon-rotate': ['get', 'heading'],
          'icon-rotation-alignment': 'map',
          'icon-allow-overlap': true,
          'icon-ignore-placement': true
        }
      });
    }

    // 2. Thermal / NASA Wildfire Layer Source (Amber Heatmap Pulse Circle Layer)
    if (!this.map.getSource('worldos-fires')) {
      this.map.addSource('worldos-fires', {
        type: 'geojson',
        data: { type: 'FeatureCollection', features: [] }
      });

      this.map.addLayer({
        id: 'fires-heat-layer',
        type: 'circle',
        source: 'worldos-fires',
        paint: {
          'circle-radius': 8,
          'circle-color': '#F59E0B',
          'circle-opacity': 0.85,
          'circle-stroke-width': 2,
          'circle-stroke-color': '#FEF08A'
        }
      });
    }

    // 3. Seismic / USGS Quakes Layer Source (Expanding Tactical Reticles)
    if (!this.map.getSource('worldos-quakes')) {
      this.map.addSource('worldos-quakes', {
        type: 'geojson',
        data: { type: 'FeatureCollection', features: [] }
      });

      this.map.addLayer({
        id: 'quakes-layer',
        type: 'circle',
        source: 'worldos-quakes',
        paint: {
          'circle-radius': 10,
          'circle-color': '#EF4444',
          'circle-opacity': 0.85,
          'circle-stroke-width': 2.5,
          'circle-stroke-color': '#FCA5A5'
        }
      });
    }

    // 4. AIS Stream Maritime Ships Source
    if (!this.map.getSource('worldos-ships')) {
      this.map.addSource('worldos-ships', {
        type: 'geojson',
        data: { type: 'FeatureCollection', features: [] }
      });

      this.map.addLayer({
        id: 'ships-layer',
        type: 'symbol',
        source: 'worldos-ships',
        layout: {
          'icon-image': 'ship-chevron',
          'icon-size': 0.55,
          'icon-rotate': ['get', 'heading'],
          'icon-rotation-alignment': 'map',
          'icon-allow-overlap': true,
          'icon-ignore-placement': true
        }
      });
    }

    // 5. General Events / Telemetry Layer Source
    if (!this.map.getSource('worldos-general')) {
      this.map.addSource('worldos-general', {
        type: 'geojson',
        data: { type: 'FeatureCollection', features: [] }
      });

      this.map.addLayer({
        id: 'general-events-layer',
        type: 'circle',
        source: 'worldos-general',
        paint: {
          'circle-radius': 7,
          'circle-color': [
            'match',
            ['get', 'severity'],
            'CRITICAL', '#EF4444',
            'HIGH', '#F97316',
            'MEDIUM', '#F59E0B',
            '#38BDF8'
          ],
          'circle-stroke-width': 2,
          'circle-stroke-color': '#FFFFFF'
        }
      });
    }

    // 6. Live CCTV & Surveillance Camera Reticle Layer Source
    if (!this.map.getSource('worldos-cameras')) {
      this.map.addSource('worldos-cameras', {
        type: 'geojson',
        data: { type: 'FeatureCollection', features: [] }
      });

      this.map.addLayer({
        id: 'cameras-layer',
        type: 'symbol',
        source: 'worldos-cameras',
        layout: {
          'icon-image': 'camera-reticle',
          'icon-size': 0.85,
          'icon-allow-overlap': true,
          'icon-ignore-placement': true
        }
      });
    }

    // Interactive Hit-Testing: Clicking GeoJSON feature halts auto-spin and triggers Dart callback with metadata
    const layers = ['flights-layer', 'fires-heat-layer', 'quakes-layer', 'ships-layer', 'general-events-layer', 'cameras-layer'];
    const self = this;

    layers.forEach(layerId => {
      self.map.on('click', layerId, (e) => {
        if (self.autoRotateAnimation) {
          cancelAnimationFrame(self.autoRotateAnimation);
          self.autoRotateAnimation = null;
        }
        self.autoRotate = false;
        self.userInteracting = true;

        if (e.features && e.features.length > 0) {
          const props = e.features[0].properties;
          if (self.onMarkerClickCallback) {
            self.onMarkerClickCallback(JSON.stringify(props));
          }
        }
      });

      self.map.on('mouseenter', layerId, () => {
        self.map.getCanvas().style.cursor = 'pointer';
      });
      self.map.on('mouseleave', layerId, () => {
        self.map.getCanvas().style.cursor = '';
      });
    });
  },

  setLayerVisibility: function(layerKey, isVisible) {
    if (!this.map) return;
    const layerIdMap = {
      'ALL': ['flights-layer', 'fires-heat-layer', 'quakes-layer', 'ships-layer', 'general-events-layer', 'cameras-layer'],
      'AIRCRAFT': ['flights-layer'],
      'WILDFIRE': ['fires-heat-layer'],
      'EARTHQUAKE': ['quakes-layer'],
      'SHIP': ['ships-layer'],
      'CAMERA': ['cameras-layer'],
      'WEATHER': ['general-events-layer'],
      'SATELLITE': ['general-events-layer'],
      'STORM': ['general-events-layer']
    };

    const targetLayers = layerIdMap[layerKey] || [layerKey];
    targetLayers.forEach(id => {
      if (this.map.getLayer(id)) {
        this.map.setLayoutProperty(id, 'visibility', isVisible ? 'visible' : 'none');
      }
    });
  },

  zoomIn: function() {
    if (this.map) {
      this.map.zoomIn({ duration: 400 });
    }
  },

  zoomOut: function() {
    if (this.map) {
      this.map.zoomOut({ duration: 400 });
    }
  },

  resetView: function() {
    if (!this.map) return;
    if (this.autoRotateAnimation) {
      cancelAnimationFrame(this.autoRotateAnimation);
      this.autoRotateAnimation = null;
    }
    this.autoRotate = false;
    this.userInteracting = true;

    this.map.flyTo({
      center: [78.9629, 20.5937],
      zoom: 1.8,
      pitch: 0,
      bearing: 0,
      duration: 1400,
      essential: true
    });
  },

  flyToCoordinates: function(lon, lat, targetZoom = 11.5, targetPitch = 60) {
    if (!this.map) return;
    if (this.autoRotateAnimation) {
      cancelAnimationFrame(this.autoRotateAnimation);
      this.autoRotateAnimation = null;
    }
    this.autoRotate = false;
    this.userInteracting = true;

    this.map.flyTo({
      center: [lon, lat],
      zoom: targetZoom,      // Dive straight into the location (streets/peaks visible)
      pitch: targetPitch,    // 60-degree tilt to expose 3D topography
      bearing: -15,          // Slight tactical angle
      speed: 1.1,
      curve: 1.3,
      essential: true
    });
  },

  flyTo: function(lat, lon, zoom, pitch, bearing, speed, curve) {
    if (!this.map) return;
    if (this.autoRotateAnimation) {
      cancelAnimationFrame(this.autoRotateAnimation);
      this.autoRotateAnimation = null;
    }
    this.autoRotate = false;
    this.userInteracting = true;

    const targetZoom = zoom !== undefined && zoom !== null ? Math.min(Math.max(zoom, 1.2), 16.0) : 11.5;
    const targetPitch = pitch !== undefined && pitch !== null ? Math.min(Math.max(pitch, 0), 75) : 60;

    this.map.flyTo({
      center: [lon, lat],
      zoom: targetZoom,
      pitch: targetPitch,
      bearing: bearing !== undefined && bearing !== null ? bearing : -15,
      speed: speed !== undefined && speed !== null ? speed : 1.1,
      curve: curve !== undefined && curve !== null ? curve : 1.3,
      essential: true
    });
  },

  updateMarkers: function(markersJsonString) {
    if (!this.map) return;
    try {
      const markers = typeof markersJsonString === 'string' ? JSON.parse(markersJsonString) : markersJsonString;
      
      const flightFeatures = [];
      const fireFeatures = [];
      const quakeFeatures = [];
      const shipFeatures = [];
      const cameraFeatures = [];
      const generalFeatures = [];

      markers.forEach(m => {
        const feature = {
          type: 'Feature',
          geometry: {
            type: 'Point',
            coordinates: [m.lng, m.lat]
          },
          properties: {
            id: m.id || m.label,
            title: m.label || 'TARGET TELEMETRY',
            type: m.type || 'GENERAL',
            severity: m.severity || 'LOW',
            heading: m.heading || 0,
            lat: m.lat,
            lng: m.lng
          }
        };

        const typeUpper = (m.type || '').toUpperCase();
        if (typeUpper.includes('FLIGHT') || typeUpper.includes('AIRCRAFT') || typeUpper.includes('AVIATION')) {
          flightFeatures.push(feature);
        } else if (typeUpper.includes('FIRE') || typeUpper.includes('WILDFIRE') || typeUpper.includes('THERMAL')) {
          fireFeatures.push(feature);
        } else if (typeUpper.includes('QUAKE') || typeUpper.includes('EARTHQUAKE') || typeUpper.includes('SEISMIC')) {
          quakeFeatures.push(feature);
        } else if (typeUpper.includes('SHIP') || typeUpper.includes('MARITIME') || typeUpper.includes('VESSEL') || typeUpper.includes('AIS')) {
          shipFeatures.push(feature);
        } else if (typeUpper.includes('CAMERA') || typeUpper.includes('CCTV') || typeUpper.includes('SURVEILLANCE') || typeUpper.includes('WEBCAM')) {
          cameraFeatures.push(feature);
        } else {
          generalFeatures.push(feature);
        }
      });

      if (this.map.getSource('worldos-flights')) {
        this.map.getSource('worldos-flights').setData({ type: 'FeatureCollection', features: flightFeatures });
      }
      if (this.map.getSource('worldos-fires')) {
        this.map.getSource('worldos-fires').setData({ type: 'FeatureCollection', features: fireFeatures });
      }
      if (this.map.getSource('worldos-quakes')) {
        this.map.getSource('worldos-quakes').setData({ type: 'FeatureCollection', features: quakeFeatures });
      }
      if (this.map.getSource('worldos-ships')) {
        this.map.getSource('worldos-ships').setData({ type: 'FeatureCollection', features: shipFeatures });
      }
      if (this.map.getSource('worldos-cameras')) {
        this.map.getSource('worldos-cameras').setData({ type: 'FeatureCollection', features: cameraFeatures });
      }
      if (this.map.getSource('worldos-general')) {
        this.map.getSource('worldos-general').setData({ type: 'FeatureCollection', features: generalFeatures });
      }
    } catch (e) {
      console.error('Error updating Mapbox markers:', e);
    }
  },

  startAutoRotation: function() {
    const secondsPerRotate = 240;
    const distancePerSecond = 360 / secondsPerRotate;
    const self = this;

    function rotate() {
      if (self.map && self.autoRotate && !self.userInteracting) {
        const center = self.map.getCenter();
        center.lng += distancePerSecond / 60;
        self.map.setCenter(center);
        self.autoRotateAnimation = requestAnimationFrame(rotate);
      } else {
        self.autoRotateAnimation = null;
      }
    }
    rotate();
  },

  setAutoRotate: function(enabled) {
    this.autoRotate = enabled;
    if (!enabled && this.autoRotateAnimation) {
      cancelAnimationFrame(this.autoRotateAnimation);
      this.autoRotateAnimation = null;
    } else if (enabled && !this.autoRotateAnimation) {
      this.startAutoRotation();
    }
  },

  resize: function() {
    if (this.map) {
      this.map.resize();
    }
  }
};

window.setWorldOSLayerVisibility = function(layerId, isVisible) {
  WorldOSMapboxEngine.setLayerVisibility(layerId, isVisible);
};

window.flyToCoordinates = function(lon, lat, targetZoom = 11.5, targetPitch = 60) {
  WorldOSMapboxEngine.flyToCoordinates(lon, lat, targetZoom, targetPitch);
};


