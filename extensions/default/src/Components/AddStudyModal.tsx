import React, { useState, useRef } from 'react';
import { Upload, X, Calendar, Clock, FileText, Image } from 'lucide-react';

interface AddStudyModalContentProps {
  hide: () => void;
}

const AddStudyModalContent: React.FC<AddStudyModalContentProps> = ({ hide }) => {
  const [patientId, setPatientId] = useState('');
  const [patientName, setPatientName] = useState('');
  const [modality, setModality] = useState('');
  const [serverType, setServerType] = useState('');
  const [accessionNumber, setAccessionNumber] = useState('');
  const [description, setDescription] = useState('');
  const [studyDate, setStudyDate] = useState('');
  const [studyTime, setStudyTime] = useState('');
  const [dicomFileUrl, setDicomFileUrl] = useState('');
  const [reportFileUrl, setReportFileUrl] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState('');
  const [dicomFileName, setDicomFileName] = useState('');
  const [reportFileName, setReportFileName] = useState('');

  const dicomFileInputRef = useRef<HTMLInputElement>(null);
  const reportFileInputRef = useRef<HTMLInputElement>(null);

  const [dicomFile, setDicomFile] = useState<File | null>(null);
  const [reportFile, setReportFile] = useState<File | null>(null);

  const handleDicomFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files && e.target.files[0]) {
      const file = e.target.files[0];
      setDicomFileName(file.name);
      setDicomFile(file);
      setDicomFileUrl('');
    }
  };

  const handleReportFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files && e.target.files[0]) {
      const file = e.target.files[0];
      setReportFileName(file.name);
      setReportFile(file);
      setReportFileUrl('');
    }
  };

  const handleUploadStudy = async () => {
    try {
      if (!patientId || !patientName || !modality) {
        setError('Patient ID, Patient Name, and Modality are required fields.');
        return;
      }

      setIsSubmitting(true);
      setError('');

      // Build multipart form data
      const formData = new FormData();
      formData.append('id', patientId);
      formData.append('name', patientName);
      formData.append('accession', accessionNumber);
      formData.append('modularity', modality);
      formData.append('description', description);
      formData.append('date', studyDate);
      formData.append('time', studyTime);

      if (dicomFile) {
        formData.append('dicomFile', dicomFile);
      }
      if (reportFile) {
        formData.append('reportFile', reportFile);
      }

      const response = await fetch('http://localhost:5000/api/studies', {
        method: 'POST',
        body: formData,
      });

      if (!response.ok) {
        const errText = await response.text();
        throw new Error(errText || 'Failed to upload study');
      }

      console.log('Study uploaded successfully');
      hide();
    } catch (err: any) {
      console.error('Error adding study:', err);
      setError(err.message || 'Failed to add study. Please try again.');
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="p4 bg-white w-[50%] max-w-[600px] mx-auto flex flex-col h-[90vh] max-h-[800px] rounded-xl overflow-hidden shadow-md">
      {/* Header */}
      <div className="flex-shrink-0 flex items-center justify-between p-4 border-b border-gray-200">
        <h2 className="text-lg font-semibold text-gray-900">Add New Study</h2>
        <button
          onClick={hide}
          className="p-1 hover:bg-gray-100 rounded transition-colors"
        >
          <X className="w-4 h-4 text-gray-400" />
        </button>
      </div>

      <div className="flex-1 overflow-y-auto p-4 space-y-4">
        {/* Patient Information */}
        <div className="grid grid-cols-2 gap-3">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Patient ID <span className="text-red-500">*</span>
            </label>
            <input
              type="text"
              value={patientId}
              onChange={(e) => setPatientId(e.target.value)}
              className="w-full px-3 py-2 text-sm border border-gray-300 rounded focus:ring-1 focus:ring-blue-500 focus:border-blue-500"
              placeholder="Enter patient ID"
              required
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Patient Name <span className="text-red-500">*</span>
            </label>
            <input
              type="text"
              value={patientName}
              onChange={(e) => setPatientName(e.target.value)}
              className="w-full px-3 py-2 text-sm border border-gray-300 rounded focus:ring-1 focus:ring-blue-500 focus:border-blue-500"
              placeholder="Enter patient name"
              required
            />
          </div>
        </div>

        {/* Modality and Server Type */}
        <div className="grid grid-cols-2 gap-3">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Modality <span className="text-red-500">*</span>
            </label>
            <select
              value={modality}
              onChange={(e) => setModality(e.target.value)}
              className="w-full px-3 py-2 text-sm border border-gray-300 rounded focus:ring-1 focus:ring-blue-500 focus:border-blue-500 bg-white"
              required
            >
              <option value="">Select Modality</option>
              <option value="CT">CT</option>
              <option value="MRI">MRI</option>
              <option value="DX">DX</option>
              <option value="CR">CR</option>
              <option value="US">US</option>
              <option value="XA">XA</option>
            </select>
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Server Type</label>
            <select
              value={serverType}
              onChange={(e) => setServerType(e.target.value)}
              className="w-full px-3 py-2 text-sm border border-gray-300 rounded focus:ring-1 focus:ring-blue-500 focus:border-blue-500 bg-white"
            >
              <option value="">Select Server Type</option>
              <option value="DICOMweb">DICOMweb</option>
              <option value="DIMSE">DIMSE</option>
              <option value="WADO">WADO</option>
            </select>
          </div>
        </div>

        {/* Accession Number, Date, and Time */}
        <div className="grid grid-cols-3 gap-3">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Accession Number</label>
            <input
              type="text"
              value={accessionNumber}
              onChange={(e) => setAccessionNumber(e.target.value)}
              className="w-full px-3 py-2 text-sm border border-gray-300 rounded focus:ring-1 focus:ring-blue-500 focus:border-blue-500"
              placeholder="Enter accession number"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1 flex items-center">
              <Calendar className="w-3 h-3 mr-1" />
              Study Date
            </label>
            <input
              type="date"
              value={studyDate}
              onChange={(e) => setStudyDate(e.target.value)}
              className="w-full px-3 py-2 text-sm border border-gray-300 rounded focus:ring-1 focus:ring-blue-500 focus:border-blue-500"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1 flex items-center">
              <Clock className="w-3 h-3 mr-1" />
              Study Time
            </label>
            <input
              type="time"
              value={studyTime}
              onChange={(e) => setStudyTime(e.target.value)}
              className="w-full px-3 py-2 text-sm border border-gray-300 rounded focus:ring-1 focus:ring-blue-500 focus:border-blue-500"
            />
          </div>
        </div>

        {/* Description */}
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">Description</label>
          <textarea
            value={description}
            onChange={(e) => setDescription(e.target.value)}
            rows={3}
            className="w-full px-3 py-2 text-sm border border-gray-300 rounded focus:ring-1 focus:ring-blue-500 focus:border-blue-500 resize-none"
            placeholder="Enter study description..."
          />
        </div>

        {/* DICOM Files Upload */}
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-2">DICOM Files</label>
          <div
            className="border-2 border-dashed border-gray-300 rounded-lg p-6 text-center hover:border-blue-400 hover:bg-blue-50 transition-all cursor-pointer group"
            onClick={() => dicomFileInputRef.current?.click()}
          >
            <input
              type="file"
              ref={dicomFileInputRef}
              className="hidden"
              accept=".dcm,.zip"
              onChange={handleDicomFileChange}
            />
            <div className="flex flex-col items-center">
              {dicomFileName ? (
                <>
                  <Image className="w-8 h-8 text-green-500 mb-2" />
                  <p className="text-sm font-medium text-green-600">{dicomFileName}</p>
                </>
              ) : (
                <>
                  <Upload className="w-8 h-8 text-gray-400 mb-2 group-hover:text-blue-500" />
                  <p className="text-sm font-medium text-blue-600">Upload a file</p>
                  <p className="text-xs text-gray-500">or drag and drop</p>
                  <p className="text-xs text-gray-400">DICOM files (.dcm) or ZIP archives up to 10MB</p>
                </>
              )}
            </div>
          </div>
        </div>

          <div className="mb-6">
            <label className="block text-sm font-medium text-gray-700 mb-3">Report Files</label>
            <div
              className="border-2 border-dashed border-gray-300 rounded-xl p-8 text-center hover:border-blue-400 hover:bg-blue-50 transition-all cursor-pointer group"
              onClick={() => reportFileInputRef.current?.click()}
            >
              <input
                type="file"
                ref={reportFileInputRef}
                className="hidden"
                accept=".pdf,.doc,.docx"
                onChange={handleReportFileChange}
              />
              <div className="flex flex-col items-center">
                {reportFileName ? (
                  <>
                    <FileText className="w-12 h-12 text-green-500 mb-3" />
                    <p className="text-sm font-medium text-green-600 mb-1">{reportFileName}</p>
                    <p className="text-xs text-gray-500">Click to change file</p>
                  </>
                ) : (
                  <>
                    <div className="w-16 h-16 bg-gray-100 rounded-full flex items-center justify-center mb-4 group-hover:bg-blue-100 transition-colors">
                      <Upload className="w-8 h-8 text-gray-400 group-hover:text-blue-500" />
                    </div>
                    <p className="text-base font-medium text-blue-600 mb-1">Upload a file</p>
                    <p className="text-sm text-gray-500 mb-1">or drag and drop</p>
                    <p className="text-xs text-gray-400">PDF, DOC, DOCX files up to 10MB</p>
                  </>
                )}
              </div>
            </div>
          </div>

          {/* Error Message */}
          {error && (
            <div className="mb-6 p-4 bg-red-50 border border-red-200 rounded-lg">
              <p className="text-sm text-red-700">{error}</p>
            </div>
          )}

          {/* Action Buttons */}
          <div className="flex justify-end gap-3 pt-4 border-t border-gray-200">
            <button
              onClick={hide}
              disabled={isSubmitting}
              className="px-6 py-2.5 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-lg hover:bg-gray-50 focus:ring-2 focus:ring-gray-200 transition-all disabled:opacity-50"
            >
              Cancel
            </button>
            <button
              onClick={handleUploadStudy}
              disabled={isSubmitting}
              className="px-6 py-2.5 text-sm font-medium text-white bg-teal-600 rounded-lg hover:bg-teal-700 focus:ring-2 focus:ring-teal-500 transition-all disabled:opacity-50 disabled:cursor-not-allowed flex items-center gap-2"
            >
              {isSubmitting ? (
                <>
                  <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin"></div>
                  Uploading...
                </>
              ) : (
                'Upload Study'
              )}
            </button>
          </div>
        </div>
      </div>
  );
};

export default AddStudyModalContent;
