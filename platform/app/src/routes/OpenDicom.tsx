import React, { useEffect } from 'react';
import { useLocation, useNavigate } from 'react-router-dom';
import { MODULE_TYPES } from '@ohif/core';

import filesToStudies from './Local/filesToStudies';
import { extensionManager } from '../App';

/**
 * Route component that downloads a remote DICOM file, registers it to the
 * local datasource, then forwards the user to the standard OHIF viewer route.
 *
 * Expected URL: /viewer/open?dicomUrl=<encoded-remote-url>
 */
const OpenDicom: React.FC = () => {
  const { search } = useLocation();
  const navigate = useNavigate();

  useEffect(() => {
    (async () => {
      const params = new URLSearchParams(search);
      const dicomUrl = params.get('dicomUrl');
      const studyListParam = params.get('studyList');
      const dicomFolderUrl = params.get('dicomFolderUrl');
      if (!dicomUrl && !studyListParam && !dicomFolderUrl) return;

      try {
        let urls: string[] = [];

        if (dicomUrl) {
          urls = [decodeURIComponent(dicomUrl)];
        } else if (studyListParam) {
          urls = studyListParam.split(',').map(decodeURIComponent);
        } else if (dicomFolderUrl) {
          const baseUrl = decodeURIComponent(dicomFolderUrl).replace(/\/+$/, '');

          // Attempt to fetch manifest or index JSON listing
          const manifestCandidates = [`${baseUrl}/manifest.json`, `${baseUrl}/index.json`];
          for (const m of manifestCandidates) {
            try {
              const resp = await fetch(m);
              if (resp.ok && resp.headers.get('content-type')?.includes('application/json')) {
                const data = await resp.json();
                if (Array.isArray(data)) {
                  urls = data.map((item: string) => `${baseUrl}/${item}`);
                  break;
                }
              }
            } catch (_) {
              /* ignore manifest errors */
            }
          }

          // Fallback: sequential file names (image-00000.dcm ... ) if manifest not found
          if (urls.length === 0) {
            for (let i = 0; i < 2000; i++) {
              const index = i.toString().padStart(5, '0');
              const candidate = `${baseUrl}/image-${index}.dcm`;
              try {
                const head = await fetch(candidate, { method: 'HEAD' });
                if (head.ok) {
                  urls.push(candidate);
                } else if (i > 0) {
                  break;
                }
              } catch {
                if (i > 0) break;
              }
            }
          }
        }

        if (urls.length === 0) {
          throw new Error('No DICOM files resolved to download');
        }

        // Download all DICOM files in parallel
        const files: File[] = await Promise.all(
          urls.map(async remoteUrl => {
            const res = await fetch(remoteUrl);
            if (!res.ok) throw new Error(`Failed to fetch DICOM file: ${remoteUrl}`);
            const blob = await res.blob();
            const filename = remoteUrl.split('/').pop() || `${Date.now()}.dcm`;
            return new File([blob], filename, {
              type: blob.type || 'application/dicom',
            });
          })
        );

        // Obtain the first localApi datasource
        const localDataSourceEntry = extensionManager
          .modules[MODULE_TYPES.DATA_SOURCE]
          .flatMap(mod => mod.module)
          .find(mod => mod.type === 'localApi');

        if (!localDataSourceEntry) {
          throw new Error('Local datasource not found');
        }

        const localDataSource = localDataSourceEntry.createDataSource({});

        // Register the files → StudyInstanceUID(s)
        const studyUIDs = await filesToStudies(files, localDataSource);

        // Navigate to viewer with new studies
        const qs = new URLSearchParams();
        studyUIDs.forEach(uid => qs.append('StudyInstanceUIDs', uid));
        qs.append('datasources', 'dicomlocal');
        navigate(`/viewer/dicomlocal?${qs.toString()}`, { replace: true });
      } catch (err) {
        console.error('Error loading remote DICOM(s)', err);
      }
    })();
  }, [search, navigate]);

  return (
    <div className="flex h-full w-full items-center justify-center text-white">
      Loading DICOM study…
    </div>
  );
};

export default OpenDicom;
