const express = require('express');
const https = require('https');
const bodyParser = require('body-parser');
const cors = require('cors');
const path = require('path');
const fs = require('fs');
const { createProxyMiddleware } = require('http-proxy-middleware');

const app = express();
const PORT = process.env.PORT || 3000;
const ORTHANC_URL = 'https://dentax.globalpearlventures.com:4000';

// SSL Configuration
const sslOptions = {
  key: fs.readFileSync('/etc/letsencrypt/live/dentax.globalpearlventures.com/privkey.pem'),
  cert: fs.readFileSync('/etc/letsencrypt/live/dentax.globalpearlventures.com/fullchain.pem'),
};

// CORS configuration for OHIF viewer
app.use(
  cors({
    origin: true,
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With', 'Accept'],
  })
);

app.use(bodyParser.json({ limit: '50mb' }));
app.use(bodyParser.urlencoded({ extended: true, limit: '50mb' }));

// Proxy middleware for Orthanc API calls with query parameter filtering
const orthancProxy = createProxyMiddleware({
  target: ORTHANC_URL,
  changeOrigin: true,
  secure: false,
  logLevel: 'debug',
  onProxyReq: (proxyReq, req, res) => {
    console.log(`Proxying ${req.method} ${req.url} to ${ORTHANC_URL}${req.url}`);

    // Filter out problematic query parameters for Orthanc
    if (req.url.includes('?')) {
      const [path, queryString] = req.url.split('?');
      const params = new URLSearchParams(queryString);

      // Remove parameters that Orthanc doesn't support
      params.delete('limit');
      params.delete('offset');
      params.delete('fuzzymatching');
      params.delete('includefield');

      // Rebuild the URL without problematic parameters
      const cleanQuery = params.toString();
      const cleanUrl = cleanQuery ? `${path}?${cleanQuery}` : path;

      console.log(`Original URL: ${req.url}`);
      console.log(`Cleaned URL: ${cleanUrl}`);

      // Update the proxy request path
      proxyReq.path = cleanUrl;
    }

    // Set appropriate headers based on endpoint
    if (req.url.includes('/dicom-web/')) {
      proxyReq.setHeader('Accept', 'application/dicom+json');
    } else if (req.url.includes('/wado')) {
      proxyReq.setHeader('Accept', 'application/dicom');
    } else {
      proxyReq.setHeader('Accept', 'application/json');
    }

    proxyReq.setHeader('User-Agent', 'OHIF-Viewer/3.0');
    proxyReq.removeHeader('accept-encoding');
  },
  onProxyRes: (proxyRes, req, res) => {
    console.log(`Proxy response: ${proxyRes.statusCode} for ${req.url}`);
    if (proxyRes.statusCode >= 400) {
      console.error(`Proxy error ${proxyRes.statusCode} for ${req.url}`);
      console.error(`Response headers:`, proxyRes.headers);
    }
    // Add CORS headers to proxy responses
    proxyRes.headers['Access-Control-Allow-Origin'] = '*';
    proxyRes.headers['Access-Control-Allow-Methods'] = 'GET, POST, PUT, DELETE, OPTIONS';
    proxyRes.headers['Access-Control-Allow-Headers'] =
      'Content-Type, Authorization, X-Requested-With, Accept';
    proxyRes.headers['Access-Control-Expose-Headers'] = 'Content-Length,Content-Range,Content-Type';
  },
  onError: (err, req, res) => {
    console.error(`Proxy error for ${req.url}:`, err);
    res.status(500).json({ error: 'Proxy error', message: err.message });
  },
});

