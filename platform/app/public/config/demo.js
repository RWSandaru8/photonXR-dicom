/** @type {AppTypes.Config} */
window.config = {
  routerBasename: null,
  modes: [],
  extensions: [],
  showStudyList: true,
  // below flag is for performance reasons, but it might not work for all servers
  showWarningMessageForCrossOrigin: true,
  strictZSpacingForVolumeViewport: true,
  showCPUFallbackMessage: true,
  defaultDataSourceName: 'dicomweb',
  dataSources: [
    {
      namespace: '@ohif/extension-default.dataSourcesModule.dicomweb',
      sourceName: 'dicomweb',
      configuration: {
        friendlyName: 'DCM4CHEE Server',
        name: 'DCM4CHEE',
        wadoUriRoot: 'https://dentax.globalpearlventures.com:3000/wado',
        qidoRoot: 'https://dentax.globalpearlventures.com:3000/dicom-web',
        wadoRoot: 'https://dentax.globalpearlventures.com:3000/dicom-web',
        qidoSupportsIncludeField: true,
        imageRendering: 'wadors',
        enableStudyLazyLoad: true,
        bulkDataURI: {
          enabled: false,
        },
        omitQuotationForMultipartRequest: true,
      },
    },
  ],
  i18n: {
    LOCIZE_PROJECTID: 'a8da3f9a-e467-4dd6-af33-474d582a0294',
    LOCIZE_API_KEY: null, // Developers can use this to do in-context editing. DO NOT COMMIT THIS KEY!
    USE_LOCIZE: true,
  },
};
