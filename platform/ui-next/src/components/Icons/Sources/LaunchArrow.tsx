import React from 'react';
import type { IconProps } from '../types';

export const LaunchArrow = (props: IconProps) => (
  <svg
    xmlns="http://www.w3.org/2000/svg"
    viewBox="0 0 24 24"
    width={20}
    height={20}
    {...props}
  >
    <g fillRule="evenodd">
      <path
        fill="#000000"
        d="M10.5.31C4.87.31.308 4.872.308 10.501c0 5.629 4.563 10.192 10.192 10.192 5.63 0 10.192-4.563 10.192-10.192C20.692 4.872 16.13.309 10.5.309zm0 1c5.077 0 9.192 4.115 9.192 9.192 0 5.076-4.115 9.192-9.192 9.192s-9.192-4.116-9.192-9.192c0-5.077 4.115-9.193 9.192-9.193z"
        transform="translate(0 .5)"
      />
      <path
        fill="#000000"
        d="M14.5 10.5c0 .276-.224.5-.5.5-.245 0-.45-.177-.492-.41l-.008-.09v-2.793l-5.146 5.147c-.195.195-.512.195-.707 0-.176-.177-.195-.452-.057-.649l.057-.058 5.146-5.147H10c-.276 0-.5-.224-.5-.5 0-.245.177-.45.41-.492l.09-.008h4c.276 0 .5.224.5.5v4z"
        transform="translate(0 .5)"
      />
    </g>
  </svg>
);

export default LaunchArrow;