// Handle problematic metadata endpoints that Orthanc doesn't support well
app.get('/dicom-web/studies/:studyUID/series/:seriesUID/metadata', async (req, res) => {
  const { studyUID, seriesUID } = req.params;

  console.log(`Metadata request for study: ${studyUID}, series: ${seriesUID}`);

  try {
    // Instead of using the problematic metadata endpoint, get instances and their metadata
    const instancesResponse = await fetch(
      `${ORTHANC_URL}/dicom-web/studies/${studyUID}/series/${seriesUID}/instances`,
      {
        headers: { Accept: 'application/dicom+json' },
      }
    );

    if (instancesResponse.ok) {
      const instances = await instancesResponse.json();
      console.log(`Found ${instances.length} instances for series ${seriesUID}`);

      // Return the instances data which contains the metadata OHIF needs
      res.set('Access-Control-Allow-Origin', '*');
      res.set('Content-Type', 'application/dicom+json');
      res.json(instances);
    } else {
      console.error(`Instances request failed: ${instancesResponse.status}`);
      // Fallback: return empty array instead of error
      res.set('Access-Control-Allow-Origin', '*');
      res.set('Content-Type', 'application/dicom+json');
      res.json([]);
    }
  } catch (error) {
    console.error('Metadata endpoint error:', error);
    // Return empty array instead of error to prevent OHIF from breaking
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Content-Type', 'application/dicom+json');
    res.json([]);
  }
});

// Handle study-level metadata requests
app.get('/dicom-web/studies/:studyUID/metadata', async (req, res) => {
  const { studyUID } = req.params;

  console.log(`Study metadata request for: ${studyUID}`);

  try {
    // Get all series for the study
    const seriesResponse = await fetch(`${ORTHANC_URL}/dicom-web/studies/${studyUID}/series`, {
      headers: { Accept: 'application/dicom+json' },
    });

    if (seriesResponse.ok) {
      const series = await seriesResponse.json();
      console.log(`Found ${series.length} series for study ${studyUID}`);

      // Return the series data as study metadata
      res.set('Access-Control-Allow-Origin', '*');
      res.set('Content-Type', 'application/dicom+json');
      res.json(series);
    } else {
      console.error(`Series request failed: ${seriesResponse.status}`);
      res.set('Access-Control-Allow-Origin', '*');
      res.set('Content-Type', 'application/dicom+json');
      res.json([]);
    }
  } catch (error) {
    console.error('Study metadata endpoint error:', error);
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Content-Type', 'application/dicom+json');
    res.json([]);
  }
});

// WADO-URI proxy with Orthanc-specific parameter transformation
app.get('/wado', (req, res) => {
  // Orthanc WADO-URI endpoint is at /wado with specific parameters
  // Transform OHIF WADO-URI requests to Orthanc format
  const orthancWadoUrl = `${ORTHANC_URL}/wado?${req.url.split('?')[1] || ''}`;

  console.log(`WADO-URI request: ${req.url}`);
  console.log(`Proxying to: ${orthancWadoUrl}`);

  fetch(orthancWadoUrl, {
    method: req.method,
    headers: {
      Accept: req.headers.accept || 'application/dicom',
      'User-Agent': 'OHIF-Viewer/3.0',
    },
  })
    .then(response => {
      // Set response headers
      res.set('Access-Control-Allow-Origin', '*');
      res.set('Content-Type', response.headers.get('content-type') || 'application/dicom');
      res.status(response.status);

      return response.arrayBuffer();
    })
    .then(buffer => {
      res.send(Buffer.from(buffer));
    })
    .catch(error => {
      console.error('WADO-URI proxy error:', error);
      res.status(500).json({ error: 'WADO-URI proxy error', message: error.message });
    });
});

// Proxy all Orthanc API requests
app.use('/dicom-web', orthancProxy);
app.use('/orthanc', orthancProxy);
app.use('/studies', orthancProxy);
app.use('/series', orthancProxy);
app.use('/instances', orthancProxy);
app.use('/patients', orthancProxy);
app.use('/modalities', orthancProxy);
app.use('/peers', orthancProxy);

