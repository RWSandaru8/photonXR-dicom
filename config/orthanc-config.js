/** @type {AppTypes.Config} */

window.config = {
  name: 'config/orthanc-config.js',
  routerBasename: null,
  extensions: [],
  modes: [],
  customizationService: {},
  showStudyList: true,
  // some windows systems have issues with more than 3 web workers
  maxNumberOfWebWorkers: 3,
  // below flag is for performance reasons, but it might not work for all servers
  showWarningMessageForCrossOrigin: true,
  showCPUFallbackMessage: true,
  showLoadingIndicator: true,
  experimentalStudyBrowserSort: false,
  strictZSpacingForVolumeViewport: true,
  groupEnabledModesFirst: true,
  allowMultiSelectExport: false,
  maxNumRequests: {
    interaction: 100,
    thumbnail: 75,
    prefetch: 25,
  },
  
  defaultDataSourceName: 'orthanc',
  
  dataSources: [
    {
      namespace: '@ohif/extension-default.dataSourcesModule.dicomweb',
      sourceName: 'orthanc',
      configuration: {
        friendlyName: 'Orthanc DICOMWeb Server',
        name: 'Orthanc',
        // Note: These URLs will be accessible from the browser, so use the host's external IP or localhost
        wadoUriRoot: 'http://localhost:4000/dicom-web',
        qidoRoot: 'http://localhost:4000/dicom-web',
        wadoRoot: 'http://localhost:4000/dicom-web',
        qidoSupportsIncludeField: true,
        supportsReject: true,
        dicomUploadEnabled: true,
        imageRendering: 'wadors',
        thumbnailRendering: 'wadors',
        enableStudyLazyLoad: true,
        supportsFuzzyMatching: true,
        supportsWildcard: true,
        staticWado: false,
        singlepart: 'bulkdata,video',
        omitQuotationForMultipartRequest: true,
        // CORS headers configuration for Orthanc
        requestOptions: {
          requestCredentials: 'omit',
        },
        bulkDataURI: {
          enabled: true,
          relativeResolution: 'studies',
        },
      },
    },
  ],
  
  httpErrorHandler: error => {
    console.warn('HTTP Error Status:', error.status);
    if (error.status === 0) {
      console.error('Network error or CORS issue. Please check if Orthanc server is running and CORS is properly configured.');
    }
  },
  
  // CORS configuration
  cors: {
    enabled: true,
    allowCredentials: false,
    allowedOrigins: ['*'],
    allowedHeaders: ['*'],
    allowedMethods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  },
};
