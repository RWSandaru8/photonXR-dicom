import React from 'react';
import PropTypes from 'prop-types';
import classnames from 'classnames';

const stickyClasses = 'sticky top-0';
const notStickyClasses = 'relative';

const NavBar = ({
  className,
  children,
  isSticky,
  isInDicomViewer = false,
}: {
  className?: string;
  children?: React.ReactNode;
  isSticky?: boolean;
  isInDicomViewer?: boolean;
}) => {
  return (
    <div
      className={classnames(
        'z-20 border-[#E2E8F0] px-1',
        isInDicomViewer ? '' : 'bg-[#004D45]',
        isSticky && stickyClasses,
        !isSticky && notStickyClasses,
        className
      )}
      style={
        isInDicomViewer
          ? {
              background: '#004D45',
              WebkitBackdropFilter: 'none',
              backdropFilter: 'none',
              borderBottom: 'none',
              boxShadow: 'none',
            }
          : undefined
      }
    >
      {children}
    </div>
  );
};

NavBar.propTypes = {
  className: PropTypes.string,
  children: PropTypes.node,
  isSticky: PropTypes.bool,
  isInDicomViewer: PropTypes.bool,
};

export default NavBar;