// API endpoint for OHIF configuration
app.get('/api/config', (req, res) => {
  // Set proper headers to ensure this config is used
  res.set({
    'Content-Type': 'application/json',
    'Cache-Control': 'no-cache, no-store, must-revalidate',
    Pragma: 'no-cache',
    Expires: '0',
  });

  const config = {
    routerBasename: '/',
    modes: ['@ohif/mode-longitudinal'],
    extensions: [],
    showStudyBrowser: false,
    dataSources: [
      {
        namespace: '@ohif/extension-default.dataSourcesModule.dicomweb',
        configuration: {
          friendlyName: 'Orthanc DICOM Server',
          name: 'orthanc',
          wadoUriRoot: 'https://dentax.globalpearlventures.com:3000/wado',
          qidoRoot: 'https://dentax.globalpearlventures.com:3000/dicom-web',
          wadoRoot: 'https://dentax.globalpearlventures.com:3000/dicom-web',
          qidoSupportsIncludeField: false, // Disable include field support
          imageRendering: 'wadouri', // Force WADO-URI for all images
          thumbnailRendering: 'wadouri', // Force WADO-URI for thumbnails
          enableStudyLazyLoad: false, // Disable lazy loading to prevent complex queries
          supportsFuzzyMatching: false, // Disable fuzzy matching
          supportsWildcard: false, // Disable wildcard queries
          acceptHeader: 'application/dicom+json',
          supportsInstanceMetadata: false, // Completely disable instance metadata
          staticWado: false,
          dicomUploadEnabled: false,
          // Orthanc-specific configurations to minimize complex queries
          omitQuotationForMultipartRequest: true,
          bulkDataURI: {
            enabled: false, // Disable bulk data URI
          },
          requestOptions: {
            mode: 'cors',
            credentials: 'omit',
          },
          // Disable advanced QIDO features that Orthanc doesn't support well
          supportsStow: false,
          supportsMetadata: false,
        },
      },
    ],
    defaultDataSourceName: 'orthanc',
    maxNumberOfWebWorkers: 1, // Reduce workers to minimize concurrent requests
    omitQuotationForMultipartRequest: true,
    // Disable some advanced OHIF features that might cause issues
    investigationalUseDialog: {
      option: 'never',
    },
  };

  res.json(config);
});

// Alternative config endpoints that OHIF might look for
app.get('/config', (req, res) => {
  res.redirect('/api/config');
});

// Override any config file requests to use our custom config
app.get('/config/:configName', (req, res) => {
  res.redirect('/api/config');
});

app.get('/app-config.js', (req, res) => {
  res.set({
    'Content-Type': 'application/javascript',
    'Cache-Control': 'no-cache, no-store, must-revalidate',
  });

  const configJS = `
window.config = {
  routerBasename: '/',
  modes: ['@ohif/mode-longitudinal'],
  extensions: [],
  showStudyBrowser: false,
  dataSources: [{
    namespace: '@ohif/extension-default.dataSourcesModule.dicomweb',
    sourceName: 'dicomweb',
    configuration: {
      friendlyName: 'Orthanc DICOM Server',
      name: 'orthanc',
      wadoUriRoot: 'https://dentax.globalpearlventures.com:3000/wado',
      qidoRoot: 'https://dentax.globalpearlventures.com:3000/dicom-web',
      wadoRoot: 'https://dentax.globalpearlventures.com:3000/dicom-web',
      qidoSupportsIncludeField: false,
      imageRendering: 'wadouri',
      thumbnailRendering: 'wadouri',
      enableStudyLazyLoad: false,
      supportsFuzzyMatching: false,
      supportsWildcard: false,
      supportsInstanceMetadata: false,
      staticWado: false,
      dicomUploadEnabled: false,
      omitQuotationForMultipartRequest: true,
      bulkDataURI: {
        enabled: false,
      },
      requestOptions: {
        mode: 'cors',
        credentials: 'omit',
      },
      supportsStow: false,
      supportsMetadata: false,
    },
  }],
  defaultDataSourceName: 'dicomweb',
  maxNumberOfWebWorkers: 1,
  omitQuotationForMultipartRequest: true,
  investigationalUseDialog: {
    option: 'never',
  },
  httpErrorHandler: error => {
    console.error('HTTP Error:', error);
  },
};
`;

  res.send(configJS);
});

