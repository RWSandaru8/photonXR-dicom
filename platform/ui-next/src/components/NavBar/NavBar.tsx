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
        'z-20 px-1',
        isSticky && stickyClasses,
        !isSticky && notStickyClasses,
        className
      )}
      style={
        isInDicomViewer
          ? {
              background: '#2A2A2A',
              WebkitBackdropFilter: 'none',
              backdropFilter: 'none',
              borderBottom: 'none',
              boxShadow: '0 2px 4px rgba(0, 0, 0, 0.1)',
            }
          : {
              background: '#2A2A2A',
              boxShadow: '0 2px 4px rgba(0, 0, 0, 0.1)',
            }
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
