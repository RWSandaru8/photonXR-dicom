import React from 'react';
import PropTypes from 'prop-types';
import { useTranslation } from 'react-i18next';

import LegacyButton from '../LegacyButton';
import Typography from '../Typography';
import InputGroup from '../InputGroup';
import { Icons, useModal } from '@ohif/ui-next';
import AddStudyModalContent from '../../../../../extensions/default/src/Components/AddStudyModal';

const StudyListFilter = ({
  filtersMeta,
  filterValues,
  onChange,
  clearFilters,
  isFiltering,
  numOfStudies,
  onUploadClick,
  getDataSourceConfigurationComponent,
}) => {
  const { t } = useTranslation('StudyList');
  const { show } = useModal();
  const { sortBy, sortDirection } = filterValues;
  const filterSorting = { sortBy, sortDirection };
  const setFilterSorting = sortingValues => {
    onChange({
      ...filterValues,
      ...sortingValues,
    });
  };
  const isSortingEnabled = numOfStudies > 0 && numOfStudies <= 100;

  const handleNewStudyClick = () => {
    show({
      title: '', // Remove the title text
      content: AddStudyModalContent,
      containerClassName: 'w-[120vw] max-w-[1400px] !border-0 !shadow-none !bg-transparent',
      contentClassName: '!p-0',
      shouldCloseOnEsc: true,
      shouldCloseOnOverlayClick: true,
    });
  };

  return (
    <React.Fragment>
      <div className="flex w-full flex-row items-center justify-between bg-[#F5F5F5] py-4 px-4">
        <div className="flex min-w-[1px] shrink flex-row items-center gap-6">
          <Typography
            component="h6"
            variant="h6"
            className="text-[#333333]"
          >
            {t('📁Patient Studies')}
          </Typography>
          {getDataSourceConfigurationComponent && getDataSourceConfigurationComponent()}
          {onUploadClick && (
            <div
              className="text-primary-active flex cursor-pointer items-center gap-2 self-center text-lg font-semibold"
              onClick={onUploadClick}
            >
              <Icons.Upload />
              <span>{t('Upload')}</span>
            </div>
          )}
        </div>
        <div className="flex h-[34px] flex-row items-center">
          {/* TODO revisit the completely rounded style of button used for clearing the study list filter - for now use LegacyButton*/}
          {isFiltering && (
            <LegacyButton
              rounded="full"
              variant="outlined"
              color="primaryActive"
              border="primaryActive"
              className="mx-8"
              startIcon={<Icons.Cancel />}
              onClick={clearFilters}
            >
              {t('ClearFilters')}
            </LegacyButton>
          )}

          {/*<Typography
            component="h6"
            variant="h6"
            className="mr-2 text-[#333333]"
            data-cy={'num-studies'}
          >
            {numOfStudies > 100 ? '>100' : numOfStudies}
          </Typography>
          <Typography
            component="h6"
            variant="h6"
            className="text-[#333333]"
          >
            {`${t('Studies')} `}
          </Typography>*/}
          <LegacyButton
            variant="outlined"
            color="primaryActive"
            border="primaryActive"
            className="ml-4 !border-none !bg-[#B2A7D3] px-6 py-2 text-lg !font-medium !text-white shadow-sm transition-all duration-200 hover:!bg-[#202025] hover:shadow-md"
            onClick={handleNewStudyClick}
          >
            + New Study
          </LegacyButton>
        </div>
      </div>
      {/*<div className="sticky -top-1 z-10 mx-auto border-b-4 border-black">
        <div className="bg-primary-dark pt-3 pb-3">
          <InputGroup
            inputMeta={filtersMeta}
            values={filterValues}
            onValuesChange={onChange}
            sorting={filterSorting}
            onSortingChange={setFilterSorting}
            isSortingEnabled={isSortingEnabled}
          />
        </div>
        {numOfStudies > 100 && (
          <div className="container m-auto">
            <div className="bg-primary-main rounded-b py-1 text-center text-base">
              <p className="text-white">
                {t('Filter list to 100 studies or less to enable sorting')}
              </p>
            </div>
          </div>
        )}
      </div>*/}
    </React.Fragment>
  );
};

StudyListFilter.propTypes = {
  filtersMeta: PropTypes.arrayOf(
    PropTypes.shape({
      /** Identifier used to map a field to it's value in `filterValues` */
      name: PropTypes.string.isRequired,
      /** Friendly label for filter field */
      displayName: PropTypes.string.isRequired,
      /** One of the supported filter field input types */
      inputType: PropTypes.oneOf(['Text', 'MultiSelect', 'DateRange', 'None']).isRequired,
      isSortable: PropTypes.bool.isRequired,
      /** Size of filter field in a 12-grid system */
      gridCol: PropTypes.oneOf([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]).isRequired,
      /** Options for a "MultiSelect" inputType */
      option: PropTypes.arrayOf(
        PropTypes.shape({
          value: PropTypes.string,
          label: PropTypes.string,
        })
      ),
    })
  ).isRequired,
  filterValues: PropTypes.object.isRequired,
  numOfStudies: PropTypes.number.isRequired,
  onChange: PropTypes.func.isRequired,
  clearFilters: PropTypes.func.isRequired,
  isFiltering: PropTypes.bool.isRequired,
  onUploadClick: PropTypes.func,
  getDataSourceConfigurationComponent: PropTypes.func,
};

export default StudyListFilter;