// Health check endpoint
app.get('/api/health', (req, res) => {
  res.json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    orthanc: ORTHANC_URL,
    port: PORT,
  });
});

// Test endpoint to check Orthanc connectivity
app.get('/api/test-orthanc', async (req, res) => {
  try {
    // Test basic Orthanc connectivity first
    const systemResponse = await fetch(`${ORTHANC_URL}/system`, {
      method: 'GET',
      headers: {
        Accept: 'application/json',
      },
    });

    if (!systemResponse.ok) {
      return res.status(systemResponse.status).json({
        status: 'error',
        message: `Orthanc system endpoint returned ${systemResponse.status}`,
      });
    }

    // Test DICOM-Web endpoint
    const dicomWebResponse = await fetch(`${ORTHANC_URL}/dicom-web/studies`, {
      method: 'GET',
      headers: {
        Accept: 'application/dicom+json',
      },
    });

    if (dicomWebResponse.ok) {
      const data = await dicomWebResponse.json();
      const systemData = await systemResponse.json();
      res.json({
        status: 'success',
        message: 'Orthanc connectivity test passed',
        studyCount: data.length,
        orthancSystem: systemData,
        dicomWebEnabled: true,
      });
    } else {
      const errorText = await dicomWebResponse.text();
      res.status(dicomWebResponse.status).json({
        status: 'error',
        message: `DICOM-Web endpoint returned ${dicomWebResponse.status}`,
        error: errorText,
        orthancSystem: await systemResponse.json(),
      });
    }
  } catch (error) {
    res.status(500).json({
      status: 'error',
      message: 'Failed to connect to Orthanc',
      error: error.message,
    });
  }
});

// Debug endpoint to check specific study data for OHIF
app.get('/api/debug-study/:studyUID', async (req, res) => {
  const { studyUID } = req.params;

  try {
    // Get study metadata
    const studyResponse = await fetch(
      `${ORTHANC_URL}/dicom-web/studies?StudyInstanceUID=${studyUID}`,
      {
        headers: { Accept: 'application/dicom+json' },
      }
    );

    // Get series metadata
    const seriesResponse = await fetch(`${ORTHANC_URL}/dicom-web/studies/${studyUID}/series`, {
      headers: { Accept: 'application/dicom+json' },
    });

    // Get instances for first series
    const seriesData = await seriesResponse.json();
    let instancesData = [];
    let instancesError = null;

    if (seriesData.length > 0) {
      const firstSeriesUID = seriesData[0]['0020000E'].Value[0];
      try {
        const instancesResponse = await fetch(
          `${ORTHANC_URL}/dicom-web/studies/${studyUID}/series/${firstSeriesUID}/instances`,
          {
            headers: { Accept: 'application/dicom+json' },
          }
        );

        if (instancesResponse.ok) {
          instancesData = await instancesResponse.json();
        } else {
          instancesError = await instancesResponse.json();
        }
      } catch (error) {
        instancesError = { error: error.message };
      }
    }

    res.json({
      study: await studyResponse.json(),
      series: seriesData,
      instances: instancesError || instancesData,
      instancesError: instancesError ? true : false,
      ohifUrl: `/viewer/dicomweb?StudyInstanceUIDs=${studyUID}`,
      config: {
        qidoRoot: 'https://dentax.globalpearlventures.com:3000/dicom-web',
        wadoRoot: 'https://dentax.globalpearlventures.com:3000/dicom-web',
      },
    });
  } catch (error) {
    res.status(500).json({
      error: 'Debug failed',
      message: error.message,
    });
  }
});

