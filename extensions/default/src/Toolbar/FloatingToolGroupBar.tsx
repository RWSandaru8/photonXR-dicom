import React, { useEffect, useState, CSSProperties } from 'react';
import ToolButtonListWrapper from './ToolButtonListWrapper';

interface FloatingToolGroupBarProps {
  buttonSection: string | null;
  onClose: () => void;
}

const FloatingToolGroupBar: React.FC<FloatingToolGroupBarProps> = ({ buttonSection, onClose }) => {
  const [isMobile, setIsMobile] = useState(false);

  useEffect(() => {
    const checkIfMobile = () => {
      setIsMobile(window.innerWidth <= 768); // Standard breakpoint for tablets and below
    };

    // Initial check
    checkIfMobile();

    // Add event listener for window resize
    window.addEventListener('resize', checkIfMobile);
    return () => window.removeEventListener('resize', checkIfMobile);
  }, []);

  if (!buttonSection) {
    return null;
  }

  // Mobile overlay styles
  const mobileStyles: CSSProperties = {
    position: 'fixed',
    top: 'auto',
    bottom: '20px',
    left: '50%',
    transform: 'translateX(-50%)',
    width: 'auto',
    maxWidth: '95%',
    padding: '8px 12px',
    backgroundColor: 'rgba(0, 166, 147, 0.9)',
    borderRadius: '8px',
    boxShadow: '0 4px 12px rgba(0,0,0,0.2)',
    zIndex: 1000,
    display: 'flex',
    gap: '8px',
    overflowX: 'auto',
    WebkitOverflowScrolling: 'touch',
    scrollbarWidth: 'none', // Firefox
    msOverflowStyle: 'none', // IE and Edge
  };

  // Desktop styles
  const desktopStyles: CSSProperties = !isMobile
    ? {
        position: 'absolute',
        top: '0',
        left: '50%',
        transform: 'translateX(-50%)',
      }
    : {};

  return (
    <div
      className={`pointer-events-auto ${isMobile ? 'fixed inset-0' : 'absolute top-0 left-1/2 z-[100] mt-2 -translate-x-1/2'}`}
      onClick={e => {
        // Close when clicking outside the toolbar on mobile
        if (isMobile && e.target === e.currentTarget) {
          onClose();
        }
      }}
    >
      <div
        className={`rounded-lg ${isMobile ? 'px-1 py-1' : 'bg-[#00A693]/10 px-2 py-1 shadow-lg'}`}
        style={isMobile ? mobileStyles : {}}
        onClick={e => e.stopPropagation()}
      >
        <div className="flex items-center gap-1">
          <div className="[&_svg]:text-white [&_svg]:hover:text-blue-200">
            <ToolButtonListWrapper
              buttonSection={buttonSection}
              id={buttonSection + 'Floating'}
              horizontalInHeader={!isMobile}
              onInteraction={onClose}
            />
          </div>
        </div>
        {isMobile && (
          <button
            onClick={onClose}
            className="ml-2 flex h-7 w-7 flex-shrink-0 items-center justify-center rounded-full bg-red-500 text-lg text-white hover:bg-red-600"
            aria-label="Close toolbar"
          >
            ×
          </button>
        )}
      </div>
    </div>
  );
};

export default FloatingToolGroupBar;
