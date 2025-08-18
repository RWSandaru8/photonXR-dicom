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
  const config = {
    routerBasename: '/',
    modes: ['@ohif/mode-longitudinal'],
    dataSources: [
      {
        // FIXED: Correct namespace name
        namespace: '@ohif/extension-default.dataSourcesModule.dicomweb',
        configuration: {
          friendlyName: 'Orthanc DICOM Server',
          name: 'orthanc',
          // FIXED: Use the proxied endpoints through your server
          wadoUriRoot: 'https://dentax.globalpearlventures.com:3000/wado',
          qidoRoot: 'https://dentax.globalpearlventures.com:3000/dicom-web',
          wadoRoot: 'https://dentax.globalpearlventures.com:3000/dicom-web',
          qidoSupportsIncludeField: false,
          imageRendering: 'wadors',
          thumbnailRendering: 'wadors',
          enableStudyLazyLoad: true,
          supportsFuzzyMatching: false,
          supportsWildcard: true,
          // ADDED: Additional configuration for better compatibility
          acceptHeader: 'application/dicom+json',
          requestOptions: {
            requestCredentials: 'include',
          },
        },
      },
    ],
    defaultDataSourceName: 'orthanc',
    httpErrorHandler: error => {
      console.error('HTTP Error:', error);
    },
    // ADDED: Additional OHIF configuration
    showStudyList: true,
    filterQueryParam: false,
  };

  res.json(config);
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