// Enhanced debug endpoint for Orthanc limitations
app.get('/api/debug-orthanc-study/:studyUID', async (req, res) => {
  const { studyUID } = req.params;

  try {
    console.log(`Enhanced debugging for study: ${studyUID}`);

    // Get study info from Orthanc API (not DICOM-Web)
    const orthancStudiesResponse = await fetch(`${ORTHANC_URL}/studies`, {
      headers: { Accept: 'application/json' },
    });
    const orthancStudies = await orthancStudiesResponse.json();

    // Find the study by UID
    let orthancStudyId = null;
    for (const studyId of orthancStudies) {
      const studyResponse = await fetch(`${ORTHANC_URL}/studies/${studyId}`, {
        headers: { Accept: 'application/json' },
      });
      const study = await studyResponse.json();
      if (study.MainDicomTags.StudyInstanceUID === studyUID) {
        orthancStudyId = studyId;
        break;
      }
    }

    if (!orthancStudyId) {
      return res.json({ error: 'Study not found in Orthanc' });
    }

    // Get complete study info
    const studyResponse = await fetch(`${ORTHANC_URL}/studies/${orthancStudyId}`, {
      headers: { Accept: 'application/json' },
    });
    const studyInfo = await studyResponse.json();

    // Get series info
    const seriesInfo = [];
    for (const seriesId of studyInfo.Series) {
      const seriesResponse = await fetch(`${ORTHANC_URL}/series/${seriesId}`, {
        headers: { Accept: 'application/json' },
      });
      const series = await seriesResponse.json();

      // Get instances for this series
      const instances = [];
      for (const instanceId of series.Instances) {
        const instanceResponse = await fetch(`${ORTHANC_URL}/instances/${instanceId}`, {
          headers: { Accept: 'application/json' },
        });
        const instance = await instanceResponse.json();
        instances.push({
          orthancId: instanceId,
          sopInstanceUID: instance.MainDicomTags.SOPInstanceUID,
          instanceNumber: instance.MainDicomTags.InstanceNumber,
        });
      }

      seriesInfo.push({
        orthancId: seriesId,
        seriesInstanceUID: series.MainDicomTags.SeriesInstanceUID,
        seriesNumber: series.MainDicomTags.SeriesNumber,
        modality: series.MainDicomTags.Modality,
        instances: instances,
      });
    }

    // Test WADO-URI URLs
    const wadoTests = [];
    if (seriesInfo.length > 0 && seriesInfo[0].instances.length > 0) {
      const firstSeries = seriesInfo[0];
      const firstInstance = firstSeries.instances[0];

      const wadoUrl = `${ORTHANC_URL}/wado?requestType=WADO&studyUID=${studyUID}&seriesUID=${firstSeries.seriesInstanceUID}&objectUID=${firstInstance.sopInstanceUID}&contentType=application/dicom`;

      try {
        const wadoResponse = await fetch(wadoUrl, {
          headers: { Accept: 'application/dicom' },
        });
        wadoTests.push({
          url: wadoUrl,
          status: wadoResponse.status,
          contentType: wadoResponse.headers.get('content-type'),
          size: wadoResponse.headers.get('content-length'),
        });
      } catch (error) {
        wadoTests.push({
          url: wadoUrl,
          error: error.message,
        });
      }
    }

    res.json({
      orthancStudyId,
      studyInfo: {
        patientName: studyInfo.PatientMainDicomTags.PatientName,
        patientId: studyInfo.PatientMainDicomTags.PatientID,
        studyDate: studyInfo.MainDicomTags.StudyDate,
        studyDescription: studyInfo.MainDicomTags.StudyDescription,
      },
      seriesCount: seriesInfo.length,
      series: seriesInfo,
      wadoTests,
      ohifUrl: `/viewer/dicomweb?StudyInstanceUIDs=${studyUID}`,
    });
  } catch (error) {
    res.status(500).json({
      error: 'Enhanced debug failed',
      message: error.message,
    });
  }
});

