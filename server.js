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

// Proxy middleware for Orthanc API calls
const orthancProxy = createProxyMiddleware({
  target: ORTHANC_URL,
  changeOrigin: true,
  secure: false, // Set to false if Orthanc uses self-signed certificates
  logLevel: 'debug',
  onProxyReq: (proxyReq, req, res) => {
    console.log(`Proxying ${req.method} ${req.url} to ${ORTHANC_URL}${req.url}`);
    // Add required headers for DICOM-Web
    proxyReq.setHeader('Accept', 'application/dicom+json');
  },
  onProxyRes: proxyRes => {
    // Add CORS headers to proxy responses
    proxyRes.headers['Access-Control-Allow-Origin'] = '*';
    proxyRes.headers['Access-Control-Allow-Methods'] = 'GET, POST, PUT, DELETE, OPTIONS';
    proxyRes.headers['Access-Control-Allow-Headers'] =
      'Content-Type, Authorization, X-Requested-With, Accept';
  },
  onError: (err, req, res) => {
    console.error('Proxy error:', err);
    res.status(500).json({ error: 'Proxy error', message: err.message });
  },
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
app.use('/wado', orthancProxy); // Add WADO proxy

// API endpoint for OHIF configuration
app.get('/api/config', (req, res) => {
  // Set proper headers to ensure this config is used
  res.set({
    'Content-Type': 'application/json',
    'Cache-Control': 'no-cache, no-store, must-revalidate',
    'Pragma': 'no-cache',
    'Expires': '0'
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
          qidoSupportsIncludeField: false,
          imageRendering: 'wadouri', // Fallback to WADO-URI if WADO-RS fails
          thumbnailRendering: 'wadouri', // Fallback to WADO-URI if WADO-RS fails
          enableStudyLazyLoad: true,
          supportsFuzzyMatching: false,
          supportsWildcard: true,
          acceptHeader: 'application/dicom+json',
          supportsInstanceMetadata: false, // Disable instance metadata if causing issues
        },
      },
    ],
    defaultDataSourceName: 'orthanc',
    maxNumberOfWebWorkers: 3,
    omitQuotationForMultipartRequest: true,
  };

  res.json(config);
});

// Alternative config endpoints that OHIF might look for
app.get('/config', (req, res) => {
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
    configuration: {
      friendlyName: 'Orthanc DICOM Server',
      name: 'orthanc',
      wadoUriRoot: 'https://dentax.globalpearlventures.com:3000/wado',
      qidoRoot: 'https://dentax.globalpearlventures.com:3000/dicom-web',
      wadoRoot: 'https://dentax.globalpearlventures.com:3000/dicom-web',
      qidoSupportsIncludeField: false,
      imageRendering: 'wadouri',
      thumbnailRendering: 'wadouri',
      enableStudyLazyLoad: true,
      supportsFuzzyMatching: false,
      supportsWildcard: true,
      acceptHeader: 'application/dicom+json',
      supportsInstanceMetadata: false,
    },
  }],
  defaultDataSourceName: 'orthanc',
  maxNumberOfWebWorkers: 3,
  omitQuotationForMultipartRequest: true,
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
    const response = await fetch(`${ORTHANC_URL}/dicom-web/studies`, {
      method: 'GET',
      headers: {
        Accept: 'application/dicom+json',
      },
    });

    if (response.ok) {
      const data = await response.json();
      res.json({
        status: 'success',
        message: 'Orthanc connectivity test passed',
        studyCount: data.length,
      });
    } else {
      res.status(response.status).json({
        status: 'error',
        message: `Orthanc returned ${response.status}`,
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
    const seriesResponse = await fetch(
      `${ORTHANC_URL}/dicom-web/studies/${studyUID}/series`,
      {
        headers: { Accept: 'application/dicom+json' },
      }
    );

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
