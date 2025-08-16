/** @type {AppTypes.Config} */
window.config = {
  routerBasename: '/',
  extensions: [],
  modes: [],
  showStudyList: true,
  maxNumberOfWebWorkers: 3,
  showLoadingIndicator: true,
  showWarningMessageForCrossOrigin: false,
  showCPUFallbackMessage: true,
  strictZSpacingForVolumeViewport: true,
  groupEnabledModesFirst: true,
  
  defaultDataSourceName: 'orthanc',
  dataSources: [
    {
      namespace: '@ohif/extension-default.dataSourcesModule.dicomweb',
      sourceName: 'orthanc',
      configuration: {
        friendlyName: 'Orthanc DICOM Server',
        name: 'orthanc',
        // Use relative URLs that will be proxied by our HTTPS server
        wadoUriRoot: '/wado',
        qidoRoot: '/dicom-web',
        wadoRoot: '/dicom-web',
        qidoSupportsIncludeField: false,
        imageRendering: 'wadors',
        thumbnailRendering: 'wadors',
        enableStudyLazyLoad: true,
        supportsFuzzyMatching: false,
        supportsWildcard: true,
        // Authentication is handled by the server proxy, so no headers needed here
        requestOptions: {
          headers: {},
        },
      },
    },
  ],
  httpErrorHandler: function (error) {
    console.error('HTTP Error from Orthanc:', error);
    console.log('If you see this error, check the Orthanc server connection');
  },
};