// Test study endpoint that OHIF is trying to access
app.get('/api/test-study-endpoint/:studyUID', async (req, res) => {
  const { studyUID } = req.params;

  console.log(`Testing study endpoint for: ${studyUID}`);

  try {
    // Test the exact endpoints that OHIF is calling
    const endpoints = [
      `/dicom-web/studies?StudyInstanceUID=${studyUID}`,
      `/dicom-web/studies/${studyUID}`,
      `/dicom-web/studies/${studyUID}/metadata`,
      `/dicom-web/studies/${studyUID}/series`,
    ];

    const results = {};

    for (const endpoint of endpoints) {
      try {
        console.log(`Testing endpoint: ${ORTHANC_URL}${endpoint}`);
        const response = await fetch(`${ORTHANC_URL}${endpoint}`, {
          headers: {
            Accept: 'application/dicom+json',
            'User-Agent': 'OHIF-Viewer/3.0',
          },
        });

        results[endpoint] = {
          status: response.status,
          statusText: response.statusText,
          headers: Object.fromEntries(response.headers.entries()),
          data: response.ok ? await response.json() : await response.text(),
        };
      } catch (error) {
        results[endpoint] = {
          error: error.message,
        };
      }
    }

    res.json({
      studyUID,
      orthancUrl: ORTHANC_URL,
      endpoints: results,
    });
  } catch (error) {
    res.status(500).json({
      error: 'Test failed',
      message: error.message,
    });
  }
});

// Orthanc system info endpoint
app.get('/api/orthanc-info', async (req, res) => {
  try {
    const systemResponse = await fetch(`${ORTHANC_URL}/system`);
    const studiesResponse = await fetch(`${ORTHANC_URL}/studies`);

    const system = await systemResponse.json();
    const studies = await studiesResponse.json();

    // Get detailed info for first study if available
    let studyDetails = null;
    if (studies.length > 0) {
      const firstStudyResponse = await fetch(`${ORTHANC_URL}/studies/${studies[0]}`);
      studyDetails = await firstStudyResponse.json();
    }

    res.json({
      system,
      totalStudies: studies.length,
      studyIds: studies,
      firstStudyDetails: studyDetails,
    });
  } catch (error) {
    res.status(500).json({
      error: 'Failed to get Orthanc info',
      message: error.message,
    });
  }
});

// Legacy endpoint for backward compatibility
app.post('/open-dicom', async (req, res) => {
  console.log('Received legacy request to open DICOM file');
  const { url: inputUrl } = req.body || {};

  if (!inputUrl) {
    return res.status(400).json({ error: 'Missing "url" in JSON body' });
  }

  // Redirect to viewer with the URL
  const redirectTo = `/viewer?url=${encodeURIComponent(inputUrl)}`;
  return res.redirect(302, redirectTo);
});

// Serve static files from the built OHIF application
app.use(
  express.static(path.join(__dirname, 'platform', 'app', 'dist'), {
    maxAge: '1d',
    etag: false,
    setHeaders: (res, path) => {
      if (path.endsWith('.js') || path.endsWith('.css')) {
        res.setHeader('Cache-Control', 'public, max-age=86400');
      }
    },
  })
);

// Catch-all handler for SPA routing
app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, 'platform', 'app', 'dist', 'index.html'));
});

// Error handling middleware
app.use((error, req, res) => {
  console.error('Server error:', error);
  res.status(500).json({
    error: 'Internal Server Error',
    message: process.env.NODE_ENV === 'development' ? error.message : 'Something went wrong',
  });
});

// Create HTTPS server
const httpsServer = https.createServer(sslOptions, app);

httpsServer.listen(PORT, '0.0.0.0', () => {
  console.log(
    `🚀 OHIF Viewer HTTPS server running on https://dentax.globalpearlventures.com:${PORT}`
  );
  console.log(`📡 Proxying Orthanc requests to: ${ORTHANC_URL}`);
  console.log(`🔒 SSL certificates loaded successfully`);
  console.log(
    `📊 Health check available at: https://dentax.globalpearlventures.com:${PORT}/api/health`
  );
  console.log(
    `🧪 Orthanc connectivity test: https://dentax.globalpearlventures.com:${PORT}/api/test-orthanc`
  );
});

// Handle server shutdown gracefully
process.on('SIGTERM', () => {
  console.log('SIGTERM received, shutting down gracefully');
  httpsServer.close(() => {
    console.log('Server closed');
  });
});

process.on('SIGINT', () => {
  console.log('SIGINT received, shutting down gracefully');
  httpsServer.close(() => {
    console.log('Server closed');
  });
});
