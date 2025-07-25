import React from 'react';

interface StudyTableProps {
  studies: Array<{
    ID: string;
    Name: string;
    Report: string;
    Accession: string;
    Modality: string;
    Description: string;
    Date: string;
    Time: string;
    SourceAE: string;
  }>;
  onRowClick: (studyId: string) => void;
}

const NewStudyTable: React.FC<StudyTableProps> = ({ studies, onRowClick }) => {
  return (
    <div className="rounded-md border-2 border-[#1E9B8A]">
      <table className="min-w-full divide-y divide-gray-200">
        <thead className="bg-[#1E9B8A]">
          <tr>
            <th
              scope="col"
              className="px-6 py-3 text-left text-xs font-medium uppercase tracking-wider text-white"
            >
              ID
            </th>
            <th
              scope="col"
              className="px-6 py-3 text-left text-xs font-medium uppercase tracking-wider text-white"
            >
              Name
            </th>
            <th
              scope="col"
              className="px-6 py-3 text-left text-xs font-medium uppercase tracking-wider text-white"
            >
              Report
            </th>
            <th
              scope="col"
              className="px-6 py-3 text-left text-xs font-medium uppercase tracking-wider text-white"
            >
              Accession
            </th>
            <th
              scope="col"
              className="px-6 py-3 text-left text-xs font-medium uppercase tracking-wider text-white"
            >
              Modality
            </th>
            <th
              scope="col"
              className="px-6 py-3 text-left text-xs font-medium uppercase tracking-wider text-white"
            >
              Description
            </th>
            <th
              scope="col"
              className="px-6 py-3 text-left text-xs font-medium uppercase tracking-wider text-white"
            >
              Date
            </th>
            <th
              scope="col"
              className="px-6 py-3 text-left text-xs font-medium uppercase tracking-wider text-white"
            >
              Time
            </th>
            <th
              scope="col"
              className="px-6 py-3 text-left text-xs font-medium uppercase tracking-wider text-white"
            >
              Source AE
            </th>
            <th
              scope="col"
              className="relative px-6 py-3"
            >
              <span className="sr-only">Actions</span>
            </th>
          </tr>
        </thead>
        <tbody className="divide-y divide-gray-200 bg-white">
          {studies.map((study, index) => (
            <tr
              key={index}
              onClick={() => onRowClick(study.ID)}
              className="cursor-pointer hover:bg-gray-100"
            >
              <td className="whitespace-nowrap px-6 py-4 text-sm font-medium text-gray-900">
                {study.ID}
              </td>
              <td className="whitespace-nowrap px-6 py-4 text-sm text-gray-900">{study.Name}</td>
              <td className="whitespace-nowrap px-6 py-4 text-sm text-gray-900">{study.Report}</td>
              <td className="whitespace-nowrap px-6 py-4 text-sm text-gray-900">
                {study.Accession}
              </td>
              <td className="whitespace-nowrap px-6 py-4 text-sm text-gray-900">
                {study.Modality}
              </td>
              <td className="whitespace-nowrap px-6 py-4 text-sm text-gray-900">
                {study.Description}
              </td>
              <td className="whitespace-nowrap px-6 py-4 text-sm text-gray-900">{study.Date}</td>
              <td className="whitespace-nowrap px-6 py-4 text-sm text-gray-900">{study.Time}</td>
              <td className="whitespace-nowrap px-6 py-4 text-sm text-gray-900">
                {study.SourceAE}
              </td>
              <td className="whitespace-nowrap px-6 py-4 text-right text-sm font-medium"></td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
};

export default NewStudyTable;
