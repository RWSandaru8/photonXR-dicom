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
  
  defaultDataSourceName: 'orthanc',
  dataSources: [
    {
      namespace: '@ohif/extension-default.dataSourcesModule.dicomweb',
      sourceName: 'orthanc',
      configuration: {
        friendlyName: 'Orthanc DICOM Server',
        name: 'orthanc',
        // Use relative URLs that will be proxied by our server
        wadoUriRoot: '/wado',
        qidoRoot: '/dicom-web',
        wadoRoot: '/dicom-web',
        qidoSupportsIncludeField: false,
        imageRendering: 'wadors',
        thumbnailRendering: 'wadors',
        enableStudyLazyLoad: true,
        supportsFuzzyMatching: false,
        supportsWildcard: true,
        // The authentication will be handled by the proxy
        requestOptions: {
          headers: {},
        },
      },
    },
  ],
  httpErrorHandler: function (error) {
    console.error('HTTP Error:', error);
  },
};
