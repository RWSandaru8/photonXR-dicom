import React, { ReactNode } from 'react';
import classNames from 'classnames';
import {
  DropdownMenu,
  DropdownMenuTrigger,
  DropdownMenuContent,
  DropdownMenuItem,
  Icons,
  Button,
  ToolButton,
} from '../';
import { IconPresentationProvider } from '@ohif/ui-next';
import HeaderIcon from '../../../PXR.png';

import NavBar from '../NavBar';

// Todo: we should move this component to composition and remove props base

interface HeaderProps {
  children?: ReactNode;
  menuOptions: Array<{
    title: string;
    icon?: string;
    onClick: () => void;
  }>;
  isReturnEnabled?: boolean;
  onClickReturnButton?: () => void;
  isSticky?: boolean;
  isInDicomViewer?: boolean;
  WhiteLabeling?: {
    createLogoComponentFn?: (React: any, props: any) => ReactNode;
  };
  PatientInfo?: ReactNode;
  Secondary?: ReactNode;
  UndoRedo?: ReactNode;
}

function Header({
  children,
  menuOptions,
  isReturnEnabled = true,
  onClickReturnButton,
  isSticky = false,
  isInDicomViewer = true,
  WhiteLabeling,
  PatientInfo,
  UndoRedo,
  Secondary,
  ...props
}: HeaderProps): ReactNode {
  const onClickReturn = () => {
    if (onClickReturnButton) {
      onClickReturnButton();
    }
  };

  return (
    <IconPresentationProvider
      size="large"
      IconContainer={ToolButton}
    >
      <NavBar
        isSticky={isSticky}
        isInDicomViewer={isInDicomViewer}
        {...props}
      >
        <div className="relative h-[48px] items-center">
          <div className="absolute left-0 top-1/2 flex -translate-y-1/2 items-center">
            <div className={'mr-3 inline-flex items-center'}>
              <img
                src={HeaderIcon}
                alt="Header Icon"
                className="w-13 mr-4 h-4 pl-1"
              />
              <div className="ml-1 flex flex-col">
                {/*<span className="text-lg font-bold text-[#F5F5F5]">GPV MED</span>
                <span className="text-xs text-[#F5F5F5]">DICOM Viewer</span>*/}
              </div>
            </div>
          </div>
          <div className="absolute top-1/2 left-[250px] h-8 -translate-y-1/2">{Secondary}</div>
          <div className="absolute left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 transform">
            <div className="flex items-center justify-center space-x-2">{children}</div>
          </div>
          <div className="absolute right-0 top-1/2 flex -translate-y-1/2 select-none items-center">
            {/*{UndoRedo}*/}
            {/*<div className="border-primary-dark mx-1.5 h-[25px] border-r"></div>*/}
            {/*{PatientInfo}*/}
            {/*<div className="border-primary-dark mx-1.5 h-[25px] border-r"></div>*/}

            {/* User Profile Section */}
            <div className="mr-4 flex-shrink-0">
              <DropdownMenu>
                <DropdownMenuTrigger asChild>
                  <Button
                    variant="ghost"
                    className="flex items-center rounded-md px-3 py-2 hover:bg-[#202025]"
                  >
                    <Icons.Patient className="mr-3 h-7 w-7 text-white" />
                    <span className="mr-3 text-base text-white">Patient</span>
                    <Icons.ChevronDown className="h-4 w-4 text-white" />
                  </Button>
                </DropdownMenuTrigger>
                <DropdownMenuContent
                  align="end"
                  className="w-64"
                >
                  <div className="space-y-3 p-4">
                    <div className="border-b border-gray-600 pb-2">
                      <h3 className="text-sm font-medium text-[#F5F5F5]">Patient Information</h3>
                    </div>

                    <div className="space-y-2">
                      <div className="flex justify-between">
                        <span className="text-sm text-[#A0A0A0]">Modality:</span>
                        <span className="text-sm font-medium text-[#D1D1D1]">CT</span>
                      </div>

                      <div className="flex justify-between">
                        <span className="text-sm text-[#A0A0A0]">Region:</span>
                        <span className="text-sm font-medium text-[#D1D1D1]">Head & Neck</span>
                      </div>

                      <div className="flex justify-between">
                        <span className="text-sm text-[#A0A0A0]">Patient ID:</span>
                        <span className="text-sm font-medium text-[#D1D1D1]">PAT-001234</span>
                      </div>

                      <div className="mt-3 border-t border-gray-600 pt-2">
                        <div className="flex items-center justify-between">
                          <span className="text-sm text-[#A0A0A0]">DOB:</span>
                          <span className="text-sm text-[#D1D1D1]">1985-03-15</span>
                        </div>
                        <div className="mt-1 flex items-center justify-between">
                          <span className="text-sm text-[#A0A0A0]">Sex | Age:</span>
                          <span className="text-sm text-[#D1D1D1]">M | 39</span>
                        </div>
                      </div>
                    </div>
                  </div>
                </DropdownMenuContent>
              </DropdownMenu>
            </div>

            <div className="flex-shrink-0">
              <DropdownMenu>
                <DropdownMenuTrigger asChild>
                  <Button
                    variant="ghost"
                    size="icon"
                    className="settings-button mt-2 h-full w-full hover:bg-[#202025]"
                  >
                    <Icons.GearSettings className="text-[#D1D1D1]" />
                  </Button>
                </DropdownMenuTrigger>
                <DropdownMenuContent align="end">
                  {menuOptions.map((option, index) => {
                    const IconComponent = option.icon
                      ? Icons[option.icon as keyof typeof Icons]
                      : null;
                    return (
                      <DropdownMenuItem
                        key={index}
                        onSelect={option.onClick}
                        className="dropdown-item flex items-center gap-2 py-2"
                      >
                        {IconComponent && (
                          <span className="flex h-4 w-4 items-center justify-center text-[#D1D1D1]">
                            <Icons.ByName name={option.icon as string} />
                          </span>
                        )}
                        <span className="flex-1 text-[#D1D1D1]">{option.title}</span>
                      </DropdownMenuItem>
                    );
                  })}
                </DropdownMenuContent>
              </DropdownMenu>
            </div>
          </div>
        </div>
      </NavBar>
    </IconPresentationProvider>
  );
}

export default Header;
