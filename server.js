const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors'); // <-- Add this
const path = require('path');
const fs = require('fs');
const url = require('url');

const app = express();
const PORT = process.env.PORT || 4000;

app.use(cors()); // <-- Enable CORS for all origins
app.use(bodyParser.json());

// Serve raw DICOM files so the viewer (OpenDicom.tsx) can fetch them
// Place your .dcm files under ./Dicom   (e.g. Dicom/0002213.dcm)
app.use('/Dicom', express.static(path.join(__dirname, 'Dicom')));

// Check if a path is a URL
function isUrl(path) {
  return path.startsWith('http://') || path.startsWith('https://');
}

// Function to extract file paths from a URL or local path
function getActualPath(inputPath) {
  // Handle URLs
  if (isUrl(inputPath)) {
    try {
      const parsedUrl = new URL(inputPath);
      return parsedUrl.pathname;
    } catch (error) {
      console.error('Error parsing URL:', error);
      return inputPath;
    }
  }
  // Handle local paths
  return inputPath;
}

// Function to list all DICOM files in a directory
async function getDicomFilesFromDirectory(dirPath, originalUrl) {
  // If the original URL is from a remote server, we can't directly read the directory
  // For remote URLs, we'll redirect with the folder URL and let the frontend handle it
  if (originalUrl && isUrl(originalUrl)) {
    console.log(`Remote URL detected: ${originalUrl}`);
    // For remote URLs, we'll just assume it's a folder and return the folder path itself
    // The frontend viewer will be responsible for listing/loading the files
    return ['REMOTE_FOLDER'];
  }
  
  // For local paths, proceed with file system operations
  try {
    let fullPath = dirPath;
    
    // If it's a relative path, make it relative to server root
    if (dirPath.startsWith('/')) {
      fullPath = path.join(__dirname, dirPath);
    } else if (!dirPath.includes(':\\')) {
      // Not an absolute Windows path, treat as relative to server
      fullPath = path.join(__dirname, dirPath);
    }

    console.log(`Reading local directory: ${fullPath}`);
    
    // Check if directory exists and is accessible
    const stats = await fs.promises.stat(fullPath);
    if (!stats.isDirectory()) {
      throw new Error('Not a directory');
    }
    
    // Read directory contents
    const files = await fs.promises.readdir(fullPath);
    
    // Filter for DICOM files and create full paths
    const dicomFiles = files
      .filter(file => /\.(dcm|DCM|dicom)$/.test(file) || !path.extname(file))
      .map(file => path.join(dirPath, file));
    
    console.log(`Found ${dicomFiles.length} DICOM files in directory`);
    return dicomFiles;
  } catch (error) {
    console.error(`Error reading directory: ${error.message}`);
    return [];
  }
}

app.post('/open-dicom', async (req, res) => {
  console.log('Received request to open DICOM file');
  console.debug('Request body:', req.body);
  const { url: inputUrl } = req.body || {};
  
  if (!inputUrl) {
    return res.status(400).json({ error: 'Missing "url" in JSON body' });
  }

  // Extract the path from URL
  let filePath = getActualPath(inputUrl);
  
  // Check if the path ends with a typical file extension for DICOM files
  // Common DICOM extensions: .dcm, .DCM, .dicom, no extension
  const isDicomFile = /\.(dcm|DCM|dicom)$/.test(filePath);
  
  // Check if it's likely a directory (doesn't have a file extension)
  const isDicomFolder = !isDicomFile;
  
  if (isDicomFolder) {
    console.log('This is a dicom folder');
    
    try {
      // For remote URLs, handle differently
      if (isUrl(inputUrl)) {
        console.log('Remote DICOM folder detected');
        
        // For remote folders, pass the folder URL to the viewer
        // The viewer will handle listing and loading the files
        const redirectTo = `/viewer/open?dicomFolderUrl=${encodeURIComponent(inputUrl)}`;
        return res.redirect(302, redirectTo);
      }
      
      // For local folders, get all DICOM files in the directory
      const dicomFiles = await getDicomFilesFromDirectory(filePath, inputUrl);
      
      if (dicomFiles.length === 0) {
        return res.status(404).json({ 
          error: 'No DICOM files found in directory', 
          path: inputUrl 
        });
      }
      
      // Create a studyList parameter with all files
      const fileList = dicomFiles.map(file => {
        // Convert back to URLs if needed
        let fileUrl = file;
        if (file !== 'REMOTE_FOLDER' && isUrl(inputUrl)) {
          const baseUrl = inputUrl.substring(0, inputUrl.lastIndexOf('/') + 1);
          const fileName = path.basename(file);
          fileUrl = `${baseUrl}${fileName}`;
        }
        return encodeURIComponent(fileUrl);
      }).join(',');
      
      // Redirect to viewer with multiple files parameter
      const redirectTo = `/viewer/open?studyList=${fileList}`;
      return res.redirect(302, redirectTo);
    } catch (error) {
      console.error('Error processing DICOM folder:', error);
      return res.status(500).json({ 
        error: `Error processing DICOM folder: ${error.message}`,
        path: inputUrl 
      });
    }
  } else {
    // Original logic for single file
    const redirectTo = `/viewer/open?dicomUrl=${encodeURIComponent(inputUrl)}`;
    return res.redirect(302, redirectTo);
  }
});

app.use(express.static(path.join(__dirname, 'platform', 'app', 'dist')));
app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, 'platform', 'app', 'dist', 'index.html'));
});

app.listen(PORT, () => {
  console.log(`Express server listening on http://localhost:${PORT}`);
});
