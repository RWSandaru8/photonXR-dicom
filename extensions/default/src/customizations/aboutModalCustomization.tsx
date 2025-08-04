import React from 'react';
import { AboutModal } from '@ohif/ui-next';
import detect from 'browser-detect';

function AboutModalDefault() {
  const { os, version, name } = detect();
  const browser = `${name[0].toUpperCase()}${name.substr(1)} ${version}`;
  const versionNumber = process.env.VERSION_NUMBER;
  const commitHash = process.env.COMMIT_HASH;

  const [main, beta] = versionNumber.split('-');

  return (
    <AboutModal className="w-[400px]">
      <AboutModal.ProductName>PhotonXR</AboutModal.ProductName>
      <AboutModal.ProductVersion>v2.5.1</AboutModal.ProductVersion>

      <AboutModal.ProductBeta>Beta Release – July 2025</AboutModal.ProductBeta>

      <AboutModal.Body>
        <AboutModal.DetailItem
          label="Commit Hash"
          value="a1b2c3d4e5f6g7h8i9"
        />
        <AboutModal.DetailItem
          label="Current Browser & OS"
          value={`${browser}, ${os}`}
        />
        <AboutModal.DetailItem
          label="Build Date"
          value="July 28, 2025"
        />
        <AboutModal.DetailItem
          label="Developed By"
          value="Global Pearl Ventures"
        />

        <AboutModal.SocialItem
          icon="SocialTwitter"
          url="https://twitter.com/GPV_Tech"
          text="@GPV_Tech"
        />
      </AboutModal.Body>
    </AboutModal>
  );
}

export default {
  'ohif.aboutModal': AboutModalDefault,
};
