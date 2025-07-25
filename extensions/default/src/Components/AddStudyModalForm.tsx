import React, { useState } from 'react';
import { LegacyButton, InputText, Select } from '../../../../platform/ui/src/components';
import Typography from '../../../../platform/ui/src/components/Typography';
import { useTranslation } from 'react-i18next';

interface AddStudyModalFormProps {
  hide: () => void;
  onSuccess: () => void;
}

const AddStudyModalForm: React.FC<AddStudyModalFormProps> = ({ hide, onSuccess }) => {
  const { t } = useTranslation('AddStudyModal');
  const [formValues, setFormValues] = useState({
    id: '',
    name: '',
    accession: '',
    modularity: '',
    description: '',
    date: '',
    time: '',
  });
  const [dicomFiles, setDicomFiles] = useState<FileList | null>(null);

  const handleChange = (field: string, value: string) => {
    setFormValues(prev => ({ ...prev, [field]: value }));
  };

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setDicomFiles(e.target.files);
  };

  const handleSubmit = async () => {
    try {
      const formData = new FormData();
      Object.entries(formValues).forEach(([key, value]) => formData.append(key, value));
      if (dicomFiles) {
        Array.from(dicomFiles).forEach(file => formData.append('dicomFiles', file));
      }
      const res = await fetch(
        process.env.REACT_APP_BACKEND_URL ?? 'http://localhost:5000/api/studies/upload',
        {
          method: 'POST',
          body: formData,
        }
      );
      if (!res.ok) throw new Error('Failed to upload study');
      onSuccess();
      hide();
    } catch (err) {
      console.error(err);
      alert('Failed to upload study');
    }
  };

  return (
    <div className="p-6">
      <Typography variant="h6" className="mb-4">
        {t('Add New Study')}
      </Typography>
      <div className="mb-4 grid grid-cols-1 gap-4 md:grid-cols-2">
        <InputText label="Patient ID" value={formValues.id} onChange={v => handleChange('id', v)} />
        <InputText label="Patient Name" value={formValues.name} onChange={v => handleChange('name', v)} />
        <InputText label="Accession" value={formValues.accession} onChange={v => handleChange('accession', v)} />
        <Select
          options={[{ value: 'CT', label: 'CT' }, { value: 'MRI', label: 'MRI' }, { value: 'DX', label: 'DX' }]}
          value={formValues.modularity}
          onChange={v => handleChange('modularity', v)}
          placeholder="Modality"
        />
        <InputText label="Description" value={formValues.description} onChange={v => handleChange('description', v)} />
        <InputText label="Date (YYYY-MM-DD)" value={formValues.date} onChange={v => handleChange('date', v)} />
        <InputText label="Time (HH:mm)" value={formValues.time} onChange={v => handleChange('time', v)} />
      </div>
      <div className="mb-4">
        <input type="file" multiple onChange={handleFileChange} accept=".dcm,.zip" />
      </div>
      <div className="flex justify-end gap-2">
        <LegacyButton onClick={hide} variant="outlined">
          {t('Cancel')}
        </LegacyButton>
        <LegacyButton onClick={handleSubmit} variant="contained" className="bg-emerald-500 text-white">
          {t('Upload Study')}
        </LegacyButton>
      </div>
    </div>
  );
};

export default AddStudyModalForm;
