import React from 'react';
import { useToolbar } from '@ohif/core';
import ToolButtonListWrapper from './ToolButtonListWrapper';

interface ToolbarProps {
  buttonSection?: string;
  viewportId?: string;
  location?: number;
  expandedGroup?: string | null;
  setExpandedGroup?: (id: string | null) => void;
}

export function Toolbar({
  buttonSection = 'primary',
  viewportId,
  location,
  expandedGroup,
  setExpandedGroup,
}: ToolbarProps) {
  const {
    toolbarButtons,
    onInteraction,
    isItemOpen,
    isItemLocked,
    openItem,
    closeItem,
    toggleLock,
  } = useToolbar({
    buttonSection,
  });

  if (!toolbarButtons.length) {
    return null;
  }

  return (
    <>
      {toolbarButtons?.map(toolDef => {
        if (!toolDef) {
          return null;
        }

        const { id, Component, componentProps } = toolDef;

        // Enhanced props with state and actions - respecting viewport specificity
        const enhancedProps = {
          ...componentProps,
          isOpen: isItemOpen(id, viewportId),
          isLocked: isItemLocked(id, viewportId),
          onOpen: () => openItem(id, viewportId),
          onClose: () => closeItem(id, viewportId),
          onToggleLock: () => toggleLock(id, viewportId),
          viewportId,
        };

        // If this is a tool group (hasDropdown or has multiple items), render only the group icon in the sidebar
        if (
          (componentProps.hasDropdown || Component === ToolButtonListWrapper) &&
          setExpandedGroup
        ) {
          return (
            <div key={id}>
              <ToolButtonListWrapper
                buttonSection={id}
                id={id}
                sidebarTriggerOnly={true}
                isActive={expandedGroup === id}
                onSidebarTrigger={() =>
                  setExpandedGroup && setExpandedGroup(expandedGroup === id ? null : id)
                }
                showLabelBelowIcon={true}
              />
            </div>
          );
        }

        // Default: normal tool button
        return (
          <div key={id}>
            <Component
              {...enhancedProps}
              id={id}
              location={location}
              showLabelBelowIcon={true}
              onInteraction={args => {
                onInteraction({
                  ...args,
                  itemId: id,
                  viewportId,
                });
              }}
            />
          </div>
        );
      })}
    </>
  );
}
