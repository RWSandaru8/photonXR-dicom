import React from 'react';
import PropTypes from 'prop-types';
import classnames from 'classnames';
import { ThumbnailList } from '../ThumbnailList';

import { Accordion, AccordionContent, AccordionItem, AccordionTrigger } from '../Accordion';
import { Tooltip, TooltipContent, TooltipTrigger } from '../Tooltip';

const StudyItem = ({
  date,
  description,
  numInstances,
  modalities,
  isActive,
  onClick,
  isExpanded,
  displaySets,
  activeDisplaySetInstanceUIDs,
  onClickThumbnail,
  onDoubleClickThumbnail,
  onClickUntrack,
  viewPreset = 'thumbnails',
  ThumbnailMenuItems,
  StudyMenuItems,
  StudyInstanceUID,
}: withAppTypes) => {
  return (
    <Accordion
      type="single"
      collapsible
      onClick={onClick}
      onKeyDown={() => {}}
      role="button"
      tabIndex={0}
      defaultValue={isActive ? 'study-item' : undefined}
    >
      <AccordionItem value="study-item">
        <AccordionTrigger
          className={classnames(
            'group w-full rounded border transition-colors',
            isActive
              ? 'border-blue-500 bg-gray-800'
              : 'border-gray-700 bg-gray-900 hover:bg-gray-800'
          )}
        >
          <div className="flex h-[36px] w-full flex-row overflow-hidden">
            <div className="flex w-full flex-row items-center justify-between px-2">
              <div className="flex min-w-0 flex-col items-start text-xs">
                <Tooltip>
                  <TooltipContent className="border border-gray-700 bg-gray-800 text-white">
                    {date}
                  </TooltipContent>
                  <TooltipTrigger
                    className="w-full"
                    asChild
                  >
                    <div className="h-4 w-full max-w-[140px] overflow-hidden truncate whitespace-nowrap text-left text-gray-200">
                      {date}
                    </div>
                  </TooltipTrigger>
                </Tooltip>
                <Tooltip>
                  <TooltipContent className="border border-gray-700 bg-gray-800 text-white">
                    {description}
                  </TooltipContent>
                  <TooltipTrigger
                    className="w-full"
                    asChild
                  >
                    <div className="h-4 w-full overflow-hidden truncate whitespace-nowrap text-left text-sm font-medium text-gray-200">
                      {description}
                    </div>
                  </TooltipTrigger>
                </Tooltip>
              </div>
              <div className="flex items-center space-x-3">
                <div className="flex flex-col items-end text-xs">
                  <div className="font-medium text-gray-300">{modalities}</div>
                  <div className="text-gray-400">{numInstances} images</div>
                </div>
                {StudyMenuItems && (
                  <div className="ml-1 flex items-center text-gray-400 transition-colors hover:text-blue-400">
                    <StudyMenuItems StudyInstanceUID={StudyInstanceUID} />
                  </div>
                )}
              </div>
            </div>
          </div>
        </AccordionTrigger>
        <AccordionContent
          onClick={event => {
            event.stopPropagation();
          }}
        >
          {isExpanded && displaySets && (
            <ThumbnailList
              thumbnails={displaySets}
              activeDisplaySetInstanceUIDs={activeDisplaySetInstanceUIDs}
              onThumbnailClick={onClickThumbnail}
              onThumbnailDoubleClick={onDoubleClickThumbnail}
              onClickUntrack={onClickUntrack}
              viewPreset={viewPreset}
              ThumbnailMenuItems={ThumbnailMenuItems}
            />
          )}
        </AccordionContent>
      </AccordionItem>
    </Accordion>
  );
};

StudyItem.propTypes = {
  date: PropTypes.string.isRequired,
  description: PropTypes.string,
  modalities: PropTypes.string.isRequired,
  numInstances: PropTypes.number.isRequired,
  isActive: PropTypes.bool,
  onClick: PropTypes.func.isRequired,
  isExpanded: PropTypes.bool,
  displaySets: PropTypes.array,
  activeDisplaySetInstanceUIDs: PropTypes.array,
  onClickThumbnail: PropTypes.func,
  onDoubleClickThumbnail: PropTypes.func,
  onClickUntrack: PropTypes.func,
  viewPreset: PropTypes.string,
  StudyMenuItems: PropTypes.func,
  StudyInstanceUID: PropTypes.string,
};

export { StudyItem };
