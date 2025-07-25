import React from 'react';
import type { IconProps } from '@ohif/ui-next/src/components/Icons/types';

export const CustomIcons = {
  TotalStudies: (props: IconProps) => (
    <svg
      width="24"
      height="24"
      viewBox="0 0 24 24"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
      {...props}
    >
      <path
        d="M7 3C7.55228 3 8 3.44772 8 4V4.5C8 5.05228 7.55228 5.5 7 5.5H6C5.44772 5.5 5 5.05228 5 4.5V4C5 3.44772 5.44772 3 6 3H7Z"
        stroke="currentColor"
        strokeWidth="1.5"
      />
      <path
        d="M11 3C11.5523 3 12 3.44772 12 4V4.5C12 5.05228 11.5523 5.5 11 5.5H10C9.44772 5.5 9 5.05228 9 4.5V4C9 3.44772 9.44772 3 10 3H11Z"
        stroke="currentColor"
        strokeWidth="1.5"
      />
      <path
        d="M15 3C15.5523 3 16 3.44772 16 4V4.5C16 5.05228 15.5523 5.5 15 5.5H14C13.4477 5.5 13 5.05228 13 4.5V4C13 3.44772 13.4477 3 14 3H15Z"
        stroke="currentColor"
        strokeWidth="1.5"
      />
      <path
        fillRule="evenodd"
        clipRule="evenodd"
        d="M3 7C3 6.44772 3.44772 6 4 6H20C20.5523 6 21 6.44772 21 7V20C21 20.5523 20.5523 21 20 21H4C3.44772 21 3 20.5523 3 20V7ZM4 7L20 7V20H4V7Z"
        fill="currentColor"
      />
      <path
        d="M6 10C6.55228 10 7 10.4477 7 11V14.5C7 15.0523 6.55228 15.5 6 15.5H5C4.44772 15.5 4 15.0523 4 14.5V11C4 10.4477 4.44772 10 5 10H6Z"
        fill="currentColor"
      />
      <path
        d="M10 10C10.5523 10 11 10.4477 11 11V17C11 17.5523 10.5523 18 10 18H9C8.44772 18 8 17.5523 8 17V11C8 10.4477 8.44772 10 9 10H10Z"
        fill="currentColor"
      />
      <path
        d="M14 10C14.5523 10 15 10.4477 15 11V15.5C15 16.0523 14.5523 16.5 14 16.5H13C12.4477 16.5 12 16.0523 12 15.5V11C12 10.4477 12.4477 10 13 10H14Z"
        fill="currentColor"
      />
      <path
        d="M18 10C18.5523 10 19 10.4477 19 11V13.5C19 14.0523 18.5523 14.5 18 14.5H17C16.4477 14.5 16 14.0523 16 13.5V11C16 10.4477 16.4477 10 17 10H18Z"
        fill="currentColor"
      />
    </svg>
  ),
  TodayScans: (props: IconProps) => (
    <svg
      width="24"
      height="24"
      viewBox="0 0 24 24"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
      {...props}
    >
      <path
        d="M12 7V12L15 13.5"
        stroke="currentColor"
        strokeWidth="1.5"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
      <path
        fillRule="evenodd"
        clipRule="evenodd"
        d="M22 12C22 17.5228 17.5228 22 12 22C6.47715 22 2 17.5228 2 12C2 6.47715 6.47715 2 12 2C17.5228 2 22 6.47715 22 12ZM12 20C16.4183 20 20 16.4183 20 12C20 7.58172 16.4183 4 12 4C7.58172 4 4 7.58172 4 12C4 16.4183 7.58172 20 12 20Z"
        fill="currentColor"
      />
    </svg>
  ),
};
