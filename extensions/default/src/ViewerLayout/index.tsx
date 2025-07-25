import React, { useEffect, useState, useCallback } from 'react';
import PropTypes from 'prop-types';

import { HangingProtocolService, CommandsManager } from '@ohif/core';
import { useAppConfig } from '@state';
import ViewerHeader from './ViewerHeader';
import SidePanelWithServices from '../Components/SidePanelWithServices';
import { ResizablePanelGroup, ResizablePanel, ResizableHandle } from '@ohif/ui-next';
import useResizablePanels from './ResizablePanelsHook';
import { Toolbar } from '../Toolbar/Toolbar';
import { useViewportGrid } from '@ohif/ui-next';
import { IconPresentationProvider, ToolButton } from '@ohif/ui-next';
import FloatingToolGroupBar from '../Toolbar/FloatingToolGroupBar';
import './mobileToolbar.css';

const resizableHandleClassName = 'mt-[1px] bg-black';

function useIsMobile() {
  const [isMobile, setIsMobile] = useState(() => window.innerWidth <= 600);
  useEffect(() => {
    const onResize = () => setIsMobile(window.innerWidth <= 600);
    window.addEventListener('resize', onResize);
    return () => window.removeEventListener('resize', onResize);
  }, []);
  return isMobile;
}

