import React from 'react';
import PropTypes from 'prop-types';

/**
 * A button that can trigger commands when clicked.
 */
function ViewportActionButton({ onInteraction, commands, id, children }) {
  return (
    <div
      className="ml-1 cursor-pointer rounded bg-[#B2A7D3] px-1.5 hover:bg-[#202025] hover:text-[#F9FAFB]"
      // Using onMouseUp because onClick wasn't firing if pointer-events are none.
      onMouseUp={() => {
        onInteraction({
          itemId: id,
          commands,
        });
      }}
    >
      {children}
    </div>
  );
}

ViewportActionButton.propTypes = {
  id: PropTypes.string,
  onInteraction: PropTypes.func.isRequired,
  commands: PropTypes.array,
  children: PropTypes.node,
};

export { ViewportActionButton };