function ViewerLayout({
  // From Extension Module Params
  extensionManager,
  servicesManager,
  hotkeysManager,
  commandsManager,
  // From Modes
  viewports,
  ViewportGridComp,
  leftPanelClosed = false,
  rightPanelClosed = false,
  leftPanelResizable = false,
  rightPanelResizable = false,
}: withAppTypes): React.FunctionComponent {
  const [appConfig] = useAppConfig();
  const isMobile = useIsMobile();

  const { panelService, hangingProtocolService, customizationService } = servicesManager.services;
  const [showLoadingIndicator, setShowLoadingIndicator] = useState(appConfig.showLoadingIndicator);

  const hasPanels = useCallback(
    (side): boolean => !!panelService.getPanels(side).length,
    [panelService]
  );

  const [hasRightPanels, setHasRightPanels] = useState(hasPanels('right'));
  const [hasLeftPanels, setHasLeftPanels] = useState(hasPanels('left'));
  const [leftPanelClosedState, setLeftPanelClosed] = useState(leftPanelClosed || isMobile);
  const [rightPanelClosedState, setRightPanelClosed] = useState(rightPanelClosed);
  const [viewerHeight, setViewerHeight] = useState(getViewerHeight());

  const [
    leftPanelProps,
    rightPanelProps,
    resizablePanelGroupProps,
    resizableLeftPanelProps,
    resizableViewportGridPanelProps,
    resizableRightPanelProps,
    onHandleDragging,
  ] = useResizablePanels(
    leftPanelClosedState,
    setLeftPanelClosed,
    rightPanelClosedState,
    setRightPanelClosed,
    hasLeftPanels,
    hasRightPanels
  );

  useEffect(() => {
    if (isMobile) {
      setLeftPanelClosed(true);
    }
  }, [isMobile]);

  const handleMouseEnter = () => {
    (document.activeElement as HTMLElement)?.blur();
  };

  const LoadingIndicatorProgress = customizationService.getCustomization(
    'ui.loadingIndicatorProgress'
  );

  const [viewportGrid] = useViewportGrid();
  const { activeViewportId } = viewportGrid;

  const [expandedGroup, setExpandedGroup] = useState<string | null>(null);

  function getViewerHeight() {
    return isMobile
      ? 'calc(100vh - 104px)' // Mobile
      : 'calc(100vh - 52px)'; // Desktop
  }

  useEffect(() => {
    function handleResize() {
      setViewerHeight(getViewerHeight());
    }
    window.addEventListener('resize', handleResize);
    return () => window.removeEventListener('resize', handleResize);
  }, [isMobile]);

  /**
   * Set body classes (tailwindcss) that don't allow vertical
   * or horizontal overflow (no scrolling). Also guarantee window
   * is sized to our viewport.
   */
  useEffect(() => {
    document.body.classList.add('bg-black');
    document.body.classList.add('overflow-hidden');

    return () => {
      document.body.classList.remove('bg-black');
      document.body.classList.remove('overflow-hidden');
    };
  }, []);

  const getComponent = id => {
    const entry = extensionManager.getModuleEntry(id);

    if (!entry || !entry.component) {
      throw new Error(
        `${id} is not valid for an extension module or no component found from extension ${id}. Please verify your configuration or ensure that the extension is properly registered. It's also possible that your mode is utilizing a module from an extension that hasn't been included in its dependencies (add the extension to the "extensionDependencies" array in your mode's index.js file). Check the reference string to the extension in your Mode configuration`
      );
    }

    return { entry };
  };

  useEffect(() => {
    const { unsubscribe } = hangingProtocolService.subscribe(
      HangingProtocolService.EVENTS.PROTOCOL_CHANGED,

      // Todo: right now to set the loading indicator to false, we need to wait for the
      // hangingProtocolService to finish applying the viewport matching to each viewport,
      // however, this might not be the only approach to set the loading indicator to false. we need to explore this further.
      () => {
        setShowLoadingIndicator(false);
      }
    );

    return () => {
      unsubscribe();
    };
  }, [hangingProtocolService]);

  const getViewportComponentData = viewportComponent => {
    const { entry } = getComponent(viewportComponent.namespace);

    return {
      component: entry.component,
      isReferenceViewable: entry.isReferenceViewable,
      displaySetsToDisplay: viewportComponent.displaySetsToDisplay,
    };
  };

  useEffect(() => {
    const { unsubscribe } = panelService.subscribe(
      panelService.EVENTS.PANELS_CHANGED,
      ({ options }) => {
        setHasLeftPanels(hasPanels('left'));
        setHasRightPanels(hasPanels('right'));
        if (options?.leftPanelClosed !== undefined) {
          setLeftPanelClosed(options.leftPanelClosed);
        }
        if (options?.rightPanelClosed !== undefined) {
          setRightPanelClosed(options.rightPanelClosed);
        }
      }
    );

    return () => {
      unsubscribe();
    };
  }, [panelService, hasPanels]);

  const viewportComponents = viewports.map(getViewportComponentData);

  return (
    <div>
      {/* Left Panel Open Button */}
      {leftPanelClosedState && (
        <button
          className="fixed top-12 bottom-24 left-0 z-50 flex h-[calc(100vh-104px)] w-9 items-center justify-center bg-transparent transition-colors hover:bg-none sm:h-[calc(100vh-52px)]"
          style={{ borderTopRightRadius: '0px', borderBottomRightRadius: '6px' }}
          onClick={() => setLeftPanelClosed(false)}
          aria-label="Open Left Panel"
        >
          <span className="text-2xl text-white">&#x203A;</span>
        </button>
      )}

      {/* Right Panel Open Button */}
      {rightPanelClosedState && (
        <button
          className="fixed top-12 bottom-24 right-0 z-50 mb-12 flex h-[calc(100vh-104px)] w-9 items-center justify-center bg-transparent transition-colors hover:bg-none sm:h-[calc(100vh-52px)]"
          style={{ borderTopLeftRadius: '0px', borderBottomLeftRadius: '6px' }}
          onClick={() => setRightPanelClosed(false)}
          aria-label="Open Right Panel"
        >
          <span className="text-2xl text-white">&#x2039;</span>
        </button>
      )}

      <ViewerHeader
        hotkeysManager={hotkeysManager}
        extensionManager={extensionManager}
        servicesManager={servicesManager}
        appConfig={appConfig}
        expandedGroup={expandedGroup}
        setExpandedGroup={setExpandedGroup}
      />
      <div
        className="viewer-main-wrapper relative flex w-full flex-row flex-nowrap items-stretch overflow-hidden bg-black"
        style={{ height: viewerHeight }}
      >
        <React.Fragment>
          {showLoadingIndicator && <LoadingIndicatorProgress className="h-full w-full bg-black" />}
          <ResizablePanelGroup {...resizablePanelGroupProps}>
            {/* LEFT SIDEPANELS */}
            {hasLeftPanels ? (
              <>
                <ResizablePanel {...resizableLeftPanelProps}>
                  <SidePanelWithServices
                    side="left"
                    isExpanded={!leftPanelClosedState}
                    servicesManager={servicesManager}
                    {...leftPanelProps}
                  />
                </ResizablePanel>
                <ResizableHandle
                  onDragging={onHandleDragging}
                  disabled={!leftPanelResizable}
                  className={resizableHandleClassName}
                />
              </>
            ) : null}
            {/* TOOLBAR + GRID */}
            <ResizablePanel {...resizableViewportGridPanelProps}>
              <div className="flex h-full flex-1 flex-col">
                <div
                  className="relative flex h-full flex-1 items-center justify-center overflow-hidden bg-black"
                  onMouseEnter={handleMouseEnter}
                >
                  {/* Floating tool group bar overlay */}
                  <FloatingToolGroupBar
                    buttonSection={expandedGroup}
                    onClose={() => setExpandedGroup(null)}
                  />
                  <ViewportGridComp
                    servicesManager={servicesManager}
                    viewportComponents={viewportComponents}
                    commandsManager={commandsManager}
                  />
                  {/* Glasslike Toolbar Sidebar Overlay */}
                  {isMobile ? (
                    <div className="toolbar-overlay toolbar-overlay-mobile">
                      <IconPresentationProvider
                        size="large"
                        IconContainer={ToolButton}
                      >
                        <div className="toolbar-buttons-container toolbar-buttons-container-mobile">
                          <Toolbar
                            buttonSection="primary"
                            location={1}
                            viewportId={activeViewportId}
                            expandedGroup={expandedGroup}
                            setExpandedGroup={setExpandedGroup}
                          />
                        </div>
                      </IconPresentationProvider>
                    </div>
                  ) : (
                    <div className="toolbar-overlay">
                      <IconPresentationProvider
                        size="large"
                        IconContainer={ToolButton}
                      >
                        <div className="toolbar-buttons-container">
                          <Toolbar
                            buttonSection="primary"
                            location={1}
                            viewportId={activeViewportId}
                            expandedGroup={expandedGroup}
                            setExpandedGroup={setExpandedGroup}
                          />
                        </div>
                      </IconPresentationProvider>
                    </div>
                  )}
                </div>
              </div>
            </ResizablePanel>
            {hasRightPanels ? (
              <>
                <ResizableHandle
                  onDragging={onHandleDragging}
                  disabled={!rightPanelResizable}
                  className={resizableHandleClassName}
                />
                <ResizablePanel {...resizableRightPanelProps}>
                  <SidePanelWithServices
                    side="right"
                    isExpanded={!rightPanelClosedState}
                    servicesManager={servicesManager}
                    {...rightPanelProps}
                  />
                </ResizablePanel>
              </>
            ) : null}
          </ResizablePanelGroup>
        </React.Fragment>
      </div>
    </div>
  );
}

ViewerLayout.propTypes = {
  // From extension module params
  extensionManager: PropTypes.shape({
    getModuleEntry: PropTypes.func.isRequired,
  }).isRequired,
  commandsManager: PropTypes.instanceOf(CommandsManager),
  servicesManager: PropTypes.object.isRequired,
  // From modes
  leftPanels: PropTypes.array,
  rightPanels: PropTypes.array,
  leftPanelClosed: PropTypes.bool.isRequired,
  rightPanelClosed: PropTypes.bool.isRequired,
  /** Responsible for rendering our grid of viewports; provided by consuming application */
  children: PropTypes.oneOfType([PropTypes.node, PropTypes.func]).isRequired,
  viewports: PropTypes.array,
};

export default ViewerLayout;
